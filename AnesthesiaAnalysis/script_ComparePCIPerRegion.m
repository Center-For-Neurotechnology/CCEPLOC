function  script_ComparePCIPerRegion(dirGral, dirGralResults, channInfoAllPat, timeAnalysis, whatToUse, posFixDir)
% Statistical Comparison of PCIst for paper CCEP LOC brain states

if ~exist('channInfoAllPat','var'), channInfoAllPat{1}.pNames = {'pXX'};end %
if ~exist('timeAnalysis','var'), timeAnalysis = [0 600]; end % in ms
if ~exist('whatToUse','var'), whatToUse = 'PERTRIALnonSOZ'; end % 'PERTRIAL' or 'PERTRIALnonSOZ'
if ~exist('posFixDir','var'), posFixDir = '_CCEPLOC'; end % both for data dir and for results dir

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
allStatesTitName = {'WakeEMU', 'Sleep', 'WakeOR','Anest'}; % USe Anest instead of Anesthesia because we are using this to remove from title and compare channels!! - poor hack!

posFixTimeAnalysisForTitle = [num2str(timeAnalysis(1)),'-',num2str(timeAnalysis(2))];
posFixTimeAnalysisForFile = [num2str(timeAnalysis(1)/1000),'_',num2str(timeAnalysis(2)/1000)];

titNameGRal = [whatToUse,'t',posFixTimeAnalysisForTitle,posFixDir];

cfgStats.regionsToCompare = {'all','anterior','frontal','PFC','OF','allButAnt','posTemp','posterior', 'temporal','central','cingulate','latTemp','posCentral','subcorMTL','antCentral'}; %,'thalCaud'

%% Organize files
nPatients = numel(channInfoAllPat);
fileNamePCIAllStates = cell(nPatients, numel(allStates));
for iP=1:nPatients
    pName = channInfoAllPat{iP}.pNames;
    dirData =  [dirGral, filesep, pName, filesep, 'ResultsAnalysisAllCh',posFixDir,filesep,'PCIValsAllStates',whatToUse];
    for iState=1:numel(allStates)
        fileNamePCIAllStates{iP,iState} = [dirData,filesep,'PCIVals2',pName,'_',allStates{iState},posFixTimeAnalysisForFile,'.mat'];
    end
    pNames{iP}=pName;
    stimChPerPat{iP} = channInfoAllPat{iP}.stimBipChNames;
end

% Results
dirGralPCIResults = [dirGralResults, filesep,'PCIResults',filesep, titNameGRal];
    
% Start Diary
%if ~exist(dirGralResults,'dir'),mkdir(dirGralResults); end
%diary([dirGralResults,filesep,'log','CompareRespChannelsPerRegion.log'])


%% Run comparisons
cfgStats.pNames = pNames;
cfgStats.allStates = allStates;
cfgStats.allStatesTitName = allStatesTitName;
cfgStats.useParam = 0; % no reason to expect normal distribution
cfgStats.stimChPerPat = stimChPerPat;
cfgStats.channInfoAllPat =channInfoAllPat;

%% PCI analysis per region
compTitName = 'PCI';
posRegionFor = {'StimCh'};
cfgStats.anatRegionFor= posRegionFor{1};   % options: 'stimCh or respCh'or StimRespCh
dirResults = [dirGralPCIResults,filesep,compTitName,cfgStats.anatRegionFor];
cfgStats.titName = [ compTitName,' ',cfgStats.anatRegionFor];
fileNameComparisonResults = [dirResults,filesep,cfgStats.titName, num2str(length(pNames)),'pat'];
cfgStats.xlsFileName = [fileNameComparisonResults,'.xlsx'];
cfgStats.sheetName = compTitName;

comparePCIPerStatePerRegion(fileNamePCIAllStates, dirResults, cfgStats)



%diary off;
