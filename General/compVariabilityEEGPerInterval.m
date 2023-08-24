function [meanStatsEEG, allData, indTrialPerCh, iChKept, varMeasure] = compVariabilityEEGPerInterval(EEGStimTrials, cfgInfoPeaks, nTrials, whichVariability, useLog)
% compute coeff of variance of abs(signal) for each channel  
%Then average CV across channels at specified intervals.
% Use Absolute data to compute variability
if ~exist('useLog','var'), useLog=0; end
useAllData  =1; % if 1 consider all the trial together - if 0 keep each trial separate

%whichVariability='STD';
minNTrials = cfgInfoPeaks.minNumberTrials; % minimum number of trials (default 5)
indTimeSamples = cfgInfoPeaks.tSamples; % time (Samples) to compute N1 peak amplitude

timeIntervalNames = fieldnames(cfgInfoPeaks.tSamples);

allStd=cell(1,length(timeIntervalNames));
allCoeffVar=cell(1,length(timeIntervalNames));
allQ25=cell(1,length(timeIntervalNames)); allQ75=cell(1,length(timeIntervalNames));
allCorrVal=cell(1,length(timeIntervalNames));
allSTdError=cell(1,length(timeIntervalNames));
allMad=cell(1,length(timeIntervalNames));
allCoeffMad=cell(1,length(timeIntervalNames));
allMADoverTrial=cell(1,length(timeIntervalNames));
allSNR=cell(1,length(timeIntervalNames));
allData=[];
nTrialPerCh=[];
indTrialPerCh=[];
iChKept=[];

for iCh=1:numel(EEGStimTrials)
    if length(nTrials)==1 % If only 1 number is specified -> use LAST trials
        indTrials= max(size(EEGStimTrials{iCh},2)- nTrials,0)+1:size(EEGStimTrials{iCh},2);
    else
        indTrials= intersect(1:size(EEGStimTrials{iCh},2), nTrials); % if index is specified use those
    end
    
    if length(indTrials) >= minNTrials % minimum number of trials to compute variability
        data = EEGStimTrials{iCh}(:,indTrials(1):min(size(EEGStimTrials{iCh},2),indTrials(end)));
        allData = [allData, data];
        nTrialPerCh = [nTrialPerCh, size(data,2)];
        
        indTrialPerCh = [indTrialPerCh, repmat(iCh,[1,size(data,2)])];
        %keep track of channels that are kept with enough data
        iChKept = [iChKept, iCh];
        
        
        for iTimeName=1:length(timeIntervalNames)
            timeName = timeIntervalNames{iTimeName};
            indT1T2 = indTimeSamples.(timeName)(1):indTimeSamples.(timeName)(2);
            dataPerInterval = data(indT1T2,:);
            
            if useAllData, dataPerInterval=dataPerInterval(:);end
            [meanVal, q25, q75, stdVal, stdErrorVal,medianVal, coeffVar, madVar, coeffMADVar, rmsVal, snrVal]= meanQuantiles(dataPerInterval, 1); % per channel - before 2 / now obtain 1 value per trial
            % [corrVal,corrPval] = corrcoef(data); % NOT IMPLEMENTED YET!
            
            allStd{iTimeName} = [allStd{iTimeName}, stdVal];
            allQ25{iTimeName} = [allQ25{iTimeName}, q25];
            allQ75{iTimeName} = [allQ75{iTimeName}, q75];
            allSTdError{iTimeName} = [allSTdError{iTimeName}, stdErrorVal];
            allCoeffVar{iTimeName} = [allCoeffVar{iTimeName}, coeffVar];
            allMad{iTimeName} = [allMad{iTimeName}, madVar];
            allCoeffMad{iTimeName} = [allCoeffMad{iTimeName}, coeffMADVar];
            allMADoverTrial{iTimeName} = [allMADoverTrial{iTimeName}, madVar / size(data,2)];
             allSNR{iTimeName} = [allSNR{iTimeName}, snrVal];
           %   allCorrVal = [allCorrVal, corrVal]; % NOT
            
        end
    end
end

