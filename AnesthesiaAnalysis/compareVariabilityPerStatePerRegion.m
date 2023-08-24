function compareVariabilityPerStatePerRegion(pooledVariabilityFileName, dirResults, cfgStats)


if ~isfield(cfgStats,'allStatesTitName'), cfgStats.allStatesTitName= cfgStats.allStates; end  % allStatesTitName is used to remove from titName (in order to match channels)
if ~isfield(cfgStats,'anatRegionFor'), cfgStats.anatRegionFor= 'stimCh'; end  % options: 'stimCh or respCh'

regionNames = cfgStats.regionsToCompare;
whatIntervalToUse = cfgStats.whatIntervalToUse;

% Start Diary
if ~exist(dirResults,'dir'),mkdir(dirResults); end
diary([dirResults,filesep,'log','CompareVarPerRegion',cfgStats.anatRegionFor,'.log'])


%% Load Variability Pooled file
stVariability = load(pooledVariabilityFileName);
nStates = length(stVariability.stateNames);

%% Get Variability and anatomical region for each patient and state
variabilityPerState=cell(1,nStates);
normVariabilityPerState=cell(1,nStates);
nTrialPerChPerState=cell(1,nStates);
stimSitesPerState=cell(1,nStates);
chNamesPNamesPerState=cell(1,nStates);
anatRegionsPerChPerState=cell(1,nStates);
anatRegionsStimChPerState=cell(1,nStates);
RASCoordPerChPerState=cell(1,nStates);
RASCoordStimChPerState=cell(1,nStates);
gralRegionsPerChPerState=cell(1,nStates);
gralRegionsStimChPerState=cell(1,nStates);
rechInStimShaftPerState=cell(1,nStates);

for iState=1:nStates
    thisState = stVariability.stateNames{iState};
    variabilityVals = stVariability.(strcat('meanStatsEEG',thisState)).VariabilityPerCh.(whatIntervalToUse);
    normVariabilityVals = stVariability.(strcat('meanStatsEEG',thisState)).normVariabilityPerCh.(whatIntervalToUse);
    nTrialPerCh = stVariability.(strcat('meanStatsEEG',thisState)).nTrialPerCh;
    variabilityPerState{iState} =   variabilityVals;
    normVariabilityPerState{iState} =   normVariabilityVals;
    nTrialPerChPerState{iState} =   nTrialPerCh;
    stimSitesPerState{iState} = stVariability.stimPatChNames.(thisState);
    chNamesPNamesPerState{iState} = stVariability.bipChNames.(thisState);
    anatRegionsPerChPerState{iState} = stVariability.bipChAnatRegion.(thisState);
    anatRegionsStimChPerState{iState} = stVariability.stimChAnatRegion.(thisState);
    RASCoordPerChPerState{iState} = stVariability.bipChRASCoord.(thisState);
    RASCoordStimChPerState{iState} = stVariability.stimChRASCoord.(thisState);
    rechInStimShaftPerState{iState} = stVariability.rechInStimShaft.(thisState);
    [gralRegionPerCh, gralRegionsPerChPerState{iState}] = getGralRegionPerChannel(anatRegionsPerChPerState{iState});
    [gralRegionPerCh, gralRegionsStimChPerState{iState}] = getGralRegionPerChannel(anatRegionsStimChPerState{iState});
end

