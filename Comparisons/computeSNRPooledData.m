function computeSNRPooledData(fileNamesPerState, fileNameComparisonResults, channInfo, cfgStats, cfgInfoPeaks)
% Compare SNR of peaks and of time intervals 
% Between Wake,Sleep and Anesthesia(divide in first 15 and last 15)
% Pooling data from all channels and patients
%
% 1. Compute peaks and compte its characteristics as in patient per patient analysis
% 2. Compute variance from intervals directly
%
% fileNamesPerState must be a struct of: fileNamesPerState.WakeEMU, etc
% stateNames = {'WakeEMU', 'Sleep', 'WakeOR', 'Anesthesia'};

%% CONFIG
%cfgStats.sheetName = titName;
%cfgStats.xlsFileName = [fileNameComparisonResults,'.xls'];
dirResults = fileparts(fileNameComparisonResults);
cfgStats.dirImages = [dirResults,filesep,'images'];
if ~exist(dirResults,'dir'), mkdir(dirResults); end
if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end
if ~isfield(cfgStats,'strDate'),cfgStats.strDate = date; end
if ~isfield(cfgStats,'whichVariability'),cfgStats.whichVariability = 'STD'; end
if ~isfield(cfgStats,'whatToUse'),cfgStats.whatToUse = 'EEG0MEAN'; end
if ~isfield(cfgStats,'titName'),cfgStats.titName = 'poolResp'; end
if ~isfield(cfgStats,'stateNames'),cfgStats.stateNames = {'WakeEMU', 'Sleep', 'WakeOR', 'Anesthesia'}; end
if ~isfield(cfgStats,'useLog'),cfgStats.useLog = 0; end

indTrialsWakeEMU = 1:cfgStats.trialsWakeEMU;
indTrialsSleep = 1:cfgStats.trialsSleep;
indTrialsORWake = 1:cfgStats.trialsWakeOR; %  first N trials anesthesia as OR Wake
indTrialsAnesthesia = cfgStats.trialsAnesthesia; % last N trials anesthesia -> Unconscious (ONLY N -> to get LAST N)

stateNames = cfgStats.stateNames;

cfgStats.legLabel = cfgStats.stateNames;
cfgStats.ylabel = cfgStats.whatToUse;
cfgInfoPeaks.useFindPeaks =1; %

% Start Diary
diary([dirResults,filesep,'log','ScriptAnesthesiaAnalysis_PooledSNR',cfgStats.titName,'.log'])


%% LOAD DATA and pool all channels together
EEGStimVals = cell2struct(cell(length(stateNames),1),stateNames);
bipChNames = cell2struct(cell(length(stateNames),1),stateNames);
stimChNames = cell2struct(cell(length(stateNames),1),stateNames);
stimPatChNames = cell2struct(cell(length(stateNames),1),stateNames);
bipChAnatRegion = cell2struct(cell(length(stateNames),1),stateNames);
stimChAnatRegion = cell2struct(cell(length(stateNames),1),stateNames);
EEGBaseline = cell2struct(cell(length(stateNames),1),stateNames);

for iState=1:length(stateNames)
    stateName = stateNames{iState};
    [EEGStimVals.(stateName), bipChNames.(stateName), stimChNames.(stateName), stimPatChNames.(stateName), anatomicalInfoPooled.(stateName), EEGBaseline.(stateName), cfgStats] = ...
                readFilesGetPooledEEGPerStateAllPatients(fileNamesPerState.(stateName), stateName, channInfo, cfgStats, cfgStats.whatToUse);
end

cfgStats.bipChWakeEMU = bipChNames.WakeEMU;
cfgStats.bipChSleep = bipChNames.Sleep;
cfgStats.bipChWakeOR = bipChNames.WakeOR;
cfgStats.bipChAnesthesia = bipChNames.Anesthesia;


%% Compare Variance of pooled channels
cfgInfoPeaks.tSamples.N1 = cfgInfoPeaks.tN1 * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tSamples.N2 = cfgInfoPeaks.tN2 * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tSamples.N1N2 = [cfgInfoPeaks.tN1(1) cfgInfoPeaks.tN2(2)] * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tSamples.Long = cfgInfoPeaks.tLong * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tSamples.CCEP = cfgInfoPeaks.CCEP * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tSamples.Baseline = cfgInfoPeaks.tBaseline * cfgStats.Fs + cfgStats.timeOfStimSamples; % to have all the variability measures in the baseline period per trial
%cfgInfoPeaks.tBaselineSamples = cfgInfoPeaks.tBaseline * cfgStats.Fs + cfgStats.timeOfStimSamples;
timeIntervalNames = fieldnames(cfgInfoPeaks.tSamples);

% Wake
[snrValWakeEMU] = computeSNR(EEGStimVals.WakeEMU, cfgInfoPeaks);

%[meanStatsEEGWakeEMU, allDataWakeEMU, indTrialPerCh.WakeEMU, iChKept.WakeEMU] = compVariabilityEEG(EEGStimVals.WakeEMU,  cfgInfoPeaks, indTrialsWakeEMU, cfgStats.whichVariability, cfgStats.useLog);

% Sleep
[snrValSleep] = computeSNR(EEGStimVals.Sleep, cfgInfoPeaks);

