function compareVariabilityPooledData(fileNamesPerState, fileNameComparisonResults, channInfo, cfgStats, cfgInfoPeaks)
% Compare variability of peaks and of time intervals 
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
diary([dirResults,filesep,'log','ScriptAnesthesiaAnalysis_PooledVar',cfgStats.titName,'.log'])


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
%[meanStatsEEGWakeEMU, allDataWakeEMU, indTrialPerCh.WakeEMU, iChKept.WakeEMU] = compVariabilityEEGPerInterval(EEGStimVals.WakeEMU,  cfgInfoPeaks, indTrialsWakeEMU, cfgStats.whichVariability, cfgStats.useLog);
[meanStatsEEGWakeEMU, allDataWakeEMU, indTrialPerCh.WakeEMU, iChKept.WakeEMU] = compVariabilityEEG(EEGStimVals.WakeEMU,  cfgInfoPeaks, indTrialsWakeEMU, cfgStats.whichVariability, cfgStats.useLog);

% Sleep
[meanStatsEEGSleep, allDataSleep, indTrialPerCh.Sleep, iChKept.Sleep] = compVariabilityEEG(EEGStimVals.Sleep, cfgInfoPeaks, indTrialsSleep, cfgStats.whichVariability, cfgStats.useLog);

% OR Wake (Anestheisa first trials)
[meanStatsEEGWakeOR, allDataWakeOR, indTrialPerCh.WakeOR, iChKept.WakeOR] = compVariabilityEEG(EEGStimVals.WakeOR, cfgInfoPeaks, indTrialsORWake, cfgStats.whichVariability, cfgStats.useLog);

% Anesthesia (Anesthesia last trials) 
[meanStatsEEGAnesthesia, allDataAnesthesia, indTrialPerCh.Anesthesia, iChKept.Anesthesia] = compVariabilityEEG(EEGStimVals.Anesthesia, cfgInfoPeaks, indTrialsAnesthesia, cfgStats.whichVariability, cfgStats.useLog);


%Also put names together for easier comparison and keep only ch used to compute variance
for iState=1:length(stateNames)
    stateName = stateNames{iState};
    cfgStats.bipolarChannels{iState} = bipChNames.(stateName)(iChKept.(stateName));
    
    bipChNames.(stateName) = bipChNames.(stateName)(iChKept.(stateName));
    stimChNames.(stateName) = stimChNames.(stateName)(iChKept.(stateName));
    stimPatChNames.(stateName) = stimPatChNames.(stateName)(iChKept.(stateName));
    bipChAnatRegion.(stateName) = anatomicalInfoPooled.(stateName).bipChAnatRegionPooled(iChKept.(stateName));
    stimChAnatRegion.(stateName) = anatomicalInfoPooled.(stateName).stimChAnatRegionPooled(iChKept.(stateName));
    bipChRASCoord.(stateName) = anatomicalInfoPooled.(stateName).bipChRASCoordPooled(iChKept.(stateName),:);
    stimChRASCoord.(stateName) = anatomicalInfoPooled.(stateName).stimChRASCoordPooled(iChKept.(stateName),:);
    rechInStimShaft.(stateName) = anatomicalInfoPooled.(stateName).isRecChInStimShaft(iChKept.(stateName),:);
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
cfgStats.xlsFileName = [fileNameComparisonResults,'_Varibility','.xlsx'];
%1.  tN1 Interval
for iTimeName=1:length(timeIntervalNames)
    timeName = timeIntervalNames{iTimeName};
    titNameForPlot = ['Mean ',cfgStats.whichVariability,' ',timeName,' ', cfgStats.titName];
    cfgStats.sheetName = [cfgStats.whichVariability,timeName];
    pValsVariability.(timeName) = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGWakeOR, meanStatsEEGAnesthesia, timeName, titNameForPlot, cfgStats);
    close all;
end

%% Save
dirResultsPooledAnalysis = fileparts(cfgStats.xlsFileName);
save([dirResultsPooledAnalysis,filesep,'pooledStdComp',cfgStats.strDate,'.mat'], 'stateNames', 'meanStatsEEGWakeEMU','meanStatsEEGSleep', 'meanStatsEEGWakeOR','meanStatsEEGAnesthesia', ...
    'bipChNames','stimChNames','stimPatChNames','bipChAnatRegion','stimChAnatRegion', 'bipChRASCoord','stimChRASCoord','rechInStimShaft', 'anatomicalInfoPooled',...
    'indTrialPerCh', 'iChKept', 'pValsPeak', 'pValsVariability',...
    'channInfo','cfgStats','cfgInfoPeaks');