function script_runLMEMVariability(dirGralResults, pNames, whichVariability)

regionNames = {'all'}; %,'frontal','posterior','temporal'};
posFixDir = '_Neuron2023';
varTimePeriods = 'CCEP';
%whichVariability = 'STD';
anatRegionType = 'OnlyRespCh';
nPatients= length(pNames);

varGralDirName = [dirGralResults, filesep, 'VariabilityRespAnyState', posFixDir, filesep,'poolRespEEG0MEAN',whichVariability];
variabilityFileName = [varGralDirName,varTimePeriods,filesep,whichVariability,anatRegionType,filesep,'VariabilityPerRegion_VarEEG0MEAN ',whichVariability,' ',varTimePeriods,' ',anatRegionType,num2str(nPatients),'pat.mat'];

dirLMMResults = [dirGralResults, filesep,'LMMResults',filesep,'Variability'];
if ~isdir(dirLMMResults), mkdir(dirLMMResults);end

%% Relative Variability
for iRegion=1:length(regionNames)
    diary([dirLMMResults,filesep,'RelativeVariability_LMM_',regionNames{iRegion},'_',date,'.log']);    
    disp(['########### Region: ', regionNames{iRegion},' ##############'])
    OrganizeDataForLMERelativeVariability(variabilityFileName, regionNames{iRegion}, [2,3]) % Sleep/WakeEMU vs. Anesthesia/WakeOR
    
    diary off;
end


%% Absolute Variability
indAbsComp = [1,2,3,4];
for iRegion=1:length(regionNames)
    diary([dirLMMResults,filesep,'Variability_LMM_',regionNames{iRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);    
    disp(['########### Region: ', regionNames{iRegion},' ##############'])
    
    OrganizeDataForLMEVariability(variabilityFileName, regionNames{iRegion}, indAbsComp)
    
    diary off;
end

% pairs of absolute
indRegion =1;

indAbsComp = [1,2];
diary([dirLMMResults,filesep,'Variability_LMM_','_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
disp(['########### ABSOLUTE Variability ','Region: ', regionNames{indRegion},  num2str([indAbsComp(:)]'), ' ##############'])
    OrganizeDataForLMEVariability(variabilityFileName, regionNames{iRegion}, indAbsComp)
diary off;

indAbsComp = [3,4];
diary([dirLMMResults,filesep,'Variability_LMM_','_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
disp(['########### ABSOLUTE Variability ','Region: ', regionNames{indRegion}, num2str([indAbsComp(:)]'), ' ##############'])
    OrganizeDataForLMEVariability(variabilityFileName, regionNames{iRegion}, indAbsComp)
diary off;

indAbsComp = [1,3];
diary([dirLMMResults,filesep,'Variability_LMM_','_',regionNames{indRegion},'_',num2str([indAbsComp(:)]'),'_',date,'.log']);
disp(['########### ABSOLUTE Variability ','Region: ', regionNames{indRegion},num2str([indAbsComp(:)]'), ' ##############'])
    OrganizeDataForLMEVariability(variabilityFileName, regionNames{iRegion}, indAbsComp)
diary off;
