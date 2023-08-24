function compareVariabilityPooledDataPerRegion(fileNamesAnesthesia, fileNamesWakeOR, fileNamesWakeEMU, fileNamesSleep, fileNameComparisonResults, channInfo, cfgStats, cfgInfoPeaks, titName, whatToUse)
% Compare variability of peaks and of time intervals 
% Between Wake,Sleep and Anesthesia(divide in first 15 and last 15)
% Pooling data from all channels and patients
%
% 1. Compute peaks and compte its characteristics as in patient per patient analysis
% 2. Compute variance from intervals directly

%% CONFIG
cfgStats.titName = titName;
%cfgStats.sheetName = titName;
%cfgStats.xlsFileName = [fileNameComparisonResults,'.xls'];
dirResults = fileparts(fileNameComparisonResults);
cfgStats.dirImages = [dirResults,filesep,'images'];
if ~exist(dirResults,'dir'), mkdir(dirResults); end
if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end


indTrialsWakeEMU = 1:cfgStats.trialsWakeEMU;
indTrialsSleep = 1:cfgStats.trialsSleep;
indTrialsORWake = 1:cfgStats.trialsWakeOR; %  first N trials anesthesia as OR Wake
indTrialsAnesthesia = cfgStats.trialsAnesthesia; % last N trials anesthesia -> Unconscious (ONLY N -> to get LAST N)
cfgStats.legLabel = {'WakeEMU', 'Sleep', 'WakeOR', 'Anesthesia'};

cfgStats.ylabel = whatToUse;
cfgStats.whichVariability='STD';
cfgInfoPeaks.useFindPeaks =1; %

% Start Diary
diary([dirResults,filesep,'log','ScriptAnesthesiaAnalysis_PooledVar.log'])


%% LOAD DATA and pool all channels together
% Wake  data
EEGStimWakeEMU = [];
bipChWakeEMU = [];
stimChWakeEMU = [];
stimPatChWakeEMU = [];
EEGBaselineWakeEMU=[];
for iP=1:numel(channInfo)
    if ~isempty(fileNamesWakeEMU{iP})
        [EEGStimPerPat, EEGStimSameSignPerPat, EEGBaselinePerPat, selBipolarChanNames, selStimChannels, cfgStats] = readFilesGetPooledEEG(fileNamesWakeEMU{iP}, channInfo{iP}, cfgStats, whatToUse);
        if isfield(channInfo{iP}, 'trialsToExcludeWakeEMU') % remove trials to exclude
            for iCh=1:numel(channInfo{iP}.trialsToExcludeWakeEMU)
                indInChFromFile = find(strcmpi(selStimChannels,channInfo{iP}.stimBipChNames{iCh}));
                for iChEEG=1:length(indInChFromFile)
                    EEGStimSameSignPerPat{indInChFromFile(iChEEG)}(:,channInfo{iP}.trialsToExcludeWakeEMU{iCh})=[];
                end
            end
        end
        EEGStimWakeEMU = [EEGStimWakeEMU, EEGStimSameSignPerPat];
        EEGBaselineWakeEMU = [EEGBaselineWakeEMU, EEGBaselinePerPat];
      %  bipChWake = [bipChWake, strcat(selBipolarChanNames,' ',channInfo{iP}.pNames)];
        bipChWakeEMU = [bipChWakeEMU, strcat('rec',selBipolarChanNames,' st',selStimChannels,' ',channInfo{iP}.pNames)];
        stimChWakeEMU = [stimChWakeEMU, selStimChannels];
        stimPatChWakeEMU = [stimPatChWakeEMU, strcat(selStimChannels,'_',channInfo{iP}.pNames)];
        disp([channInfo{iP}.pNames,' WAKE EMU',num2str(length(EEGStimSameSignPerPat)),' rec channs - reading MAT files done!'])
    end
end

