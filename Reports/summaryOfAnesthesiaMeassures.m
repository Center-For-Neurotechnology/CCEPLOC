function summaryOfAnesthesiaMeassures(dirPooledResults, pNames, posFixDir, whatToUseRespCh, anatRegionType)

%allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; 
%regionForPercWithin = {'anterior','posterior','temporal'}; % MUST be exclusive  - 'thalCaud','unknown'look for percentage of responsive within region (at the resolution indicated here)

if ~exist('anatRegionType','var'), anatRegionType = 'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 
if ~exist('whatToUseRespCh','var'), whatToUseRespCh = 'PERTRIALnonSOZMEDIAN'; end %'PERTRIALnonSOZMEDIAN'; %'PERTRIALnonSOZMEAN'; 

anatRegionTypePCI = 'StimCh'; %'StimCh' ONLY for PCI; %'nResp_StimCh';

%posFixDir = '_CCEPLOC'; 
titNameGRal = ['t0-600',posFixDir];
whatToUsePCI = 'PERTRIALnonSOZ'; 
varTimePeriod = 'CCEP'; %'Baseline';% 
whichVariability=  'STD';%'MAD'; %'2575RANGE'; 

%% Organize files
nPatients = numel(pNames);
%dirPooledResults = [dirGral, filesep, 'AnesthesiaAnalysis', filesep,num2str(nPatients),'pat_',strDate];

% Resp Channels
dirRespChPooled = [dirPooledResults,filesep,'ConnectivityResults',filesep,titNameGRal,filesep,whatToUseRespCh,filesep,'nResp',anatRegionType];
respChFileName = [dirRespChPooled,filesep,'nRespChPerRegion_','nResp_',anatRegionType,num2str(nPatients),'pat','.mat'];

% PCI
dirPCIPooled = [dirPooledResults,filesep,'PCIResults',filesep,whatToUsePCI,titNameGRal,filesep,'PCI',anatRegionTypePCI];
PCIFileName = [dirPCIPooled,filesep,'PCIPerRegion_','PCI ',anatRegionTypePCI,num2str(nPatients),'pat','.mat'];

% Variability
dirVariabilityPooled = [dirPooledResults,filesep,'VariabilityRespAnyState',posFixDir,filesep,'poolRespEEG0MEAN',whichVariability,varTimePeriod,filesep,whichVariability,anatRegionType];
variabilityFileName = [dirVariabilityPooled,filesep,'VariabilityPerRegion_VarEEG0MEAN ',whichVariability,' ',varTimePeriod,' ',anatRegionType,num2str(nPatients),'pat','.mat'];

% Output
fileNameSummary = [dirPooledResults,filesep,'summaryStimInfo_',whatToUseRespCh,'_',whichVariability,'_',anatRegionType,'_',num2str(nPatients),'pat_',date];

%% Responsive channels
% Stats relative resp channels Stim and Resp WITHIN region
stResp = load(respChFileName);
regionNames = stResp.regionNames;
cfgStats = stResp.cfgStats;
statsResults = stResp.statsResults;

nRegions = length(regionNames);
disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['#RespCh Relative Sleep/WakeEMU vs Anesthesia/WakeOR'])
% headers
nCols=9;
m4Save{1,1} = cfgStats.anatRegionFor;
m4Save{1,2} = cfgStats.titName;
m4Save{2,1} = respChFileName;
m4Save{3,1} = ['#RespCh Relative Sleep/WakeEMU vs Anesthesia/WakeOR'];
m4Save(4,1:nCols) = {'Region', 'pairedpVal','medianSleep/WakeEMU','25qSleep/WakeEMU','75qSleep/WakeEMU','medianAnesthesia/WakeOR','25qAnesthesia/WakeOR','75qAnesthesia/WakeOR','N'};
disp(m4Save(4,1:nCols)); %['Region ', 'pairedpVal',' median Sleep/WakeEMU',' 25q Sleep/WakeEMU',' 75q Sleep/WakeEMU','median Anesthesia/WakeOR','25q Anesthesia/WakeOR','75q Anesthesia/WakeOR','N'])
iRow=4;
for iRegion=1:nRegions
    if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
        dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.pVal,...
             statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.medianRelSleepWakeEMU,...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.relSleepWakeEMU,0.25),...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.relSleepWakeEMU,0.75),...
            statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.medianRelAnesthWakeOR,...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.relAnesthesiaWakeOR,0.25),...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).nResp.relAnesthesiaWakeOR,0.75),...
             length(statsResults.RelSleepAnesth.(regionNames{iRegion}).commonCh)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +iRegion, 1:nCols) = dataToSave;
    end
