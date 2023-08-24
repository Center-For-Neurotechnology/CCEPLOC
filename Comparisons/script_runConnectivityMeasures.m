function script_runConnectivityMeasures(dirGral,dirGralResults, channInfoAllPat, timeIntervalMs, whatToUse, posFixDir, cfgStats)

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
allStatesTitName = {'WakeEMU', 'Sleep', 'WakeOR','Anest'}; % USe Anest instead of Anesthesia because we are using this to remove from title and compare channels!! - poor hack!

posFixTimeAnalysisForTitle = [num2str(timeIntervalMs(1)),'-',num2str(timeIntervalMs(2))];
posFixTimeAnalysisForFile = [num2str(timeIntervalMs(1)/1000),'_',num2str(timeIntervalMs(2)/1000)];

titNameGRal = ['Centrality',posFixTimeAnalysisForTitle,posFixDir];

%cfgStats.regionsToCompare = {'anterior','posTemp','allButAnt','all','PFC','posterior', 'temporal'};
%cfgStats.regionsToCompare = {'all','anterior','frontal','PFC','OF','allButAnt','posTemp','posterior', 'temporal','central','cingulate','latTemp','posCentral','subcorMTL'}; %,'thalCaud'
cfgStats.regionsToCompare = {'all','anterior','frontal','allButAnt','posterior', 'temporal','central','cingulate',...
                            'latTemp','dlPFC','vlPFC','dmPFC','OF','ACC'}; %,'thalCaud'

%% Organize files
nPatients = numel(channInfoAllPat);
fileNameRespChAllPatAllStates = cell(nPatients, numel(allStates));
for iP=1:nPatients
    pName = channInfoAllPat{iP}.pNames;
    dirData =  [dirGral, filesep, pName, filesep, 'ResultsAnalysisAllCh',posFixDir,filesep,'ResponsiveChannelsAllStates',whatToUse]; 
    for iState=1:numel(allStates)
        fileNameRespChAllPatAllStates{iP,iState} = [dirData,filesep,'lstResponsiveChannel',pName,'_',allStates{iState},'_P2P2std',posFixTimeAnalysisForFile,'.mat'];
    end
    pNames{iP}=pName;
    stimChPerPat{iP} = channInfoAllPat{iP}.stimBipChNames;
    respChAnyStaChPerPat{iP} = channInfoAllPat{iP}.recBipolarChPerStim;
end

dirConnResults = [dirGralResults, filesep,'ConnectivityResults',filesep, titNameGRal, filesep, whatToUse];

%% cfgStats
cfgStats.pNames = pNames;
cfgStats.allStates = allStates;
cfgStats.allStatesTitName = allStatesTitName;
%cfgStats.sheetName = 'nRespCh';
cfgStats.useParam = 0; % 0 = non parametric / 1=ttest - no reason to expect normal distribution
cfgStats.posRegionFor = { 'OnlyRespCh'};
cfgStats.stimChPerPat = stimChPerPat;
cfgStats.respChAnyStaChPerPat = respChAnyStaChPerPat;
cfgStats.channInfoAllPat = channInfoAllPat;
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
cfgStats.pairComps = pairComps;

%% run brain connectivity toolbox
[fileNameCentralityAllStatesAllPat, fileNamesCentralityPerPat]= computeCentralityMeas(fileNameRespChAllPatAllStates, dirConnResults, cfgStats); %, whichRecChannels)

%% Comparison across states
compTitName = 'CentANYSTATE';
cfgStats.regionsToCompare = {'all','anterior','frontal','allButAnt','posterior', 'temporal','central','cingulate','posCentral','antCentral',...
                            'latTemp','dlPFC','vlPFC','dmPFC','OF','ACC'}; %,'thalCaud'

cfgStats.useParam=0; % permutation test
for iRegionFor=1:length(cfgStats.posRegionFor)
    cfgStatsPerFor = cfgStats;
    cfgStatsPerFor.anatRegionFor= cfgStats.posRegionFor{iRegionFor};   % options: 'stimCh or respCh'or StimRespCh
    cfgStatsPerFor.titName = [compTitName,' ',cfgStatsPerFor.anatRegionFor]; %,' ', num2str(length(pNames)),'p'];
    dirResultsCompar = [dirConnResults,filesep,compTitName,cfgStatsPerFor.anatRegionFor];
    fileNameComparisonResults = [dirResultsCompar,filesep,compTitName,'_',cfgStatsPerFor.anatRegionFor,'_', num2str(length(pNames)),'p'];
    cfgStatsPerFor.xlsFileName = [fileNameComparisonResults,'.xlsx'];
    
    compareCentralityMeasuresPerStatePerRegion(fileNamesCentralityPerPat, dirResultsCompar, cfgStatsPerFor, 'ANYSTATE')
end


% pairComps = [1,3;1,2;3,4];
% nComps = size(pairComps,1);
% 
% for iP=1:nPatients
%     pName = cfgStats.pNames{iP};
%     for iComp=1:nComps
%         statesInComp = [allStates{pairComps(iComp,:)}];
%         
%         fileNamesCentralityPerPat{iComp,iP} = [dirConnResults,filesep,'CentralityMeasures_',statesInComp,'_',pName,'.mat'];
%     end
% end