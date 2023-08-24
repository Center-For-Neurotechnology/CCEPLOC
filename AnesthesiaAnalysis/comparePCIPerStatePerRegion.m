function comparePCIPerStatePerRegion(fileNamePCIAllStates, dirResults, cfgStats)

nPatients = size(fileNamePCIAllStates,1);
nStates = size(fileNamePCIAllStates,2);

if ~isfield(cfgStats,'allStatesTitName'), cfgStats.allStatesTitName= cfgStats.allStates; end  % allStatesTitName is used to remove from titName (in order to match channels)
if ~isfield(cfgStats,'anatRegionFor'), cfgStats.anatRegionFor= 'stimCh'; end  % options: 'stimCh or respCh'

regionNames = cfgStats.regionsToCompare;

% Start Diary
if ~exist(dirResults,'dir'),mkdir(dirResults); end
diary([dirResults,filesep,'log','ComparePCIPerRegion',cfgStats.anatRegionFor,'.log'])

% %% Get nRespChannels for all states and stim channels
% [nRespPerState, perRespChPerState, stimSitesPerState, pNamesPerState, meanNRespPerState, nRespPerStatePerPat, stimSitesPerStatePerPat] = getNRespChannels(fileNameRespChAllPatAllStates);


%% Get anatomical information nRespChannels for all states and stim channels - ONLY for those with some response
[anatRegionsStimChPerState, anatRegionsPerChPerState, gralRegionsStimChPerState, gralRegionsPerChPerState, chNamesPerState, stimSitesPerState, pNamesPerState, anatLabels] =...
    getRegionStimChannels(fileNamePCIAllStates, cfgStats.stimChPerPat);

%% Get PCI and anatomical region for each patient and state
PCIPerState=cell(1,nStates);
stimSitesPNamesPerState=cell(1,nStates);
maxPCIperPat = cell(1,nStates);
pNamesMaxPCI = cell(1,nStates);
%gralRegionsStimChPerState=cell(1,nStates);
for iState=1:nStates
    for iP=1:nPatients
        maxPCIperPat{iState}(iP)=NaN;
        % Load PCI data with anatomical info
        stPCI = load(fileNamePCIAllStates{iP,iState});
        if ~isempty(stPCI.PCIstPerStimCh)
           for iStim=1:length(stPCI.stimSiteNamePNames)
                if find(strcmpi(stPCI.stimSiteNamePNames{iStim},stimSitesPerState{iState}))
                    % Organize PCI with same channel order as RespCh/anatomical data
                    PCIVals = [stPCI.PCIstPerStimCh{iStim}];
                    PCIPerState{iState} =  [PCIPerState{iState}, PCIVals];
                    stimSitesPNamesPerState{iState} = [stimSitesPNamesPerState{iState}, stPCI.stimSiteNamePNames(iStim)];
                    maxPCIperPat{iState}(iP) = max(maxPCIperPat{iState}(iP), PCIVals);
                end
            end
            pNamesMaxPCI{iState}{iP} =stPCI.channInfo.pName;
   %         gralRegionsStimChPerState{iState} = [gralRegionsStimChPerState{iState}, gralRegionsStimCh];
        end
    end
end
%% Find which channels are in the regions we want to compare
PCIPerStatePerRegion = cell(nStates,length(regionNames));
stimSitesPerStatePerRegion = cell(nStates,length(regionNames));
for iState=1:nStates
    for iRegion=1:length(regionNames)
%         nTotalPerRegion = zeros(1,length(gralRegionsRespCh{iState}));
%         for iCh=1:length(gralRegionsRespCh{iState})
%             [indChPerRegion] = findChannelsWithinRegion(gralRegionsPerChPerState{iState}(iCh), regionNames{iRegion});
%             nTotalPerRegion(iCh) = length(cell2mat(indChPerRegion));
%         end
        
        [indChWithinStimRegion, PCIWithinStimRegion, stimChNamesPerRegion] = findChannelsWithinRegion(gralRegionsStimChPerState{iState}, regionNames{iRegion}, PCIPerState{iState}, stimSitesPerState{iState});
        
        % Assign depending on what we want to analyse
%        PCIPerStatePerRegion{iState,iRegion} = nan(1, length(PCIPerRegion));
        PCIPerStatePerRegion{iState,iRegion} = PCIWithinStimRegion{1};
        stimSitesPerStatePerRegion(iState,iRegion) = stimChNamesPerRegion; % only stim channels in this region
    end
    %  [indRecChWithinRegions{iState}] = findChannelsWithinRegion(gralRegionsPerChPerState{iState}, regionNames);
end

%% PLOTS
% Plot only those with corresponding stim channels
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
dirImages = [dirResults,filesep,'images'];
cfgStats.dirImages = dirImages;
%% Plot Max PCI
cfgStats.bipolarChannels = pNamesMaxPCI;
cfgStats.legLabel = cfgStats.allStates;
cfgStats.ylabel = ['Max PCI per Patient'] ;
titName = [cfgStats.titName, 'Max PCI per Patient'] ;
plotWakeVsAnesthesiaPerCh([], maxPCIperPat, titName, cfgStats, pairComps);