end

%% Stats PCI
stPCI = load(PCIFileName);
regionNames = stPCI.regionNames;
cfgStats = stPCI.cfgStats;
statsResults = stPCI.statsResults;
nRegions = length(regionNames);

iRow= size(m4Save,1);
m4Save{iRow+2,1} = PCIFileName;
m4Save{iRow+3,1} = ['PCI Relative Sleep/WakeEMU vs Anesthesia/WakeOR'];
m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal','medianSleep/WakeEMU','25qSleep/WakeEMU','75qSleep/WakeEMU','medianAnesthesia/WakeOR','25qAnesthesia/WakeOR','75qAnesthesia/WakeOR','N'};

disp(['PCI Relative Sleep/WakeEMU vs Anesthesia/WakeOR'])
disp(m4Save(iRow+4,1:nCols)); %['Region ', 'pairedpVal',' median Sleep/WakeEMU',' 25q Sleep/WakeEMU',' 75q Sleep/WakeEMU','median Anesthesia/WakeOR','25q Anesthesia/WakeOR','75q Anesthesia/WakeOR','N'])
iRow= size(m4Save,1);
for iRegion=1:nRegions
    if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
        dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesth.(regionNames{iRegion}).pVal,...
            statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelSleepWakeEMU,...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relSleepWakeEMU,0.25),...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relSleepWakeEMU,0.75),...
            statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelAnesthWakeOR,...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relAnesthesiaWakeOR,0.25),...
             quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relAnesthesiaWakeOR,0.75),...
            length(statsResults.RelSleepAnesth.(regionNames{iRegion}).commonCh)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +iRegion, 1:nCols) = dataToSave;
    end
end

%% Relative Variability
stVar = load(variabilityFileName);
cfgStats = stVar.cfgStats;
statsResults = stVar.statsResults;

iRow= size(m4Save,1);
m4Save{iRow+2,1} = variabilityFileName;
m4Save{iRow+3,1} = ['Variability Relative Sleep/WakeEMU vs Anesthesia/WakeOR'];
m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal','medianSleep/WakeEMU','25qSleep/WakeEMU','75qSleep/WakeEMU','medianAnesthesia/WakeOR','25qAnesthesia/WakeOR','75qAnesthesia/WakeOR','N'};

regionNames = cfgStats.regionsToCompare;
nRegions = length(regionNames);
disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['Variability Relative Sleep/WakeEMU vs Anesthesia/WakeOR'])
disp(m4Save(iRow+4,1:nCols));%['Region', ' pairedpVal',' medianSleep/WakeEMU',' medianAnesthesia/WakeOR',' N'])
iRow= size(m4Save,1);
for iRegion=1:nRegions
    if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
    dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesth.(regionNames{iRegion}).pVal,...
        statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelSleepWakeEMU,...
        quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relSleepWakeEMU,0.25),...
        quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relSleepWakeEMU,0.75),...
        statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelAnesthWakeOR,...
        quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relAnesthesiaWakeOR,0.25),...
        quantile(statsResults.RelSleepAnesth.(regionNames{iRegion}).relAnesthesiaWakeOR,0.75),...
        length(statsResults.RelSleepAnesth.(regionNames{iRegion}).commonCh)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +iRegion, 1:nCols) = dataToSave;
    end
end

%% Save Relative Summary Info
sheetName = ['Summary','RelRespCh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);

clear m4Save;

% %% Within region
% regionNames = stResp.regionNames;
% cfgStats = stResp.cfgStats;
% statsResults = stResp.statsResults;
% nRegions = length(regionNames);
% iRow= 0;
% nCols=6;
% m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
% m4Save{iRow+2,1} = respChFileName;
% m4Save{iRow+3,1} = ['#RespCh Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'];
% m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','medianAnesthesia/WakeOR','NEMU','NOR'};
% iRow= size(m4Save,1);
% 
% disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
% disp(['#RespCh Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'])
% disp(['Region', ' unpairedpVal',' medianSleep/WakeEMU',' medianAnesthesia/WakeOR',' NEMU',' NOR'])
% for iRegion=1:nRegions
%     if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
%         dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.pVal,...
%             statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.medianRelSleepWakeEMU,...
%             statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.medianRelAnesthWakeOR,...
%             length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.chNamesEMU),...
%             length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.chNamesOR)};
%         disp(dataToSave)
%         % m4Save
%         m4Save(iRow +iRegion, 1:nCols) = dataToSave;
%     end
% end

