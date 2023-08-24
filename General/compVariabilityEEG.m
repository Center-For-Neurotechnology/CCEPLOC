function [meanStatsEEG, allData, indTrialPerCh, iChKept, varMeasure] = compVariabilityEEG(EEGStimTrials, cfgInfoPeaks, nTrials, whichVariability, useLog)
% compute coeff of variance of abs(signal) for each channel  
%Then average CV across channels at specified intervals.
% Use Absolute data to compute variability
if ~exist('useLog','var'), useLog=0; end
    
%whichVariability='STD';
minNTrials = cfgInfoPeaks.minNumberTrials; % minimum number of trials (default 5)
indTimeSamples = cfgInfoPeaks.tSamples; % time (Samples) to compute N1 peak amplitude
indBaseline = cfgInfoPeaks.tSamples.Baseline; % time (Samples) to compute baseline variation amplitude/variability if no general baseline is provided

timeIntervalNames = fieldnames(cfgInfoPeaks.tSamples);

allCoeffVar=[]; allStd=[];
allQ25=[];allQ75=[];
allCorrVal=[];
allSTdError=[];
allMad=[];
allCoeffMad=[];
allMADoverTrial=[];
allSNR=[];
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
        [meanVal, q25, q75, stdVal, stdErrorVal,medianVal, coeffVar, madVar, coeffMADVar, rmsVal, snrVal]= meanQuantiles(data, 2); % per channel
        % [corrVal,corrPval] = corrcoef(data); % NOT IMPLEMENTED YET!
        
        allStd = [allStd, stdVal];
        allQ25 = [allQ25, q25];
        allQ75 = [allQ75, q75];
        allSTdError = [allSTdError, stdErrorVal];
        allCoeffVar = [allCoeffVar, coeffVar];
        allMad = [allMad, madVar];
        allCoeffMad = [allCoeffMad, coeffMADVar];
        allMADoverTrial = [allMADoverTrial, madVar / size(data,2)];
        %   allCorrVal = [allCorrVal, corrVal]; % NOT
        allSNR = [allSNR, snrVal];
        allData = [allData, data];
        indTrialPerCh = [indTrialPerCh, repmat(iCh,[1,size(data,2)])];
        %keep track of channels that are kept with enough data
        iChKept = [iChKept, iCh];
        nTrialPerCh = [nTrialPerCh, size(data,2)];
    end
end
rangeQ2575 = allQ75 - allQ25;
switch upper(whichVariability)
    case 'STD'
        varMeasure = allStd;
    case 'CV'
        varMeasure = allCoeffVar;
    case '2575RANGE'
        varMeasure = rangeQ2575;
    case 'CORR' % Perason correlation coefficient
        varMeasure = allCorrVal;
    case 'VARERR'
        varMeasure = allSTdError;
    case 'MAD'
        varMeasure = allMad;
    case 'COEFFMAD'
        varMeasure = allCoeffMad;    
    case 'TRIALMAD'
        varMeasure = allMADoverTrial;
    case 'SNR'
        varMeasure = allSNR;
    otherwise
        varMeasure = allStd;
end

% log10 of varMeasure to make it more normal
if useLog
    varMeasure = log10(varMeasure);
end

% Variability per Baseline Data 
meanStatsEEG.VariabilityBaselinePerCh = mean(varMeasure(indBaseline(1):indBaseline(2),:),1,'omitnan');

% if ~isempty(EEGBaseline)
%     stdBaseline = [EEGBaseline.std];
%     meanBaseline = [EEGBaseline.mean];
% end
%     switch upper(whichVariability)
%         case 'STD'
%             meanStatsEEG.VariabilityBaselinePerCh = stdBaseline(iChKept);
%         case 'CV'
%             meanStatsEEG.VariabilityBaselinePerCh = stdBaseline(iChKept) ./ meanBaseline(iChKept);
% %         case '2575RANGE'
% %             varMeasure = allQ75 - allQ25; % I do NOT have this info!
%         otherwise
%             meanStatsEEG.VariabilityBaselinePerCh = stdBaseline(iChKept);
%     end
% else
%    meanStatsEEG.VariabilityBaselinePerCh = mean(varMeasure(indBaseline(1):indBaseline(2),:),1);
%end

for iTimeName=1:length(timeIntervalNames)
    timeName = timeIntervalNames{iTimeName};
    % Average across interval - USE STD as meassure of variability (could also use q25-75)
    meanStatsEEG.VariabilityPerCh.(timeName) = mean(varMeasure(indTimeSamples.(timeName)(1):indTimeSamples.(timeName)(2),:),1);
    
    %Normalize with respect to baseline CV
    meanStatsEEG.normVariabilityPerCh.(timeName) = (meanStatsEEG.VariabilityPerCh.(timeName)./meanStatsEEG.VariabilityBaselinePerCh);
    
    % Average across channel
    meanStatsEEG.meanVariability.(timeName) = mean(meanStatsEEG.VariabilityPerCh.(timeName),'omitnan');
    
    % Average across channel - Normalized Variability
    meanStatsEEG.meanNormVariability.(timeName) = mean(meanStatsEEG.normVariabilityPerCh.(timeName),'omitnan');
end

meanStatsEEG.meanVariabilityBaseline = mean(meanStatsEEG.VariabilityBaselinePerCh,'omitnan');

%% Add also other measures (for comparison)
% meanStatsEEG.AllMeasures.corrPerCh.N1 = mean(allCorrVal(indN1(1):indN1(2),:),1);
for iTimeName=1:length(timeIntervalNames)
    timeName = timeIntervalNames{iTimeName};
    indT1T2 = indTimeSamples.(timeName)(1):indTimeSamples.(timeName)(2);
    meanStatsEEG.AllMeasures.coeffVar.(timeName) = mean(allCoeffVar(indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allStd.(timeName) = mean(allStd(indT1T2,:),1);
    meanStatsEEG.AllMeasures.rangeQ2575.(timeName) = mean(rangeQ2575(indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.stdError.(timeName) = mean(allSTdError(indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allMad.(timeName) = mean(allMad(indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allCoeffMad.(timeName) = mean(allCoeffMad(indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allMADoverTrial.(timeName) = mean(allMADoverTrial(indT1T2,:),1,'omitnan');
    meanStatsEEG.AllMeasures.allSNR.(timeName) = mean(allSNR(indT1T2,:),1,'omitnan');
end

% meanStatsEEG.AllMeasures.coeffVar.BaselinePerCh = stdBaseline(iChKept) ./ meanBaseline(iChKept);
% meanStatsEEG.AllMeasures.allStd.BaselinePerCh = stdBaseline(iChKept);
% indT1T2Baseline = indTimeSamples.Baseline(1):indTimeSamples.Baseline(2);
% 
% meanStatsEEG.AllMeasures.coeffVar.BaselinePerCh = mean(allCoeffVar(indT1T2Baseline,:),1);
% meanStatsEEG.AllMeasures.allStd.BaselinePerCh = mean(allStd(indT1T2Baseline,:),1);
% meanStatsEEG.AllMeasures.rangeQ2575.BaselinePerCh = mean(rangeQ2575(indT1T2Baseline,:),1);

% Keep field indicating to which channels each variability corresponds
meanStatsEEG.indChKept = iChKept;
meanStatsEEG.nTrialPerCh = nTrialPerCh;