%% PLot within stim region 
for iRegion=1:length(regionNames)
    cfgStats.bipolarChannels = stimSitesPerStatePerRegion(:,iRegion);
    cfgStats.legLabel = cfgStats.allStates;
    cfgStats.ylabel = ['PCI ', regionNames{iRegion}] ;
    titName = [cfgStats.titName, ' PCI ', regionNames{iRegion}] ;
    plotWakeVsAnesthesiaPerCh([], PCIPerStatePerRegion(:,iRegion), titName, cfgStats, pairComps);
end


%% Stats within Stim region
for iRegion=1:length(regionNames)
    PCIThisRegion = PCIPerStatePerRegion(:,iRegion);
    cfgStats.bipolarChannels = stimSitesPerStatePerRegion(:,iRegion);
    titNamePerRegion = [cfgStats.titName, ' ', regionNames{iRegion}] ;
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileName = [filepath,filesep,name,'_',regionNames{iRegion},'.',ext] ;
    for iComp=1:size(pairComps,1)
        titName = [titNamePerRegion,' ',num2str([pairComps(iComp,:)])];
        [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
        if ~isempty(commonCh)
            legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(indIn1)),')']);
            % PCI per region
            cfgStats.sheetName ='PCI';
            PCIVal1 = PCIThisRegion{pairComps(iComp,1)}(indIn1);
            PCIVal2 = PCIThisRegion{pairComps(iComp,2)}(indIn2);
            [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(PCIVal1,PCIVal2,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
            disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N= ',num2str(length(indIn1))])
            
            % compute relative values as Val1-Val2 / Val1+Val2 to use in next comparison
            relativePCI{iComp,iRegion} = (PCIVal1 - PCIVal2) ./(PCIVal1 + PCIVal2);
            stimChPerCompRegion{iComp,iRegion} = commonCh;
            
            
            %save stats
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).pVal = pairedTtest;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).median1 = medianVal1;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).median2 = medianVal2;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).relativePCI = relativePCI{iComp,iRegion};
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).commonCh =commonCh;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).values1 =PCIVal1;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).values2 =PCIVal2;
            
        end
    end    
    statsResults.WithStimChInRegion.(regionNames{iRegion}).PCIThisRegion = PCIThisRegion;
    statsResults.WithStimChInRegion.(regionNames{iRegion}).pairComps = pairComps;
    statsResults.WithStimChInRegion.(regionNames{iRegion}).legLabel = cfgStats.legLabel;
    statsResults.WithStimChInRegion.(regionNames{iRegion}).bipolarChannels = cfgStats.bipolarChannels;
end

%% Relative comparison: Anesthesia-WakeOR vs Sleep-WakeEMU
indCompSleepWakeEMU =2;
indCompAnesthesiaWakeOR =3;
legComp = {[cfgStats.legLabel{pairComps(indCompSleepWakeEMU,:)}],[cfgStats.legLabel{pairComps(indCompAnesthesiaWakeOR,:)}]};

