function  script_CompareVariabilityPerRegion(dirResultsVar, pNames, cfgStats, posFixFile)
% Statistical Comparison of Variability for paper CCEP LOC brain states

if ~exist('pNames','var'), pNames = {'pXX'}; end
if ~isfield(cfgStats,'whatToUse'), cfgStats.whatToUse = 'EEG0MEAN'; end % 'PERTRIAL' or 'PERTRIALnonSOZ'
if ~exist('posFixFile','var'), posFixFile = '03-May-2021'; end % file

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
allStatesTitName = {'WakeEMU', 'Sleep', 'WakeOR','Anest'}; % USe Anest instead of Anesthesia because we are using this to remove from title and compare channels!! - poor hack!

titNameGRal = ['Var',cfgStats.whatToUse];%posFixTimeAnalysisForTitle,

if ~isfield(cfgStats,'useParam'), cfgStats.useParam = 0; end %Given the large number t-test seems appropriate
if ~isfield(cfgStats,'whatIntervalToUse'), cfgStats.whatIntervalToUse = 'CCEP'; end % options: CCEP, N1, N2, N1N2, Long, Baseline
if ~isfield(cfgStats,'whichVariability'), cfgStats.whichVariability = 'STD'; end % options: 2575RANGE, STD % - changed to 25-75 range to make it more robust to outliers - original: 'STD'
if ~isfield(cfgStats,'whatToUse'), cfgStats.whatToUse = 'EEG0MEAN'; end % options:'PERTRIAL' or 'PERTRIALnonSOZ'
if ~isfield(cfgStats,'regionsToCompare')
    %cfgStats.regionsToCompare = {'all','anterior','posTemp','allButAnt','PFC','posterior', 'temporal'};
    cfgStats.regionsToCompare = {'all','anterior','frontal','PFC','OF','allButAnt','posTemp','posterior', 'temporal','central','cingulate','latTemp',...
        'posCentral','antCentral','subcorMTL','dlPFC','vlPFC','dmPFC','mOF','lOF','ACC'}; %,'thalCaud'
end
cfgStats.allStates = allStates;
cfgStats.allStatesTitName = allStatesTitName;

%% Variability file
% Results
pooledVariabilityFileName = [dirResultsVar,filesep,'pooledStdComp',posFixFile,'.mat'];

% Start Diary
%if ~exist(dirGralResults,'dir'),mkdir(dirGralResults); end
%diary([dirGralResults,filesep,'log','CompareRespChannelsPerRegion.log'])


%% Run comparisons
cfgStats.pNames = pNames;

%% Variability analysis per region
compTitName = cfgStats.whichVariability;
posRegionFor = {'StimCh','OnlyRespCh','StimRespCh'};
parfor iRegFor=1:numel(posRegionFor)
    cfgStatsThisLoop = cfgStats;
    cfgStatsThisLoop.anatRegionFor= posRegionFor{iRegFor};   % options: 'stimCh or respCh'or StimRespCh
    dirResults = [dirResultsVar, filesep,compTitName,cfgStatsThisLoop.anatRegionFor];
    cfgStatsThisLoop.titName = [titNameGRal, ' ', compTitName,' ',cfgStatsThisLoop.whatIntervalToUse,' ',cfgStatsThisLoop.anatRegionFor];
    fileNameComparisonResults = [dirResults,filesep,cfgStatsThisLoop.titName, num2str(length(pNames)),'pat'];
    cfgStatsThisLoop.xlsFileName = [fileNameComparisonResults,'.xlsx'];
    cfgStatsThisLoop.sheetName = compTitName;
    
    compareVariabilityPerStatePerRegion(pooledVariabilityFileName, dirResults, cfgStatsThisLoop)
end


%diary off;