% Sleep  data
EEGStimSleep = [];
bipChSleep = [];
stimChSleep = [];
stimPatChSleep = [];
EEGBaselineSleep=[];
for iP=1:numel(channInfo)
    if ~isempty(fileNamesSleep{iP})
        [EEGStimPerPat, EEGStimSameSignPerPat, EEGBaselinePerPat, selBipolarChanNames, selStimChannels, cfgStats] = readFilesGetPooledEEG(fileNamesSleep{iP}, channInfo{iP}, cfgStats, whatToUse);
        if isfield(channInfo{iP}, 'trialsToExcludeSleep') % remove trials to exclude
            for iCh=1:numel(channInfo{iP}.trialsToExcludeSleep)
                indInChFromFile = find(strcmpi(selStimChannels,channInfo{iP}.stimBipChNames{iCh}));
                for iChEEG=1:length(indInChFromFile)
                    EEGStimSameSignPerPat{indInChFromFile(iChEEG)}(:,channInfo{iP}.trialsToExcludeSleep{iCh})=[];
                end
            end
        end
        EEGStimSleep = [EEGStimSleep, EEGStimSameSignPerPat];
        EEGBaselineSleep = [EEGBaselineSleep, EEGBaselinePerPat];
        %bipChSleep = [bipChSleep, strcat(selBipolarChanNames,' ',channInfo{iP}.pNames)];
        bipChSleep = [bipChSleep, strcat('rec',selBipolarChanNames,' st',selStimChannels,' ',channInfo{iP}.pNames)];
        stimChSleep = [stimChSleep, selStimChannels];
        stimPatChSleep = [stimPatChSleep, strcat(selStimChannels,'_',channInfo{iP}.pNames)];
        disp([channInfo{iP}.pNames,' SLEEP reading MAT files done!'])
    end
end

% Wake  OR data
EEGStimWakeOR = [];
bipChWakeOR = [];
stimChWakeOR = [];
stimPatChWakeOR = [];
EEGBaselineWakeOR=[];
for iP=1:numel(channInfo)
    if ~isempty(fileNamesWakeOR{iP})
        [EEGStimPerPat, EEGStimSameSignPerPat, EEGBaselinePerPat, selBipolarChanNames, selStimChannels, cfgStats] = readFilesGetPooledEEG(fileNamesWakeOR{iP}, channInfo{iP}, cfgStats, whatToUse);
        if isfield(channInfo{iP}, 'trialsToExcludeWakeOR') % remove trials to exclude
            for iCh=1:numel(channInfo{iP}.trialsToExcludeWakeOR)
                indInChFromFile = find(strcmpi(selStimChannels,channInfo{iP}.stimBipChNames{iCh}));
                for iChEEG=1:length(indInChFromFile)
                    EEGStimSameSignPerPat{indInChFromFile(iChEEG)}(:,channInfo{iP}.trialsToExcludeWakeOR{iCh})=[];
                end
            end
        end
        EEGStimWakeOR = [EEGStimWakeOR, EEGStimSameSignPerPat];
        EEGBaselineWakeOR = [EEGBaselineWakeOR, EEGBaselinePerPat];
      %  bipChWake = [bipChWake, strcat(selBipolarChanNames,' ',channInfo{iP}.pNames)];
        bipChWakeOR = [bipChWakeOR, strcat('rec',selBipolarChanNames,' st',selStimChannels,' ',channInfo{iP}.pNames)];
        stimChWakeOR = [stimChWakeOR, selStimChannels];
        stimPatChWakeOR = [stimPatChWakeOR, strcat(selStimChannels,'_',channInfo{iP}.pNames)];
        disp([channInfo{iP}.pNames,' WAKE OR',num2str(length(EEGStimSameSignPerPat)),' rec channs - reading MAT files done!'])
    end
end

% Anesthesia data
EEGStimAnesthesia = [];
bipChAnesthesia = [];
stimChAnesthesia = [];
stimPatChAnesthesia = [];
EEGBaselineAnesthesia=[];
for iP=1:numel(channInfo)
    [EEGStimPerPat, EEGStimSameSignPerPat, EEGBaselinePerPat, selBipolarChanNames, selStimChannels, cfgStats] = readFilesGetPooledEEG(fileNamesAnesthesia{iP}, channInfo{iP}, cfgStats, whatToUse);
    if isfield(channInfo{iP}, 'trialsToExcludeAnesthesia') % remove trials to exclude
        for iCh=1:numel(channInfo{iP}.trialsToExcludeAnesthesia)
            indInChFromFile = find(strcmpi(selStimChannels,channInfo{iP}.stimBipChNames{iCh}));
           for iChEEG=1:length(indInChFromFile)
                EEGStimSameSignPerPat{indInChFromFile(iChEEG)}(:,channInfo{iP}.trialsToExcludeAnesthesia{iCh})=[];
            end
        end
    end
    EEGStimAnesthesia = [EEGStimAnesthesia, EEGStimSameSignPerPat];
    EEGBaselineAnesthesia = [EEGBaselineAnesthesia, EEGBaselinePerPat];
    bipChAnesthesia = [bipChAnesthesia, strcat('rec',selBipolarChanNames,' st',selStimChannels,' ',channInfo{iP}.pNames)];
    stimChAnesthesia = [stimChAnesthesia, selStimChannels];
    stimPatChAnesthesia = [stimPatChAnesthesia, strcat(selStimChannels,'_',channInfo{iP}.pNames)];
    disp([channInfo{iP}.pNames,' ANESTHESIA reading MAT files done!'])
