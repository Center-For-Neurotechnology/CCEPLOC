function script_corrPCIRESChVar(dirGralResults, pNames, posFixDir, whatToUseRespCh, anatRegionType)
if ~exist('anatRegionType','var'), anatRegionType = 'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 
varTimePeriod = 'CCEP'; %'Baseline';% 
whichVariability= 'STD'; %'TRIALMAD'; %'MAD'; %'2575RANGE'; % 'VARERR'; 
if ~exist('whatToUseRespCh','var'), whatToUseRespCh = 'PERTRIALnonSOZMEDIAN'; end %'PERTRIALnonSOZMEDIAN'; %'PERTRIALnonSOZMEAN'; 

nPatients = numel(pNames);

regionNames = {'all', 'anterior', 'posterior', 'temporal', 'frontal','antCentral'};
dirResults = [dirGralResults, filesep, 'correlationsLog',filesep,anatRegionType];
dirImages = [dirResults,filesep,'images'];
titNameGRal = ['t0-600',posFixDir];%'LP45Hz';%LP_CCEP';

PCIFileName = [dirGralResults, filesep, 'PCIResults', filesep, 'PERTRIALnonSOZ',titNameGRal,filesep,'PCIStimCh',filesep,'PCIPerRegion_PCI StimCh',num2str(nPatients),'pat.mat'];

%respChFileName = [dirGralResults, filesep, 'ConnectivityResults', filesep, titNameGRal,filesep,'PERTRIALnonSOZ_Clean20',filesep,'nResp min5RespCh',anatRegionType,filesep,'nRespChPerRegion_',titNameGRal,'_nResp min5RespCh_',anatRegionType,num2str(nPatients),'pat.mat'];
dirRespChPooled = [dirGralResults,filesep,'ConnectivityResults',filesep,titNameGRal,filesep,whatToUseRespCh,filesep,'nResp',anatRegionType];
respChFileName = [dirRespChPooled,filesep,'nRespChPerRegion_','nResp_',anatRegionType,num2str(nPatients),'pat','.mat'];

%variabilityFileName = [dirGralResults, filesep, 'VariabilityRespAnyState_LP100Hz', filesep,'poolResp0_0.6ChEEG0MEAN2575RANGE',filesep,'2575RANGE',anatRegionType,filesep,'VariabilityPerRegion_VarEEG0MEAN 2575RANGE CCEP ',anatRegionType,'20pat.mat'];
variabilityFileName = [dirGralResults, filesep, 'VariabilityRespAnyState',posFixDir, filesep,'poolRespEEG0MEAN',whichVariability,varTimePeriod,filesep,whichVariability,anatRegionType,filesep,'VariabilityPerRegion_VarEEG0MEAN ',whichVariability,' ',varTimePeriod,' ',anatRegionType,num2str(nPatients),'pat.mat'];

if ~isdir(dirResults), mkdir(dirResults);end

diary([dirResults,filesep, 'CorrPCIRespVar',anatRegionType,'_',date,'.log'])

%% Run Correlations
for iRegion=1:length(regionNames)
    corrVariabilityDistanceToStim(variabilityFileName, [dirImages,'VarvsDistSTIM',filesep,regionNames{iRegion}], regionNames{iRegion}, anatRegionType);

    if strcmpi(anatRegionType,'StimCh') % only implemented for 'StimCh'
        quickCorrelationVariabilityPCIRespChanns(PCIFileName, respChFileName, variabilityFileName, [dirImages,filesep,'log',regionNames{iRegion}], regionNames{iRegion})
    end
end
diary off;