%% Find which channels are in the regions we want to compare
variabilityPerStatePerRegion = cell(nStates,length(regionNames));
logVariabilityPerStatePerRegion = cell(nStates,length(regionNames));
normVariabilityPerStatePerRegion = cell(nStates,length(regionNames));
nTrialPerChPerStatePerRegion = cell(nStates,length(regionNames));
stimSitesPerStatePerRegion = cell(nStates,length(regionNames));
nPairsPerStatePerRegion = zeros(nStates,length(regionNames));
chNamesPNamesPerStatePerRegion = cell(nStates,length(regionNames));
for iState=1:nStates
    [indChWithinStimRegion, variabilityWithinStimRegion, stimChNamesPerRegion] = findChannelsWithinRegion(gralRegionsStimChPerState{iState}, regionNames, variabilityPerState{iState}, stimSitesPerState{iState});
    % find also location of recording channels
    [indRecChWithinRegions] = findChannelsWithinRegion(gralRegionsPerChPerState{iState}, regionNames);
    for iRegion=1:length(regionNames)
        % Asign based on cfgStats.anatRegionFor
        if strcmpi(cfgStats.anatRegionFor,'stimCh')
            indCh = indChWithinStimRegion{iRegion};
        elseif strcmpi(cfgStats.anatRegionFor,'onlyRespCh')
            indCh = indRecChWithinRegions{iRegion};
        elseif strcmpi(cfgStats.anatRegionFor,'stimRespCh') %  both stim and rec Ch (within the same region)
            indCh = intersect(indChWithinStimRegion{iRegion}, indRecChWithinRegions{iRegion});
        else % same as all region
            indCh = 1:length(variabilityPerState{iState});
        end
        % Assign depending on what we want to analyse - log is now done
        % directly on full variability measure - before mean across timepoints
        logVariabilityPerStatePerRegion{iState,iRegion} = log10(variabilityPerState{iState}(indCh)); % USE log10 to make it more normal!!!
        variabilityPerStatePerRegion{iState,iRegion} = variabilityPerState{iState}(indCh);% keep also variability values
        normVariabilityPerStatePerRegion{iState,iRegion} = normVariabilityPerState{iState}(indCh);% keep also variability values
        nTrialPerChPerStatePerRegion{iState,iRegion} = nTrialPerChPerState{iState}(indCh);% keep also variability values
        stimSitesPerStatePerRegion{iState,iRegion} = stimSitesPerState{iState}(indCh); % only stim channels in this region
        nPairsPerStatePerRegion(iState,iRegion) = length(indCh);%sum(~isnan(variabilityWithinStimRegion{1}));
        chNamesPNamesPerStatePerRegion{iState,iRegion} = chNamesPNamesPerState{iState}(indCh);
    end
    
end


%% PLot within stim region
% Plot only those with corresponding stim channels
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
for iRegion=1:length(regionNames)
    dirImages = [dirResults,filesep,'images'];
    cfgStats.dirImages = dirImages;
    cfgStats.bipolarChannels = chNamesPNamesPerStatePerRegion(:,iRegion); %chNamesPNamesPerState;
    cfgStats.legLabel = cfgStats.allStates;
    cfgStats.ylabel = ['Variability ', regionNames{iRegion}] ;
    titName = [cfgStats.titName, ' ', regionNames{iRegion}] ;
    plotWakeVsAnesthesiaPerCh([], variabilityPerStatePerRegion(:,iRegion), titName, cfgStats, pairComps);
    
end