%% UNPAIRED COMPARISONS - nResp
regionNames = stResp.regionNames;
cfgStats = stResp.cfgStats;
statsResults = stResp.statsResults;
nRegions = length(regionNames);
iRow= 0;
nCols=10;
m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = respChFileName;
m4Save{iRow+3,1} = ['#RespCh Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'];
%m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','medianAnesthesia/WakeOR'};
m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal','medianSleep/WakeEMU','25qSleep/WakeEMU','75qSleep/WakeEMU','medianAnesthesia/WakeOR','25qAnesthesia/WakeOR','75qAnesthesia/WakeOR','NEMU','NOR'};

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['%RespCh Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'])
disp(m4Save(iRow+4,1:nCols)); %['Region', ' unpairedpVal',' medianSleep/WakeEMU',' medianAnesthesia/WakeOR',' NEMU',' NOR'])
iRow= size(m4Save,1);
for iRegion=1:nRegions
    if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
        dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.pVal,...
            statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.medianRelSleepWakeEMU,...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.relSleepWakeEMU,0.25),...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.relSleepWakeEMU,0.75),...
            statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.medianRelAnesthWakeOR,...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.relAnesthesiaWakeOR,0.25),...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.relAnesthesiaWakeOR,0.75),...
            length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.chNamesEMU),...
            length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).nResp.chNamesOR)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +iRegion, 1:nCols) = dataToSave;
    end
end

iRow= size(m4Save,1)+1;
nCols=8;

m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = ['#RespCh Comparison Regions Rel NONPAIRED'];
m4Save(iRow+3,1:nCols) = {'State','Region1','Region2', 'unpairedpVal','medianRegion1','medianRegion2','NRegion1','NRegion2'};
%RIZ: Did not added 25-75 for anat comparison - could do it:  m4Save(iRow+3,1:nCols) = {'State','Region1','Region2', 'unpairedpVal','medianRegion1','q25Region1','q75Region1','medianRegion2','q25Region2','q75Region2','NRegion1','NRegion2'};

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['#RespCh Comparison Regions Rel NONPAIRED'])
disp(['Region', ' unpairedpVal',' medianRegion1',' medianRegion2',' NRegion1',' NRegion2'])
relCompStates = {'AnWa','SlWa','WaWa'}; %relCompStates = {'Anes','Slee','Wake'};
regionNamesToCompare = stResp.regionNamesToCompare;
regComp = [1 2; 1 3; 2 3];
iRow= size(m4Save,1);

for iComp=1:length(relCompStates)
    relState = relCompStates{iComp};
    for iRegComp=1:length(regComp)
        dataToSave =  {relState,regionNamesToCompare{regComp(iRegComp,1)},regionNamesToCompare{regComp(iRegComp,2)},...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).nResp.pVal,...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).nResp.(['median',regionNamesToCompare{regComp(iRegComp,1)}]),...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).nResp.(['median',regionNamesToCompare{regComp(iRegComp,2)}]),...
            length(statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).nResp.chNamesRegion1),...
            length(statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).nResp.chNamesRegion2)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +1, 1:nCols) = dataToSave;
        iRow =iRow +1;
    end
end

% Save UnPaired Comparisons Summary Info
sheetName = ['UnPairedRespCh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
clear m4Save;


%% UNPAIRED COMPARISONS - PCI
regionNames = stPCI.regionNames;
cfgStats = stPCI.cfgStats;
statsResults = stPCI.statsResults;
nRegions = length(regionNames);
iRow= 0;
nCols=10;
m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = respChFileName;
m4Save{iRow+3,1} = ['PCI Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'];
%m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','medianAnesthesia/WakeOR','NEMU','NOR'};
m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','25qSleep/WakeEMU','75qSleep/WakeEMU','medianAnesthesia/WakeOR','25qAnesthesia/WakeOR','75qAnesthesia/WakeOR','NEMU','NOR'};

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['PCI Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'])
disp(m4Save(iRow+4,1:nCols)); %['Region', ' unpairedpVal',' medianSleep/WakeEMU',' medianAnesthesia/WakeOR',' NEMU',' NOR'])

iRow= size(m4Save,1);
for iRegion=1:nRegions
    if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
        dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).pVal,...
            statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelSleepWakeEMU,...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU,0.25),...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU,0.75),...
            statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelAnesthWakeOR,...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR,0.25),...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR,0.75),...
            length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).chNamesEMU),...
            length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).chNamesOR)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +iRegion, 1:nCols) = dataToSave;
    end
end

iRow= size(m4Save,1)+1;
nCols=8;

