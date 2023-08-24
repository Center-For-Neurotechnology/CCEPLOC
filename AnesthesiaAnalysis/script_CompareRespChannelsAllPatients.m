function [fileNameRespChAllPatAllStates, cfgStats] = script_CompareRespChannelsAllPatients(dirGral, dirGralResults, pNames, timeAnalysis, whatToUse, posFixDir)

if ~exist('pNames','var'), pNames = {'pXX'}; end
if ~exist('timeAnalysis','var'), timeAnalysis = [10 150]; end % in ms
if ~exist('posFixDir','var'), posFixDir = []; end % both for data dir and for results dir

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
allStatesTitName = {'WakeEMU', 'Sleep', 'WakeOR','Anest'}; % USe Anest instead of Anesthesia because we are using this to remove from title and compare channels!! - poor hack!

posFixTimeAnalysisForTitle = [num2str(timeAnalysis(1)),'-',num2str(timeAnalysis(2))];
posFixTimeAnalysisForFile = [num2str(timeAnalysis(1)/1000),'_',num2str(timeAnalysis(2)/1000)];

titName = ['nResp',posFixTimeAnalysisForTitle,posFixDir];


%% Organize files
nPatients = numel(pNames);
fileNameRespChAllPatAllStates = cell(nPatients, numel(allStates));
for iP=1:nPatients
    dirData =  [dirGral, filesep, pNames{iP}, filesep, 'ResultsAnalysisAllCh',posFixDir, filesep,'ResponsiveChannelsAllStates',whatToUse]; 
    for iState=1:numel(allStates)
        fileNameRespChAllPatAllStates{iP,iState} = [dirData,filesep,'lstResponsiveChannel',pNames{iP},'_',allStates{iState},'_P2P2std',posFixTimeAnalysisForFile,'.mat'];
    end
end

dirResults = [dirGralResults, filesep,'ConnectivityResults',filesep, titName, filesep, whatToUse];

%% Run comparison of nResp and perc # Resp
fileNameComparisonResults = [dirResults,filesep,titName,[pNames{:}],'.mat'];
cfgStats.pNames = pNames;
cfgStats.allStates = allStates;
cfgStats.allStatesTitName = allStatesTitName;
cfgStats.titName = titName;
cfgStats.xlsFileName = [dirResults,filesep,titName,'_nP',num2str(length(pNames)),'_nRespChann','.xlsx'];
cfgStats.useParam = 0; % no reason to expect normal distribution
cfgStats = compareResponsiveChannelsPerState(fileNameRespChAllPatAllStates, dirResults, cfgStats);