%% ANOVA
for iRegion=1:length(regionNames)
    allChData = [variabilityPerStatePerRegion(:,iRegion)];
    if ~any(cellfun(@isempty,allChData))
        cfgStats.bipolarChannels = chNamesPNamesPerStatePerRegion(:,iRegion); %chNamesPNamesPerState; %stimSitesPerStatePerRegion(:,iRegion);
        %   titNamePerRegion = ['log ',cfgStats.titName, ' ', regionNames{iRegion}] ;
        [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
        xlsFileName = [filepath,filesep,name,'_',regionNames{iRegion},ext] ;
        titName = ['ANOVA ', cfgStats.whatIntervalToUse, ' ',regionNames{iRegion}];
        
        % Bar Plot
        % Bar Plot for Log10 data
        cfgStats.ylim = [1 2];
        plotErrorBars([], allChData, [titName], cfgStats);
        cfgStats.ylim = 'auto';
        
        % ANOVA
        allChDataForANOVA = [allChData{:}];
        groupLabels=[];
        for iComp=1:length(allChData)
            groupLabels = [groupLabels, repmat(cfgStats.legLabel(iComp),1,length(allChData{iComp}))];
        end
        stimSiteAll = [stimSitesPerStatePerRegion{:,iRegion}];
        nTrialsAll = [nTrialPerChPerStatePerRegion{:,iRegion}];
        [pNameAll] = regexprep(stimSiteAll,'\S*\_','');

        cfgStats.sheetName =['ANOVA', cfgStats.whatIntervalToUse, regionNames{iRegion}];
        [pValsANOVA] = computeANOVASaveInXls(allChDataForANOVA, groupLabels, titName, cfgStats.xlsFileName, cfgStats.sheetName, cfgStats.dirImages);
       
%         % N-way ANOVA - use patient, SNR and #trials as groups
% %          cfgStats.sheetName =['NANOVA', cfgStats.whatIntervalToUse, regionNames{iRegion}];
% %          [pValsANOVAN] = computeANOVANSaveInXls(allChDataForANOVA, {groupLabels,pNameAll,nTrialsAll},{'BrainState','pName','nTrials'}, titName, cfgStats.xlsFileName, cfgStats.sheetName, cfgStats.dirImages);
    end       
end

%% Stats within Stim region
relativeVariability = cell(size(pairComps,1),length(regionNames));
commonChPerCompRegion = cell(size(pairComps,1),length(regionNames));
for iRegion=1:length(regionNames)
    cfgStats.bipolarChannels = chNamesPNamesPerStatePerRegion(:,iRegion); %chNamesPNamesPerState; %stimSitesPerStatePerRegion(:,iRegion);
    titNamePerRegion = [cfgStats.titName, ' ', regionNames{iRegion}] ;
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileName = [filepath,filesep,name,'_',regionNames{iRegion},'.',ext] ;

    for iComp=1:size(pairComps,1)
        titName = [titNamePerRegion,' ',num2str([pairComps(iComp,:)])];
        [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
        legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(indIn1)),')']);
        % Variability per region
        cfgStats.sheetName =['Var', regionNames{iRegion}];
        varibilityThisRegionComp1 = variabilityPerStatePerRegion{pairComps(iComp,1),iRegion}(indIn1); % use var value for relative measures 
        varibilityThisRegionComp2 = variabilityPerStatePerRegion{pairComps(iComp,2),iRegion}(indIn2);
        logVaribilityThisRegionComp1 = logVariabilityPerStatePerRegion{pairComps(iComp,1),iRegion}(indIn1); % use LOG10 for the stats
        logVaribilityThisRegionComp2 = logVariabilityPerStatePerRegion{pairComps(iComp,2),iRegion}(indIn2);
        if ~isempty(commonCh) && ~isempty(varibilityThisRegionComp1) && ~isempty(varibilityThisRegionComp2)
            [pairedTtest, medianVal1, medianVal2, testName] = computePairedTtestSaveInXls(logVaribilityThisRegionComp1, logVaribilityThisRegionComp2, titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
            disp([testName, ': ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N= ',num2str(length(commonCh))])
            
            % compute relative values as Val1-Val2 / Val1+Val2 to use in next comparison
            relativeVariability{iComp,iRegion} = (varibilityThisRegionComp1 - varibilityThisRegionComp2) ./(varibilityThisRegionComp1 + varibilityThisRegionComp2);
           
            commonChPerCompRegion{iComp,iRegion} = commonCh;%(indInCommonRegion1);
            
            %save stats
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).pVal = pairedTtest;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).median1 = medianVal1; % corresponds to pairComps(iComp,1)
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).median2 = medianVal2; % corresponds to pairComps(iComp,2)
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).q025075Feat1 = [quantile(logVaribilityThisRegionComp1, 0.25) quantile(logVaribilityThisRegionComp1, 0.75)];
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).q025075Feat2 = [quantile(logVaribilityThisRegionComp1, 0.25) quantile(logVaribilityThisRegionComp2, 0.75)];
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).relativeVar = relativeVariability{iComp,iRegion};
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).commonCh =commonCh;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nCommonPairs =length(logVaribilityThisRegionComp1);
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).pairComp =pairComps(iComp,:);
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nPairs = nPairsPerStatePerRegion(pairComps(iComp,:),iRegion);
        end
    end
end