end

cfgStats.bipChWakeEMU = bipChWakeEMU;
cfgStats.bipChSleep = bipChSleep;
cfgStats.bipChWakeOR = bipChWakeOR;
cfgStats.bipChAnesthesia = bipChAnesthesia;


%% Compare Variance of pooled channels
cfgInfoPeaks.tN1Samples = cfgInfoPeaks.tN1 * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tN2Samples = cfgInfoPeaks.tN2 * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tLongSamples = cfgInfoPeaks.tLong * cfgStats.Fs + cfgStats.timeOfStimSamples;
cfgInfoPeaks.tBaselineSamples = cfgInfoPeaks.tBaseline * cfgStats.Fs + cfgStats.timeOfStimSamples;

% Wake
[meanStatsEEGWakeEMU, allDataWakeEMU, indTrialWakeEMUPerCh, iChKeptWakeEMU] = compVariabilityEEG(EEGStimWakeEMU, EEGBaselineWakeEMU, cfgInfoPeaks, indTrialsWakeEMU, cfgStats.whichVariability);

% Sleep
[meanStatsEEGSleep, allDataSleep, indTrialSleepPerCh, iChKeptSleep] = compVariabilityEEG(EEGStimSleep, EEGBaselineSleep, cfgInfoPeaks, indTrialsSleep, cfgStats.whichVariability);

% OR Wake (Anestheisa first trials)
[meanStatsEEGWakeOR, allDataWakeOR, indTrialWakeORPerCh, iChKeptWakeOR] = compVariabilityEEG(EEGStimWakeOR, EEGBaselineWakeOR, cfgInfoPeaks, indTrialsORWake, cfgStats.whichVariability);

% Anesthesia (Anesthesia last trials) 
[meanStatsEEGAnesthesia, allDataAnesthesia, indTrialAnesthesiaPerCh, iChKeptAnesthesia] = compVariabilityEEG(EEGStimAnesthesia, EEGBaselineAnesthesia, cfgInfoPeaks, indTrialsAnesthesia, cfgStats.whichVariability);

close all;
%% PUT data together
allData = {allDataWakeEMU,allDataSleep,allDataWakeOR,allDataAnesthesia};
allIndTrialPerCh={indTrialWakeEMUPerCh,indTrialSleepPerCh,indTrialWakeORPerCh,indTrialAnesthesiaPerCh};

%Also put names together for easier comparison and keep only ch used to compute variance
cfgStats.bipolarChannels{find(strcmpi('WakeEMU',cfgStats.legLabel))} = cfgStats.bipChWakeEMU(iChKeptWakeEMU);
cfgStats.bipolarChannels{find(strcmpi('Sleep',cfgStats.legLabel))} = cfgStats.bipChSleep(iChKeptSleep);
cfgStats.bipolarChannels{find(strcmpi('WakeOR',cfgStats.legLabel))} = cfgStats.bipChWakeOR(iChKeptWakeOR);
cfgStats.bipolarChannels{find(strcmpi('Anesthesia',cfgStats.legLabel))} = cfgStats.bipChAnesthesia(iChKeptAnesthesia);

stimPatChWakeEMU = stimPatChWakeEMU(iChKeptWakeEMU);
stimPatChSleep = stimPatChSleep(iChKeptSleep);
stimPatChWakeOR = stimPatChWakeOR(iChKeptWakeOR);
stimPatChAnesthesia = stimPatChAnesthesia(iChKeptAnesthesia);
stimChWakeEMU = stimChWakeEMU(iChKeptWakeEMU);
stimChSleep = stimChSleep(iChKeptSleep);
stimChWakeOR = stimChWakeOR(iChKeptWakeOR);
stimChAnesthesia = stimChAnesthesia(iChKeptAnesthesia);

