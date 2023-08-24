function summaryOfAnesthesiaCCEPCentrality(dirPooledResults, pNames, posFixDir, whatToUseRespCh, anatRegionType, whichRecChannels)

%allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; 
%regionForPercWithin = {'anterior','posterior','temporal'}; % MUST be exclusive  

if ~exist('anatRegionType','var'), anatRegionType = 'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 
if ~exist('whichRecChannels','var'), whichRecChannels = 'RespCh'; end % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCh'=All recording channels
if ~exist('whatToUseRespCh','var'), whatToUseRespCh = 'PERTRIALnonSOZMEDIAN'; end %'PERTRIALnonSOZMEDIAN'; %'PERTRIALnonSOZMEAN'; 

%posFixDir = '_CCEPLOC'; 
titNameGRal = ['0-600',posFixDir];

%% Organize files
nPatients = numel(pNames);
%dirPooledResults = [dirGral, filesep, 'AnesthesiaAnalysis', filesep,num2str(nPatients),'pat_',strDate];

% Resp Channels
dirRespFeatChPooled = [dirPooledResults,filesep,'ConnectivityResults',filesep,'Centrality',titNameGRal,filesep,whatToUseRespCh,filesep,'Cent', whichRecChannels,anatRegionType];
respFeatChFileName = [dirRespFeatChPooled,filesep,'Centrality','PerRegion_','Cent',whichRecChannels,'_',anatRegionType,'_',num2str(nPatients),'p','.mat'];

% Output
fileNameSummary = [dirPooledResults,filesep,'summaryStimInfo_','Centr_',whatToUseRespCh,'_',whichRecChannels,'_',anatRegionType,'_',num2str(nPatients),'p_',date];

%% Responsive channels
% Stats relative resp channels Stim and Resp WITHIN region
stRespFeat = load(respFeatChFileName);
regionNames = stRespFeat.regionNames;
featureNames = stRespFeat.featureNames;

cfgStats = stRespFeat.cfgStats;
statsResults = stRespFeat.statsResults;

nRegions = length(regionNames);
nFeatures = length(featureNames);

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
% headers
nCols=9;
m4Save{1,1} = cfgStats.anatRegionFor;
m4Save{1,2} = cfgStats.titName;
m4Save{2,1} = respFeatChFileName;
iRow=size(m4Save,1);

for iFeat =1:nFeatures
    disp([featureNames{iFeat},' Relative Sleep/WakeEMU vs Anesthesia/WakeOR'])
    disp(['RelSleepAnesth', ' pairedpVal',' medianSleep/WakeEMU','q0.25','q0.75',' medianAnesthesia/WakeOR','q0.25','q0.75',' N'])
    m4Save{iRow+3,1} = [featureNames{iFeat},' Relative Sleep/WakeEMU vs Anesthesia/WakeOR'];
    m4Save(iRow+4,1:nCols) = {'RelSleepAnesth', 'pairedpVal','medianSleep/WakeEMU','q0.25','q0.75','medianAnesthesia/WakeOR','q0.25','q0.75','N'};
   for iRegion=1:nRegions
        if isfield(statsResults.RelFeatSleepAnesth,regionNames{iRegion})
            dataToSave = {regionNames{iRegion}, statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).pVal,...
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).medianRelSleepWakeEMU,...
                quantile(statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).relSleepWakeEMU,0.25),...
                quantile(statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).relSleepWakeEMU,0.75),...
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).medianRelAnesthWakeOR,...
                quantile(statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).relAnesthesiaWakeOR,0.25),...
                quantile(statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).relAnesthesiaWakeOR,0.75),...
                length(statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).commonCh)};
            disp(dataToSave)
            % m4Save
            m4Save(iRow +iRegion +4, 1:nCols) = dataToSave;
        end
    end
    iRow= size(m4Save,1);
end


