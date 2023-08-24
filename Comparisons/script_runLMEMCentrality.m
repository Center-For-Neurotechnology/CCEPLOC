function script_runLMEMCentrality(dirGralResults, pNames, thisFeature, strDate)

regionNames = {'all'}; %,'frontal','posterior','temporal'};

%thisFeature= 'ptpResponsiveCh'; %'dataMaxMinAmp'; %
%whichRespType = 'RespCh'; % 'ANYState'; %

anatRegionType = 'OnlyRespCh';
nPatients= length(pNames);

featGralDirName = [dirGralResults, filesep, 'ConnectivityResults',filesep, 'Centrality10-600_Neuron2023',filesep,'PERTRIALnonSOZMEAN'];
featuresMatFile = [featGralDirName,filesep,'CentralityMeasures_AllStates_p',num2str(nPatients),strDate,'.mat'];

dirLMMResults = [dirGralResults, filesep,'LMMResults',filesep,'Centrality',thisFeature];
if ~isdir(dirLMMResults), mkdir(dirLMMResults);end

indRegion=1; % only for ALL regions 

%% Relative Features
    diary([dirLMMResults,filesep,'RelativeFeatures_LMM_',thisFeature,'_',regionNames{indRegion},'_',date,'.log']);    
    disp(['########### RELATIVE ',thisFeature ,'Region: ', regionNames{indRegion},' ##############'])
    OrganizeDataForLMERelativeFeatures(featuresMatFile, regionNames{indRegion}, [2 3],thisFeature)
    
    diary off;



%% Absolute Features
indAbsComp = [1,2,3,4];
    diary([dirLMMResults,filesep,'Features_LMM_',thisFeature,'_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
    disp(['########### ABSOLUTE ',thisFeature ,'Region: ', regionNames{indRegion},' ##############'])
    OrganizeDataForLMEFeatures(featuresMatFile, regionNames{indRegion}, indAbsComp,thisFeature)
    
    diary off;