m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = ['PCI Comparison Regions Rel  NONPAIRED'];
m4Save(iRow+3,1:nCols) = {'State','Region1','Region2', 'unpairedpVal','medianRegion1','medianRegion2','NRegion1','NRegion2'};

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['PCI Comparison Regions Rel  NONPAIRED'])
disp(['Region', ' unpairedpVal',' medianRegion1',' medianRegion2',' NRegion1',' NRegion2'])
relCompStates = {'Anes','Slee','Wake'};
regionNamesToCompare = stResp.regionNamesToCompare;
regComp = [1 2; 1 3; 2 3];
iRow= size(m4Save,1);

for iComp=1:length(relCompStates)
    relState = relCompStates{iComp};
    for iRegComp=1:length(regComp)
        dataToSave =  {relState,regionNamesToCompare{regComp(iRegComp,1)},regionNamesToCompare{regComp(iRegComp,2)},...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).pVal,...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(['median',regionNamesToCompare{regComp(iRegComp,1)}]),...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(['median',regionNamesToCompare{regComp(iRegComp,2)}]),...
            length(statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).chNamesRegion1),...
            length(statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).chNamesRegion2)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +1, 1:nCols) = dataToSave;
        iRow =iRow +1;
    end
end

% Save UnPaired Comparisons Summary Info
sheetName = ['UnPairedPCICh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
clear m4Save;

%% UNPAIRED COMPARISONS - Variability
regionNames = stVar.regionNames;
cfgStats = stVar.cfgStats;
statsResults = stVar.statsResults;
nRegions = length(regionNames);
iRow= 0;
nCols=10;
m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = respChFileName;
m4Save{iRow+3,1} = ['Variability Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'];
%m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','medianAnesthesia/WakeOR','NEMU','NOR'};
m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','25qSleep/WakeEMU','75qSleep/WakeEMU','medianAnesthesia/WakeOR','25qAnesthesia/WakeOR','75qAnesthesia/WakeOR','NEMU','NOR'};

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['Variability Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'])
disp(m4Save(iRow+4,1:nCols)); %['Region', ' unpairedpVal',' medianSleep/WakeEMU',' medianAnesthesia/WakeOR',' NEMU',' NOR'])

iRow= size(m4Save,1);
for iRegion=1:nRegions
    if isfield(statsResults.RelSleepAnesth,regionNames{iRegion})
        dataToSave =  {regionNames{iRegion}, statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).pVal,...
            statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelSleepWakeEMU,...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU,0.25),...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU,0.75),...
            length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU),...
            statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelAnesthWakeOR,...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR,0.25),...
            quantile(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR,0.75),...
            length(statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +iRegion, 1:nCols) = dataToSave;
    end
end

iRow= size(m4Save,1)+1;
nCols=8;

m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = ['Variability Comparison Regions Rel NONPAIRED'];
m4Save(iRow+3,1:nCols) = {'State','Region1','Region2', 'unpairedpVal','medianRegion1','medianRegion2','NRegion1','NRegion2'};

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
disp(['Variability Comparison Regions Rel NONPAIRED'])
disp(['Region', ' unpairedpVal',' medianRegion1',' medianRegion2',' NRegion1',' NRegion2'])
relCompStates = {'Anes','Slee','Wake'};
regionNamesToCompare = stResp.regionNamesToCompare;
regComp = [1 2; 1 3; 2 3];
iRow= size(m4Save,1);

for iComp=1:length(relCompStates)
    relState = relCompStates{iComp};
    for iRegComp=1:length(regComp)
        dataToSave =  {relState,regionNamesToCompare{regComp(iRegComp,1)},regionNamesToCompare{regComp(iRegComp,2)},...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).pVal,...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(['median',regionNamesToCompare{regComp(iRegComp,1)}]),...
            statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(['median',regionNamesToCompare{regComp(iRegComp,2)}]),...
            length(statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).relativeRespRegion1),...
            length(statsResults.RelRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).relativeRespRegion2)};
        disp(dataToSave)
        % m4Save
        m4Save(iRow +1, 1:nCols) = dataToSave;
        iRow =iRow +1;
    end
end