%% Save Relative Summary Info
sheetName = ['Summary','RelRespFeatCh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);

clear m4Save;


%% UNPAIRED COMPARISONS - Features
regionNames = stRespFeat.regionNames;
cfgStats = stRespFeat.cfgStats;
statsResults = stRespFeat.statsResults;
nRegions = length(regionNames);
iRow= 0;
nCols=10;
m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = respFeatChFileName;
iRow=size(m4Save,1);

for iFeat =1:nFeatures
    m4Save{iRow+3,1} = [featureNames{iFeat}, ' Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'];
    m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal','medianSleep/WakeEMU','q0.25','q0.75','NEMU','medianAnesthesia/WakeOR','q0.25','q0.75','NOR'};
    iRow= size(m4Save,1);
    
    disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
    disp([featureNames{iFeat}, ' Relative Sleep/WakeEMU vs Anesthesia/WakeOR RelSleepAnesthNONPAIRED'])
    disp(['Region', ' unpairedpVal',' medianSleep/WakeEMU','q0.25','q0.75',' NEMU',' medianAnesthesia/WakeOR','q0.25','q0.75',' NOR'])
    for iRegion=1:nRegions
        if isfield(statsResults.RelFeatSleepAnesthNONPAIRED,regionNames{iRegion})
            dataToSave =  {regionNames{iRegion}, statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).pVal,...
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).medianRelSleepWakeEMU,...
                quantile(statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).relSleepWakeEMU,0.25),...
                quantile(statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).relSleepWakeEMU,0.75),...
                sum(~cellfun(@isempty,statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).chNamesEMU)),...
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).medianRelAnesthWakeOR,...
                quantile(statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).relAnesthesiaWakeOR,0.25),...
                quantile(statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).relAnesthesiaWakeOR,0.75),...
                sum(~cellfun(@isempty,statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).chNamesOR))};
            disp(dataToSave)
            % m4Save
            m4Save(iRow +iRegion, 1:nCols) = dataToSave;
        end
    end
    iRow=size(m4Save,1);
end

% Save UnPaired Comparisons Summary Info
sheetName = ['UnPairedRespFeatCh',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
clear m4Save;


%% Comparison between region - UNPAIRED

iRow= 0;
m4Save{iRow+1,1} = [cfgStats.anatRegionFor, ' ', cfgStats.titName];
m4Save{iRow+2,1} = respFeatChFileName;
iRow=size(m4Save,1);
nCols=8;
relCompStates = {'AnWa','SlWa','WaWa'};
regionNamesToCompare = stRespFeat.regionNamesToCompare;
regComp = [1 2; 1 3; 2 3];

disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])

for iFeat =1:nFeatures
    
    m4Save{iRow+2,1} = [featureNames{iFeat},' Comparison Regions Rel NONPAIRED'];
    m4Save(iRow+3,1:nCols) = {'State','Region1','Region2', 'unpairedpVal','medianRegion1','medianRegion2','NRegion1','NRegion2'};
    
    disp([featureNames{iFeat},' Comparison Regions Rel NONPAIRED'])
    disp(['Region', ' unpairedpVal',' medianRegion1',' medianRegion2',' NRegion1',' NRegion2'])
    iRow= size(m4Save,1);
    
    for iComp=1:length(relCompStates)
        relState = relCompStates{iComp};
        for iRegComp=1:length(regComp)
            dataToSave =  {relState,regionNamesToCompare{regComp(iRegComp,1)},regionNamesToCompare{regComp(iRegComp,2)},...
                statsResults.RelFeatRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(featureNames{iFeat}).pVal,...
                statsResults.RelFeatRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(featureNames{iFeat}).(['median',regionNamesToCompare{regComp(iRegComp,1)}]),...
                statsResults.RelFeatRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(featureNames{iFeat}).(['median',regionNamesToCompare{regComp(iRegComp,2)}]),...
                sum(~cellfun(@isempty,statsResults.RelFeatRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(featureNames{iFeat}).chNamesRegion1)),...
                sum(~cellfun(@isempty,statsResults.RelFeatRegionsNONPAIRED.(relState).([regionNamesToCompare{regComp(iRegComp,:)}]).(featureNames{iFeat}).chNamesRegion2))};
            disp(dataToSave)
            % m4Save
            m4Save(iRow +1, 1:nCols) = dataToSave;
            iRow =iRow +1;
        end
    end
end

% Save UnPaired between regions Comparisons Summary Info
sheetName = ['FeatBetweenRegions',cfgStats.anatRegionFor];
xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
clear m4Save;