% OR Wake (Anestheisa first trials)
[snrValWakeOR] = computeSNR(EEGStimVals.WakeOR, cfgInfoPeaks);

% Anesthesia (Anesthesia last trials) 
[snrValAnesthesia] = computeSNR(EEGStimVals.Anesthesia, cfgInfoPeaks);


%Also put names together for easier comparison and keep only ch used to compute variance
for iState=1:length(stateNames)
    stateName = stateNames{iState};
    cfgStats.bipolarChannels{iState} = bipChNames.(stateName);
    
    bipChNames.(stateName) = bipChNames.(stateName);
    stimChNames.(stateName) = stimChNames.(stateName);
    stimPatChNames.(stateName) = stimPatChNames.(stateName);
    bipChAnatRegion.(stateName) = anatomicalInfoPooled.(stateName).bipChAnatRegionPooled;
    stimChAnatRegion.(stateName) = anatomicalInfoPooled.(stateName).stimChAnatRegionPooled;
    bipChRASCoord.(stateName) = anatomicalInfoPooled.(stateName).bipChRASCoordPooled;
    stimChRASCoord.(stateName) = anatomicalInfoPooled.(stateName).stimChRASCoordPooled;
    rechInStimShaft.(stateName) = anatomicalInfoPooled.(stateName).isRecChInStimShaft;
end

%% Plot together - RIZ: ADD BACK for NEW PATIENTS!!!
%% PUT data together
% allData = {allDataWakeEMU,allDataSleep,allDataWakeOR,allDataAnesthesia};
% allIndTrialPerCh={indTrialPerCh.WakeEMU,indTrialPerCh.Sleep,indTrialPerCh.WakeOR,indTrialPerCh.Anesthesia};
% plotPooledDataWakeSleepAnesthesia(allData, allIndTrialPerCh, cfgStats);
%close all;
pValsPeak=[];
% % % %% Work also on the peaks
% % % cfgStats.xlsFileName = [fileNameComparisonResults,'_Peaks','.xlsx'];
% % % for iTimeName=1:length(timeIntervalNames)
% % %     timeName = timeIntervalNames{iTimeName};
% % %     indTimeSamples = cfgInfoPeaks.tSamples.(timeName); % time (Samples) to compute peak amplitude
% % %     cfgStats.sheetName = ['Peaks',timeName];
% % %     [pVals, infoFirstPeak, infoAllPeaks] = compareNPeaks(allData,allIndTrialPerCh, indTimeSamples(1), indTimeSamples(2), cfgStats, cfgInfoPeaks, [cfgStats.titName ,timeName]);
% % %     pValsPeak.(timeName) = pVals;
% % %     close all;
% % % end

%% Comparisons
cfgStats.xlsFileName = [fileNameComparisonResults,'_SNR','.xlsx'];
% %1.  tN1 Interval
% for iTimeName=1:length(timeIntervalNames)
%     timeName = timeIntervalNames{iTimeName};
%     titNameForPlot = ['Mean ',cfgStats.whichVariability,' ',timeName,' ', cfgStats.titName];
%     cfgStats.sheetName = [cfgStats.whichVariability,timeName];
%     pValsVariability.(timeName) = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGWakeOR, meanStatsEEGAnesthesia, timeName, titNameForPlot, cfgStats);
%     close all;
% end
 cfgStats.sheetName = ['SNR','CCEP'];
pValsSNR = computePooledStatsSNR(snrValWakeEMU, snrValSleep, snrValWakeOR, snrValAnesthesia, 'SNR', ['SNR',cfgStats.titName], cfgStats);

% disp quantile values
disp(['SNR ','WakeEMU',' median= ',num2str(median(snrValWakeEMU)),' q25= ',num2str(quantile(snrValWakeEMU, 0.25)),' q75= ',num2str(quantile(snrValWakeEMU, 0.75))])
disp(['SNR ','Sleep',' median= ',num2str(median(snrValSleep)),' q25= ',num2str(quantile(snrValSleep, 0.25)),' q75= ',num2str(quantile(snrValSleep, 0.75))])
disp(['SNR ','WakeOR',' median= ',num2str(median(snrValWakeOR)),' q25= ',num2str(quantile(snrValWakeOR, 0.25)),' q75= ',num2str(quantile(snrValWakeOR, 0.75))])
disp(['SNR ','Anesthesia',' median= ',num2str(median(snrValAnesthesia)),' q25= ',num2str(quantile(snrValAnesthesia, 0.25)),' q75= ',num2str(quantile(snrValAnesthesia, 0.75))])

%% Save
dirResultsPooledAnalysis = fileparts(cfgStats.xlsFileName);
save([dirResultsPooledAnalysis,filesep,'pooledSNR',cfgStats.strDate,'.mat'], 'stateNames', 'snrValWakeEMU','snrValSleep', 'snrValWakeOR','snrValAnesthesia','pValsSNR', ...
    'bipChNames','stimChNames','stimPatChNames','bipChAnatRegion','stimChAnatRegion', 'bipChRASCoord','stimChRASCoord','rechInStimShaft', 'anatomicalInfoPooled',...
    'channInfo','cfgStats','cfgInfoPeaks');