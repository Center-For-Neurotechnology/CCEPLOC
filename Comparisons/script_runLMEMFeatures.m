function script_runLMEMFeatures(dirGralResults, pNames, whichRecChannels, thisFeature)

regionNames = {'all'}; %,'frontal','posterior','temporal'};

%thisFeature= 'ptpResponsiveCh'; %'dataMaxMinAmp'; %
%whichRespType = 'RespCh'; % 'ANYState'; %

anatRegionType = 'OnlyRespCh';
nPatients= length(pNames);

featGralDirName = [dirGralResults, filesep, 'Feat',whichRecChannels,anatRegionType];
featuresMatFile = [featGralDirName,filesep,'FeatRespChPerRegion_Feat',whichRecChannels,'_',anatRegionType,'_',num2str(nPatients),'pat.mat'];

dirLMMResults = [dirGralResults, filesep,'LMMResults',filesep,'Features',thisFeature];
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
disp(['########### ABSOLUTE ',thisFeature ,'Region: ', regionNames{indRegion}, num2str([indAbsComp(:)]'), ' ##############'])
OrganizeDataForLMEFeatures(featuresMatFile, regionNames{indRegion}, indAbsComp,thisFeature)
diary off;

indAbsComp = [1,2];
diary([dirLMMResults,filesep,'Features_LMM_',thisFeature,'_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
disp(['########### ABSOLUTE ',thisFeature ,'Region: ', regionNames{indRegion},  num2str([indAbsComp(:)]'), ' ##############'])
OrganizeDataForLMEFeatures(featuresMatFile, regionNames{indRegion}, indAbsComp,thisFeature)
diary off;

indAbsComp = [3,4];
diary([dirLMMResults,filesep,'Features_LMM_',thisFeature,'_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
disp(['########### ABSOLUTE ',thisFeature ,'Region: ', regionNames{indRegion}, num2str([indAbsComp(:)]'), ' ##############'])
OrganizeDataForLMEFeatures(featuresMatFile, regionNames{indRegion}, indAbsComp,thisFeature)
diary off;

indAbsComp = [1,3];
diary([dirLMMResults,filesep,'Features_LMM_',thisFeature,'_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
disp(['########### ABSOLUTE ',thisFeature ,'Region: ', regionNames{indRegion},num2str([indAbsComp(:)]'), ' ##############'])
OrganizeDataForLMEFeatures(featuresMatFile, regionNames{indRegion}, indAbsComp,thisFeature)
diary off;