%% Relative comparison: Anesthesia-WakeOR vs Sleep-WakeEMU
indCompSleepWakeEMU =2;
indCompAnesthesiaWakeOR =3;
legComp = {[cfgStats.legLabel{pairComps(indCompSleepWakeEMU,:)}],[cfgStats.legLabel{pairComps(indCompAnesthesiaWakeOR,:)}]};

for iRegion=1:length(regionNames)
    figure; hold on;
    for iComp=1:size(pairComps,1)
        subplot(1,2*size(pairComps,1),iComp*2-1)
        plot(relativeVariability{iComp,iRegion},'.','MarkerSize',20);
        line([1 length(relativeVariability{iComp,iRegion})],[0 0],'Color', 'k','LineWidth',3)
        line([1 length(relativeVariability{iComp,iRegion})],[median(relativeVariability{iComp,iRegion}) median(relativeVariability{iComp,iRegion})],'Color', 'r','LineWidth',3)
        ylim([-1 1])
        xlim([0 length(relativeVariability{iComp,iRegion})+1])
        grid on;
        legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(relativeVariability{iComp,iRegion})),')']);
        xticklabels({})

        title([legLabel{:}]);
        % boxplot of same data
        subplot(1,2*size(pairComps,1),iComp*2)
        boxplot(relativeVariability{iComp,iRegion})
        ylim([-1 1])
        yticklabels({})
        xticklabels([regionNames{iRegion}, ' ', num2str([pairComps(iComp,:)])])
    end
    suptitle(['Rel Variability ', regionNames{iRegion}])
    %Save figure
    titNameForFile = ['Rel_',regexprep([cfgStats.titName, regionNames{iRegion}],'\W','_')];
    saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.png']);
    saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.svg']);
    savefig(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.fig'],'compact');

    % compare Anesthesia-WakeOR vs Sleep-WakeEMU ONLY for those with all states
    [indIn1, indIn2, commonCh] = strmatchAll(commonChPerCompRegion{indCompSleepWakeEMU,iRegion}, commonChPerCompRegion{indCompAnesthesiaWakeOR,iRegion});
    relVarSleep = relativeVariability{indCompSleepWakeEMU,iRegion};
    relVarAnesthesia = relativeVariability{indCompAnesthesiaWakeOR,iRegion};

    if ~isempty(commonCh) && ~all(isnan(relVarSleep(indIn1)))&& ~all(isnan(relVarAnesthesia(indIn2)))
        legLabel= strcat('Rel',legComp,[' (', num2str(length(indIn1)),')']);
        cfgStats.sheetName =['RelVar', regionNames{iRegion}];
        [pairedTtest, medianVal1, medianVal2, testName] = computePairedTtestSaveInXls(relVarSleep(indIn1),relVarAnesthesia(indIn2),titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
        disp([testName, ': ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N= ',num2str(min(nPairsPerStatePerRegion(pairComps(iComp,:),iRegion)))])
        statsResults.RelSleepAnesth.(regionNames{iRegion}).pVal = pairedTtest;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelSleepWakeEMU = medianVal1;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelAnesthWakeOR = medianVal2;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).commonCh =commonCh;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).nPairs =nPairsPerStatePerRegion(pairComps(iComp,:),iRegion);
        statsResults.RelSleepAnesth.(regionNames{iRegion}).relSleepWakeEMU = relVarSleep(indIn1);
        statsResults.RelSleepAnesth.(regionNames{iRegion}).relAnesthesiaWakeOR = relVarAnesthesia(indIn2);

        % Variability  NON-PAIR stats
        legLabel= strcat('RelNONPAIR',legComp,' (', {num2str(length(relVarSleep)),num2str(length(relVarAnesthesia))},')');
        cfgStats.sheetName = ['RelVarNONPAIR',regionNames{iRegion}(1:min(5,end)),'SleepAnes'];
        titName = ['RelNONPAIR ',cfgStats.titName,' ',' Sl-An'];
        [nonpairedTtest, medianVal1, medianVal2] = computeRankSumSaveInXls(relVarSleep, relVarAnesthesia,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],[cfgStats.dirImages,filesep,'RelativeNonPairedStats'],cfgStats.useParam);
        disp(['RankSUM: ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relVarSleep)),' N2= ',num2str(length(relVarAnesthesia))])
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).pVal = nonpairedTtest;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelSleepWakeEMU = medianVal1;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelAnesthWakeOR = medianVal2;
%        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).chNamesEMU =stimChPerCompRegion{indCompSleepWakeEMU,iRegion};
%        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).chNamesOR =stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion};
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU = relVarSleep;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR = relVarAnesthesia;
    end