for iRegion=1:length(regionNames)
    figure; hold on;
    for iComp=1:size(pairComps,1)
        subplot(1,2*size(pairComps,1),iComp*2-1)
        plot(relativePCI{iComp,iRegion},'.','MarkerSize',20);
        line([1 length(relativePCI{iComp,iRegion})],[0 0],'Color', 'k','LineWidth',3)
        line([1 length(relativePCI{iComp,iRegion})],[median(relativePCI{iComp,iRegion}) median(relativePCI{iComp,iRegion})],'Color', 'r','LineWidth',3)
        ylim([-1 1])
        xlim([0 length(relativePCI{iComp,iRegion})+1])
        grid on;
        legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(relativePCI{iComp,iRegion})),')']);
        xticklabels({})

        title([legLabel{:}]);
        % boxplot of same data
        subplot(1,2*size(pairComps,1),iComp*2)
        boxplot(relativePCI{iComp,iRegion})
        ylim([-1 1])
        yticklabels({})
        xticklabels([regionNames{iRegion}, ' ', num2str([pairComps(iComp,:)])])
    end
    suptitle(['Rel PCI ', regionNames{iRegion}])
    %Save figure
    titNameForFile = ['Rel_',regexprep([cfgStats.titName, regionNames{iRegion}],'\W','_')];
    saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.png']);
    saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.svg']);
    savefig(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.fig'],'compact');

    % compare Anesthesia-WakeOR vs Sleep-WakeEMU ONLY for those with all states
    [indIn1, indIn2, commonCh] = strmatchAll(stimChPerCompRegion{indCompSleepWakeEMU,iRegion}, stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion});
    relPCISleep = relativePCI{indCompSleepWakeEMU,iRegion};
    relPCIAnesthesia = relativePCI{indCompAnesthesiaWakeOR,iRegion};
    
    if ~isempty(commonCh)
        legLabel= strcat('Rel ',legComp,[' (', num2str(length(indIn1)),')']);
        titName = ['RelPCIPAIR ',cfgStats.titName,' ',regionNames{iRegion}(1:min(5,end)),' Sleep-Anest'];
        [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(relPCISleep(indIn1),relPCIAnesthesia(indIn2),titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
        disp(['Wilcoxon: ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N= ',num2str(length(indIn1))])
        statsResults.RelSleepAnesth.(regionNames{iRegion}).pVal = pairedTtest;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelSleepWakeEMU = medianVal1;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).medianRelAnesthWakeOR = medianVal2;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).commonCh =commonCh;
        statsResults.RelSleepAnesth.(regionNames{iRegion}).relSleepWakeEMU = relPCISleep(indIn1);
        statsResults.RelSleepAnesth.(regionNames{iRegion}).relAnesthesiaWakeOR = relPCIAnesthesia(indIn2);
     
        % PCI NON-PAIR stats
        legLabel= strcat('Rel ', legComp,' (', {num2str(length(relPCISleep)),num2str(length(relPCIAnesthesia))},')');
        cfgStats.sheetName = ['RelPCINONPAIR',regionNames{iRegion}(1:min(5,end)),'SleepAnes'];
        titName = ['RelNONPAIR ',cfgStats.titName,' ',regionNames{iRegion}(1:min(5,end)),' Sleep-Anest'];
        [nonpairedTtest, medianVal1, medianVal2] = computeRankSumSaveInXls(relPCISleep, relPCIAnesthesia,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],[cfgStats.dirImages,filesep,'RelativeNonPairedStats'],cfgStats.useParam);
        disp(['RankSUM: ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relPCISleep)),' N2= ',num2str(length(relPCIAnesthesia))])
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).pVal = nonpairedTtest;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelSleepWakeEMU = medianVal1;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).medianRelAnesthWakeOR = medianVal2;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).chNamesEMU =stimChPerCompRegion{indCompSleepWakeEMU,iRegion};
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).chNamesOR =stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion};
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relSleepWakeEMU = relPCISleep;
        statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).relAnesthesiaWakeOR = relPCIAnesthesia;
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
        relativePCIRegion1 = relativePCI{iRelState, pairRegionsComp(iCompRegion,1)};
        relativePCIRegion2 = relativePCI{iRelState, pairRegionsComp(iCompRegion,2)};
        
        if ~isempty(relativePCIRegion1) && ~isempty(relativePCIRegion2)
            % # Responsive channels NON-PAIR stats
            legLabel= strcat('Rel ',regionNames(pairRegionsComp(iCompRegion,:)),' (', {num2str(length(relativePCIRegion1)),num2str(length(relativePCIRegion2))},')');
            cfgStats.sheetName = ['RelPCI',thisRelState,thisRegionsToCompare];
            titName = ['RelPCI',cfgStats.titName, ' ',thisRelState,' ',thisRegionsToCompare];
            [nonpairedTtest, medianVal1, medianVal2] = computeRankSumSaveInXls(relativePCIRegion1,relativePCIRegion2,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairRegionsComp(iCompRegion,:)])],[cfgStats.dirImages,filesep,'RelativeCompareRegions'],cfgStats.useParam);
            disp(['RankSUM: ', cfgStats.sheetName,' between ',thisRegionsToCompare, ' ', cfgStats.anatRegionFor,' ', thisRelState,' ',' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relativePCIRegion1)),' N2= ',num2str(length(relativePCIRegion2))])
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).pVal = nonpairedTtest;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(['median',regionNames{pairRegionsComp(iCompRegion,1)}]) = medianVal1;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(['median',regionNames{pairRegionsComp(iCompRegion,2)}]) = medianVal2;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).chNamesRegion1 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,1)};
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).chNamesRegion2 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,2)};
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).relativeRespRegion1 = relativePCIRegion1;
            statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).relativeRespRegion2 = relativePCIRegion2;
        end
    end
end


%% Save info in MAT file
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    matFileNameResults = [filepath,filesep,'PCIPerRegion_',name,'.mat'] ;

save([matFileNameResults], 'regionNames', 'stimSitesPerStatePerRegion', 'cfgStats','fileNamePCIAllStates',...
    'PCIPerStatePerRegion', 'relativePCI', 'pairComps', 'maxPCIperPat', 'statsResults', ...
    'anatRegionsStimChPerState', 'anatRegionsPerChPerState', 'gralRegionsStimChPerState', 'gralRegionsPerChPerState', 'chNamesPerState',   'anatLabels', ...
    'stimSitesPerState', 'pNamesPerState','pNamesMaxPCI');


diary off;