%% WITHIN REGIONS - PAIRED Comparisons - one spreadsheet per feature
for iFeat =1:nFeatures
    iRow= 0;
    m4Save{iRow+1,1} = [featureNames{iFeat}, ' WithinRegion ', cfgStats.anatRegionFor, ' ', cfgStats.titName];
    m4Save{iRow+2,1} = respFeatChFileName;
    
    nCols=9;
    disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
    compNames = {'AnesthesiaWakeOR','SleepWakeEMU','WakeORWakeEMU'};
    %compNames = {'WakeORAnesthesia','WakeEMUSleep','WakeEMUWakeOR'};

    disp([featureNames{iFeat}, ' WithinRegion '])
    for iComp=1:length(compNames)
        disp([featureNames{iFeat}, ' ',compNames{iComp}])
        disp(['Region', ' pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'])
        iRow= size(m4Save,1);
        m4Save{iRow+3,1} = [featureNames{iFeat}, ' ',compNames{iComp}];
        m4Save(iRow+4,1:nCols) = {'Region', 'pairedpVal',' median1','q25' ,'q75' ,'median2','q25' ,'q75',' N'};
        iRow= size(m4Save,1);
       for iRegion=1:nRegions
            if isfield(statsResults.FeaturesRespPerRegion, regionNames{iRegion}) && isfield(statsResults.FeaturesRespPerRegion.(regionNames{iRegion}),compNames{iComp}) && isfield(statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}),featureNames{iFeat})
                dataToSave =  {regionNames{iRegion}, statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).pVal,...
                    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).median1,...
                    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).q025075Feat1(1),...
                    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).q025075Feat1(2),...
                    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).median2,...
                    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).q025075Feat2(1),...
                    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).q025075Feat2(2),...
                    sum(~cellfun(@isempty,statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).commonCh))};
                disp(dataToSave)
                % m4Save
                m4Save(iRow +iRegion, 1:nCols) = dataToSave;
            end
        end
        disp(' ')
    end
    
    % Save within region Summary Info - per feature
    sheetName = ['WithinPair_',featureNames{iFeat}(1:7),'_',cfgStats.anatRegionFor];
    xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
    
    clear m4Save;

end

%% WITHIN REGIONS - UNPAIRED Comparisons - one spreadsheet per feature
for iFeat =1:nFeatures
    iRow= 0;
    m4Save{iRow+1,1} = [featureNames{iFeat},' WithinRegion ', cfgStats.anatRegionFor, ' ', cfgStats.titName];
    m4Save{iRow+2,1} = respFeatChFileName;
    
    nCols=6;
    disp([cfgStats.anatRegionFor, ' ', cfgStats.titName])
    compNames = {'AnesthesiaWakeOR','SleepWakeEMU','WakeORWakeEMU'};

    disp([featureNames{iFeat}, ' WithinRegion '])
    for iComp=1:length(compNames)
        disp([featureNames{iFeat}, ' ',compNames{iComp}])
        disp({'Region', ' unpairedpVal',' median1','median2','N1' ,'N2'})
        iRow= size(m4Save,1);
        m4Save{iRow+3,1} = [featureNames{iFeat}, ' ',compNames{iComp}];
        m4Save(iRow+4,1:nCols) = {'Region', 'unpairedpVal',' median1','median2','N1' ,'N2'};
        iRow= size(m4Save,1);
       for iRegion=1:nRegions
            if isfield(statsResults.FeaturesRespPerRegionNONPAIRED, regionNames{iRegion}) && isfield(statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}),compNames{iComp}) && isfield(statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).(compNames{iComp}),featureNames{iFeat})
                dataToSave =  {regionNames{iRegion}, statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).pVal,...
                    statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).median1,...
                    statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).median2,...
                    statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).nVals1,...
                    statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).(compNames{iComp}).(featureNames{iFeat}).nVals2};
                disp(dataToSave)
                % m4Save
                m4Save(iRow +iRegion, 1:nCols) = dataToSave;
            end
        end
        disp(' ')
    end
    
    % Save within region Summary Info - per feature
    sheetName = ['WithNonPair_',featureNames{iFeat}(1:7),'_',cfgStats.anatRegionFor];
    xlswrite([fileNameSummary,'.xlsx'], m4Save, sheetName);
    
    clear m4Save;

end