for iTimeName=1:length(timeIntervalNames)
    timeName = timeIntervalNames{iTimeName};
    
    switch upper(whichVariability)
        case 'STD'
            varMeasure = allStd{iTimeName};
        case 'CV'
            varMeasure = allCoeffVar{iTimeName};
        case '2575RANGE'
            varMeasure = allQ75{iTimeName} - allQ25{iTimeName};
        case 'CORR' % Perason correlation coefficient
            varMeasure = allCorrVal{iTimeName};
        case 'VARERR'
            varMeasure = allSTdError{iTimeName};
        case 'MAD'
            varMeasure = allMad{iTimeName};
        case 'COEFFMAD'
            varMeasure = allCoeffMad{iTimeName};
        case 'TRIALMAD'
            varMeasure = allMADoverTrial{iTimeName};
        case 'SNR'
            varMeasure = allSNR;
        otherwise
            varMeasure = allStd{iTimeName};
    end
    
    % log10 of varMeasure to make it more normal
    if useLog
        varMeasure = log10(varMeasure);
    end
    
    % Variability with selected measure
    meanStatsEEG.VariabilityPerChPerTrial.(timeName) = varMeasure;   

    % Average per channel
    meanStatsEEG.meanVariability.(timeName) = mean(varMeasure,'omitnan');
    
    % Average per channel across trials
    if length(indTrialPerCh) == length(varMeasure)
        uTrial = unique(indTrialPerCh);
        mPerCh = NaN(1,length(uTrial));
        for iCh=1:length(uTrial)
            mPerCh(uTrial(iCh))= mean([varMeasure(find(indTrialPerCh==uTrial(iCh)))],'omitnan');
        end
        meanStatsEEG.VariabilityPerCh.(timeName) = mPerCh;
    else
        meanStatsEEG.VariabilityPerCh.(timeName) = meanStatsEEG.VariabilityPerChPerTrial.(timeName);
    end
    
    %% Add also other measures (for comparison)
    meanStatsEEG.AllMeasures.coeffVar.(timeName) = allCoeffVar{iTimeName}; % mean((indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allStd.(timeName) = allStd{iTimeName};
    meanStatsEEG.AllMeasures.rangeQ2575.(timeName) = allQ75{iTimeName} - allQ25{iTimeName};
    meanStatsEEG.AllMeasures.stdError.(timeName) = allSTdError{iTimeName};
    meanStatsEEG.AllMeasures.allMad.(timeName) = allMad{iTimeName}; %mean((indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allCoeffMad.(timeName) = allCoeffMad{iTimeName};
    meanStatsEEG.AllMeasures.allMADoverTrial.(timeName) = allMADoverTrial{iTimeName};
    meanStatsEEG.AllMeasures.allSNR.(timeName) = allSNR{iTimeName};
end
% Keep field indicating to which channels each variability corresponds
meanStatsEEG.indChKept = iChKept;
meanStatsEEG.nTrialPerCh = nTrialPerCh;

% Normalize with respect to baseline
for iTimeName=1:length(timeIntervalNames)
    timeName = timeIntervalNames{iTimeName};

    %Normalize with respect to baseline
    meanStatsEEG.normVariabilityPerCh.(timeName) = (meanStatsEEG.VariabilityPerCh.(timeName)./meanStatsEEG.VariabilityPerCh.Baseline);
    % Average across channel - Normalized Variability
    meanStatsEEG.meanNormVariability.(timeName) = mean(meanStatsEEG.normVariabilityPerCh.(timeName),'omitnan');
end



% meanStatsEEG.AllMeasures.coeffVar.BaselinePerCh = stdBaseline(iChKept) ./ meanBaseline(iChKept);
% meanStatsEEG.AllMeasures.allStd.BaselinePerCh = stdBaseline(iChKept);
% indT1T2Baseline = indTimeSamples.Baseline(1):indTimeSamples.Baseline(2);
% 
% meanStatsEEG.AllMeasures.coeffVar.BaselinePerCh = mean(allCoeffVar(indT1T2Baseline,:),1);
% meanStatsEEG.AllMeasures.allStd.BaselinePerCh = mean(allStd(indT1T2Baseline,:),1);
% meanStatsEEG.AllMeasures.rangeQ2575.BaselinePerCh = mean(rangeQ2575(indT1T2Baseline,:),1);