% Save UnPaired Comparisons Summary Info
sheetName = ['UnPairedVarCh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
clear m4Save;

%% WITHIN REGIONS
regionNames = stResp.regionNames;
cfgStats = stResp.cfgStats;
statsResults = stResp.statsResults;
nRegions = length(regionNames);
iRow= 0;
m4Save{iRow+1,1} = ['RespCh WithinRegion ', cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = respChFileName;

nCols=9;
disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
compNames = {'AnesthesiaWakeOR','SleepWakeEMU','WakeORWakeEMU'};
testNames = {'nResp','perResp','perTOTAL','perWITHIN'};
for iTest=1:length(testNames)
    disp(['nResp WithinRegion '])
    for iComp=1:length(compNames)
        disp([testNames{iTest}, ' ',compNames{iComp}])
        disp({'Region', ' pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'})
        iRow= size(m4Save,1);
        m4Save{iRow+3,1} = [testNames{iTest}, ' ',compNames{iComp}];
        m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'};
        iRow= size(m4Save,1);
       for iRegion=1:nRegions
            if isfield(statsResults.WithStimChInRegion, regionNames{iRegion}) && isfield(statsResults.WithStimChInRegion.(regionNames{iRegion}),compNames{iComp}) && isfield(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}),testNames{iTest})
                dataToSave =  {regionNames{iRegion}, statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).pVal,...
                    statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).median1,...
                    quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).values1,0.25),...
                    quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).values1,0.75),...
                    statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).median2,...
                    quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).values2,0.25),...
                    quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).values2,0.75),...
                    length(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).(testNames{iTest}).commonCh)};
                disp(dataToSave)
                % m4Save
                m4Save(iRow +iRegion, 1:nCols) = dataToSave;
            end
        end
        disp(' ')
    end
    disp(' ')
end
%% Save within region Summary Info
sheetName = ['WithinRespCh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);

clear m4Save;

%% PCI within region
regionNames = stPCI.regionNames;
cfgStats = stPCI.cfgStats;
statsResults = stPCI.statsResults;
nRegions = length(regionNames);
iRow= 0;
nCols=9;
m4Save{iRow+1,1} = ['PCI WithinRegion ', cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = PCIFileName;
compNames = {'AnesthesiaWakeOR','SleepWakeEMU','WakeORWakeEMU'};
disp(['PCI WithinRegion '])
for iComp=1:length(compNames)
    disp(['PCI ',compNames{iComp}])
    disp({'Region', ' pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'})
    iRow= size(m4Save,1);
    m4Save{iRow+3,1} = ['PCI', ' ',compNames{iComp}];
    m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'};
    iRow= size(m4Save,1);
    for iRegion=1:nRegions
        if isfield(statsResults.WithStimChInRegion, regionNames{iRegion}) && isfield(statsResults.WithStimChInRegion.(regionNames{iRegion}),compNames{iComp})
            dataToSave =  {regionNames{iRegion}, statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).pVal,...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).median1,...
            quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).values1,0.25),...
            quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).values1,0.75),...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).median2,...
            quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).values2,0.25),...
            quantile(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).values2,0.75),...
                length(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).commonCh)};
            disp(dataToSave)
            % m4Save
            m4Save(iRow +iRegion, 1:nCols) = dataToSave;
        end
    end
    disp(' ')
end
%% Save within region Summary Info
sheetName = ['WithinPCI',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);

clear m4Save;


%% Stats Variability
regionNames = stVar.regionNames;
cfgStats = stVar.cfgStats;
statsResults = stVar.statsResults;
nRegions = length(regionNames);
iRow= 0;
nCols=9;
m4Save{iRow+1,1} = ['Variability WithinRegion ', cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = PCIFileName;


compNames = {'AnesthesiaWakeOR','SleepWakeEMU','WakeORWakeEMU'};
disp(['Variability WithinRegion '])
for iComp=1:length(compNames)
    iRow= size(m4Save,1);
    m4Save{iRow+3,1} = ['Variability', ' ',compNames{iComp}];
    m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'};
    iRow= size(m4Save,1);
    disp(['Variability ',compNames{iComp}])
    disp({'Region', ' pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'})
    for iRegion=1:nRegions
        if isfield(statsResults.WithStimChInRegion, regionNames{iRegion}) && isfield(statsResults.WithStimChInRegion.(regionNames{iRegion}),compNames{iComp})
            dataToSave =  {regionNames{iRegion}, statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).pVal,...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).median1,...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).q025075Feat1(1),...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).q025075Feat1(2),...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).median2,...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).q025075Feat2(1),...
                statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).q025075Feat2(2),...
                length(statsResults.WithStimChInRegion.(regionNames{iRegion}).(compNames{iComp}).commonCh)};
            disp(dataToSave)
            % m4Save
            m4Save(iRow +iRegion, 1:nCols) = dataToSave;
        end
    end
    disp(' ')
end

%% Save within region Summary Info
sheetName = ['WithinVar',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);

clear m4Save;