%% Plot together - RIZ: ADD BACK for NEW PATIENTS!!!
cfgStats.titName = titName;
%plotPooledDataWakeSleepAnesthesia(allData, allIndTrialPerCh, cfgStats);
close all;

%% Work also on the peaks
cfgStats.xlsFileName = [fileNameComparisonResults,'_Peaks','.xlsx'];
cfgStats.sheetName = 'PeaksN1';
[pValsPeakN1, infoFirstPeak, infoAllPeaks] = compareNPeaks(allData,allIndTrialPerCh, cfgInfoPeaks.tN1Samples(1), cfgInfoPeaks.tN1Samples(2), cfgStats, cfgInfoPeaks, [cfgStats.titName ,'N1']);
close all;
cfgStats.sheetName = 'PeaksN2';
[pValsPeakN2, infoFirstPeak, infoAllPeaks] = compareNPeaks(allData,allIndTrialPerCh, cfgInfoPeaks.tN2Samples(1), cfgInfoPeaks.tN2Samples(2), cfgStats, cfgInfoPeaks, [cfgStats.titName ,'N2']);
close all;
cfgStats.sheetName = 'PeaksLong';
[pValsPeakLong, infoFirstPeak, infoAllPeaks] = compareNPeaks(allData,allIndTrialPerCh, cfgInfoPeaks.tLongSamples(1), cfgInfoPeaks.tLongSamples(2), cfgStats, cfgInfoPeaks, [cfgStats.titName ,'Long']);
close all;
cfgStats.sheetName = 'PeaksN1N2';
[pValsPeakN1N2, infoFirstPeak, infoAllPeaks] = compareNPeaks(allData,allIndTrialPerCh, cfgInfoPeaks.tN1Samples(1), cfgInfoPeaks.tN2Samples(2), cfgStats, cfgInfoPeaks, [cfgStats.titName ,'N1N2']);

close all;

%% Comparisons
cfgStats.xlsFileName = [fileNameComparisonResults,'_Varibility','.xlsx'];
cfgStats.sheetName = 'STD';
%1.  tN1 Interval
titNameForPlot = ['Mean Std 10-60ms ', titName];
pValsVariabilityN1 = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGWakeOR, meanStatsEEGAnesthesia, 'N1', titNameForPlot, cfgStats);
close all;

%tN2 Interval
titNameForPlot = ['Mean Std 60-250ms ', titName];
pValsVariabilityN2 = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGWakeOR, meanStatsEEGAnesthesia, 'N2', titNameForPlot, cfgStats);
close all;

%Long Interval
titNameForPlot = ['Mean Std 250-1000ms ', titName];
pValsVariabilityLong = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGWakeOR, meanStatsEEGAnesthesia, 'Long', titNameForPlot, cfgStats);
close all;

%N1N2 Interval
titNameForPlot = ['Mean Std 10-250ms ', titName];
pValsVariabilityN1N2 = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGWakeOR, meanStatsEEGAnesthesia, 'N1N2', titNameForPlot, cfgStats);
close all;

%% Save
dirResultsPooledAnalysis = fileparts(cfgStats.xlsFileName);
save([dirResultsPooledAnalysis,filesep,'pooledStdComp',date,'.mat'], 'meanStatsEEGWakeEMU','meanStatsEEGSleep', 'meanStatsEEGWakeOR','meanStatsEEGAnesthesia', ...
    'bipChWakeEMU','bipChSleep','bipChWakeOR','bipChAnesthesia','stimChWakeEMU','stimChSleep','stimChWakeOR','stimChAnesthesia', ...
    'stimPatChWakeEMU','stimPatChSleep','stimPatChWakeOR','stimPatChAnesthesia',...
    'indTrialWakeEMUPerCh','indTrialSleepPerCh','indTrialWakeORPerCh','indTrialAnesthesiaPerCh',...
    'iChKeptWakeEMU','iChKeptSleep','iChKeptWakeOR','iChKeptAnesthesia',...
    'pValsPeakN1','pValsPeakN2','pValsPeakLong','pValsPeakN1N2',...
    'pValsVariabilityN1','pValsVariabilityN2','pValsVariabilityLong','pValsVariabilityN1N2',...
    'channInfo','cfgStats','cfgInfoPeaks');