end

%% Compare specific regions within same state
regionNamesToCompare= {'frontal', 'posterior','temporal'}; % frontal=PFC and OF / anterior
%regionNamesToCompare= {'anterior', 'posterior','temporal'}; % frontal=PFC and OF / anterior includes ACC
indRegionToCompare= strmatchAll(regionNames,regionNamesToCompare);
pairRegionsComp = [indRegionToCompare(1),indRegionToCompare(2);...
                   indRegionToCompare(1),indRegionToCompare(3);...
                   indRegionToCompare(2),indRegionToCompare(3)];
               
for iRelState=1:size(pairComps,1)
    thisRelState = [cfgStats.legLabel{pairComps(iRelState,1)}(1:4)];
    for iCompRegion=1:size(pairRegionsComp,1)
        thisRegionsToCompare = [regionNames{pairRegionsComp(iCompRegion,:)}];
        relativeVarRegion1 = relativeVariability{iRelState, pairRegionsComp(iCompRegion,1)};
        relativeVarRegion2 = relativeVariability{iRelState, pairRegionsComp(iCompRegion,2)};
        
        if ~isempty(relativeVarRegion1) && ~isempty(relativeVarRegion2)
            % # Responsive channels NON-PAIR stats
            legLabel= strcat('Rel ',regionNames(pairRegionsComp(iCompRegion,:)),' (', {num2str(length(relativeVarRegion1)),num2str(length(relativeVarRegion2))},')');
            cfgStats.sheetName = ['RelVar',thisRelState,thisRegionsToCompare];
            titName = ['RelVar',cfgStats.titName, ' ',thisRelState,' ',thisRegionsToCompare];
            [nonpairedTtest, medianVal1, medianVal2] = computeRankSumSaveInXls(relativeVarRegion1,relativeVarRegion2,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairRegionsComp(iCompRegion,:)])],[cfgStats.dirImages,filesep,'RelCompRegions'],cfgStats.useParam);
            disp(['RankSUM: ', cfgStats.sheetName,' between ',thisRegionsToCompare, ' ', cfgStats.anatRegionFor,' ', thisRelState,' ',' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relativeVarRegion1)),' N2= ',num2str(length(relativeVarRegion2))])
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).pVal = nonpairedTtest;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(['median',regionNames{pairRegionsComp(iCompRegion,1)}]) = medianVal1;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(['median',regionNames{pairRegionsComp(iCompRegion,2)}]) = medianVal2;
  %          statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).chNamesRegion1 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,1)};
  %          statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).chNamesRegion2 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,2)};
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).relativeRespRegion1 = relativeVarRegion1;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).relativeRespRegion2 = relativeVarRegion2;
        end
    end
end

%% Save info in MAT file
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    matFileNameResults = [filepath,filesep,'VariabilityPerRegion_',name,'.mat'] ;

save([matFileNameResults], 'regionNames', 'stimSitesPerStatePerRegion', 'cfgStats','pooledVariabilityFileName',...
    'variabilityPerStatePerRegion','logVariabilityPerStatePerRegion','normVariabilityPerStatePerRegion', 'nTrialPerChPerStatePerRegion', ...
    'relativeVariability', 'pairComps', 'statsResults', ...
    'anatRegionsStimChPerState', 'anatRegionsPerChPerState', 'gralRegionsStimChPerState', 'gralRegionsPerChPerState','RASCoordPerChPerState','RASCoordStimChPerState','rechInStimShaftPerState',...
    'stimSitesPerState','nPairsPerStatePerRegion','chNamesPNamesPerState','chNamesPNamesPerStatePerRegion',...
    'commonChPerCompRegion','indCompSleepWakeEMU','indCompAnesthesiaWakeOR');


diary off;
