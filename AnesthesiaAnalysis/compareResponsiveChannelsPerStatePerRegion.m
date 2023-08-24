function compareResponsiveChannelsPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStats)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

if ~isfield(cfgStats,'allStatesTitName'), cfgStats.allStatesTitName= cfgStats.allStates; end  % allStatesTitName is used to remove from titName (in order to match channels)
if ~isfield(cfgStats,'anatRegionFor'), cfgStats.anatRegionFor= 'stimCh'; end  % options: 'stimCh or respCh'

regionNames = cfgStats.regionsToCompare;

% Start Diary
if ~exist(dirResults,'dir'),mkdir(dirResults); end
diary([dirResults,filesep,'log','CompareRespChannelsPerRegion',cfgStats.anatRegionFor,'.log'])

%% Get nRespChannels for all states and stim channels
[nRespPerState, perRespChPerState, ~, ~, meanNRespPerState, nRespPerStatePerPat, stimSitesPerStatePerPat]...
    = getNRespChannels(fileNameRespChAllPatAllStates, cfgStats.stimChPerPat);

%% Get anatomical information nRespChannels for all states and stim channels
[anatRegionsRespChPerState, anatRegionsStimChPerState, anatRegionsPerChPerState, gralRegionsRespChPerState, gralRegionsStimChPerState, gralRegionsPerChPerState, chNamesRespPerState, chNamesPerState, stimSitesPerState, pNamesPerState, anatLabels, labelPerRegion] ...
    = getRegionRespChannels(fileNameRespChAllPatAllStates, cfgStats.stimChPerPat);

%% Find which channels are in the regions we want to compare
nRespPerStatePerRegion = cell(nStates,length(regionNames));
percPerStatePerRegion = cell(nStates,length(regionNames));
percTOTPerStatePerRegion = cell(nStates,length(regionNames));
percPerStateWithinRegion = cell(nStates,length(regionNames));
stimSitesPerStatePerRegion = cell(nStates,length(regionNames));
for iState=1:nStates
    for iRegion=1:length(regionNames)
        nRespPerRegion = zeros(1,length(nRespPerState{iState}));
        nTotalPerRegion = zeros(1,length(nRespPerState{iState}));
        for iCh=1:length(nRespPerState{iState})
            [indRespCh] = findChannelsWithinRegion(gralRegionsRespChPerState{iState}(iCh), regionNames{iRegion});
            nRespPerRegion(iCh) = length(cell2mat(indRespCh));
            [indChPerRegion] = findChannelsWithinRegion(gralRegionsPerChPerState{iState}(iCh), regionNames{iRegion});
            nTotalPerRegion(iCh) = length(cell2mat(indChPerRegion));
        end
        percOfRespPerRegion = nRespPerRegion ./ nRespPerState{iState}; % % of channels in Region with resp - How many of the resp are  (e.g. qANT)
        percOfRespPerRegion(isnan(percOfRespPerRegion))=0; % change nan to zero because these are due to channels with ZERO response
        percTotRespPerRegion = percOfRespPerRegion .* perRespChPerState{iState} ; % % of resp in rgion out of TOTAL # channels (pTOTANT)
        percRespOutOfChInRegion = nRespPerRegion ./ nTotalPerRegion ; % % of channels IN a region with resp (pANT)
        
        [indChWithinStimRegion, nRespWithinStimRegion, stimChNamesPerRegion] = findChannelsWithinRegion(gralRegionsStimChPerState{iState}, regionNames{iRegion}, nRespPerState{iState}, stimSitesPerState{iState});
        [indChWithinStimRegion, percWithinStimRegion] = findChannelsWithinRegion(gralRegionsStimChPerState{iState}, regionNames{iRegion}, perRespChPerState{iState});
        indChWithinStimRegion = indChWithinStimRegion{1};
        
        % Assign depending on what we want to analyse
        nRespPerStatePerRegion{iState,iRegion} = nan(1, length(nRespPerRegion));
        percPerStatePerRegion{iState,iRegion} = nan(1, length(nRespPerRegion));
        percTOTPerStatePerRegion{iState,iRegion} = nan(1, length(nRespPerRegion));
        percPerStateWithinRegion{iState,iRegion} = nan(1, length(nRespPerRegion));
        if strcmpi(cfgStats.anatRegionFor,'stimCh')
            nRespPerStatePerRegion{iState,iRegion} = nRespWithinStimRegion{1};
            percPerStatePerRegion{iState,iRegion} = percWithinStimRegion{1};
            stimSitesPerStatePerRegion(iState,iRegion) = stimChNamesPerRegion; % only stim channels in this region
        elseif strcmpi(cfgStats.anatRegionFor,'onlyrespCh')
            nRespPerStatePerRegion{iState,iRegion} = nRespPerRegion;
            percPerStatePerRegion{iState,iRegion} = percOfRespPerRegion;
            percTOTPerStatePerRegion{iState,iRegion} = percTotRespPerRegion;
            percPerStateWithinRegion{iState,iRegion} = percRespOutOfChInRegion;
            stimSitesPerStatePerRegion(iState,iRegion) = stimSitesPerState(iState); % All stim regions
        elseif strcmpi(cfgStats.anatRegionFor,'stimrespCh') %  both stim and rec Ch (within the same region)
            nRespPerStatePerRegion{iState,iRegion}(indChWithinStimRegion) = nRespPerRegion(indChWithinStimRegion);
            percPerStatePerRegion{iState,iRegion}(indChWithinStimRegion) = percOfRespPerRegion(indChWithinStimRegion);
            percTOTPerStatePerRegion{iState,iRegion}(indChWithinStimRegion) = percTotRespPerRegion(indChWithinStimRegion);
            percPerStateWithinRegion{iState,iRegion}(indChWithinStimRegion) = percRespOutOfChInRegion(indChWithinStimRegion);
            stimSitesPerStatePerRegion(iState,iRegion) = stimChNamesPerRegion;
        else % ALL - it does not make sense to use -> repeats the same info for all "regions" / use region='all' instead
            nRespPerStatePerRegion{iState,iRegion} = nRespPerState{iState};
            percPerStatePerRegion{iState,iRegion} = perRespChPerState{iState};
            stimSitesPerStatePerRegion(iState,iRegion) = stimSitesPerState(iState);
        end
    end
    %  [indRecChWithinRegions{iState}] = findChannelsWithinRegion(gralRegionsPerChPerState{iState}, regionNames);
end

%% PLot within stim region 
    % Plot only those with corresponding stim channels
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
for iRegion=1:length(regionNames)
    dirImages = [dirResults,filesep,'images'];
    cfgStats.dirImages = dirImages;
    cfgStats.bipolarChannels = stimSitesPerStatePerRegion(:,iRegion);
    cfgStats.legLabel = cfgStats.allStates;
    cfgStats.ylabel = ['# RespCh', regionNames{iRegion}] ;
    titName = [cfgStats.titName, ' RespCh ', regionNames{iRegion}] ;
    plotWakeVsAnesthesiaPerCh([], nRespPerStatePerRegion(:,iRegion), titName, cfgStats, pairComps);
    % % Repeat for percentage of responsive channels
    cfgStats.ylabel = ['perc RespCh', regionNames{iRegion}] ;
    titName = [cfgStats.titName, ' perc ', regionNames{iRegion}] ;
    plotWakeVsAnesthesiaPerCh([], percPerStatePerRegion(:,iRegion), titName, cfgStats, pairComps);
    % % Repeat for TOTAL percentage of responsive channels
    if ~all(isnan(percTOTPerStatePerRegion{iState,iRegion}))
        cfgStats.ylabel = ['percTOT RespCh', regionNames{iRegion}] ;
        titName = [cfgStats.titName, ' percTOTAL ', regionNames{iRegion}] ;
        plotWakeVsAnesthesiaPerCh([], percTOTPerStatePerRegion(:,iRegion), titName, cfgStats, pairComps);
    end
    % % Repeat for WITHIN REGION percentage of responsive channels
    if ~all(isnan(percPerStateWithinRegion{iState,iRegion}))
        cfgStats.ylabel = ['perc Within Region RespCh', regionNames{iRegion}] ;
        titName = [cfgStats.titName, ' percWITHIN ', regionNames{iRegion}] ;
        plotWakeVsAnesthesiaPerCh([], percPerStateWithinRegion(:,iRegion), titName, cfgStats, pairComps);
    end

end
close all;

%% check if at least cfgStats.minNumberRespCh responses in ANY REGION - now is done for ALL STATES!
indWithRepCh=cell(1,size(pairComps,1));
indWithRespPerComp=cell(1,size(pairComps,2));
stimSitesPerComparison=cell(1,size(pairComps,1));
for iComp=1:size(pairComps,1)
    [indIn1, indIn2, commonCh] = strmatchAll(stimSitesPerState{pairComps(iComp,1)}, stimSitesPerState{pairComps(iComp,2)});
%     if isfield(cfgStats,'minNumberRespCh') && ~isempty(cfgStats.minNumberRespCh)
%         indWithRepCh{iComp} = unique([find(nRespPerState{pairComps(iComp,1)}(indIn1)>=cfgStats.minNumberRespCh), find(nRespPerState{pairComps(iComp,2)}(indIn2)>=cfgStats.minNumberRespCh)]);
%         stimSitesPerComparison{iComp} = commonCh(indWithRepCh{iComp});
%         indWithRespPerComp{iComp,1} = indIn1(indWithRepCh{iComp});
%         indWithRespPerComp{iComp,2} = indIn2(indWithRepCh{iComp});
%     else
        indWithRespPerComp{iComp,1} = indIn1;
        indWithRespPerComp{iComp,2} = indIn2;
%     end
end
statsResults.WithStimChInRegion.indWithRepCh = indWithRepCh;
statsResults.WithStimChInRegion.indWithRespPerComp = indWithRespPerComp;
statsResults.WithStimChInRegion.stimSitesPerComparison = stimSitesPerComparison;
statsResults.WithStimChInRegion.pairComps = pairComps;
statsResults.cfgStats = cfgStats;

%% Stats within Stim region - For now ONLY plot n Resp relative
relativeNResp = cell(size(pairComps,1), length(regionNames));
relativePercResp = cell(size(pairComps,1), length(regionNames));
relativePercTOTResp = cell(size(pairComps,1), length(regionNames));
relativePercWithinResp = cell(size(pairComps,1), length(regionNames));

for iRegion=1:length(regionNames)
    cfgStats.bipolarChannels = stimSitesPerStatePerRegion(:,iRegion);
    titNamePerRegion = [cfgStats.titName, ' ', regionNames{iRegion}] ;
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileName = [filepath,filesep,name,'_',regionNames{iRegion},ext] ;
    nRespThisRegion = nRespPerStatePerRegion(:,iRegion);
    statsResults.WithStimChInRegion.(regionNames{iRegion}).nRespThisRegion = nRespThisRegion;
    statsResults.WithStimChInRegion.(regionNames{iRegion}).pairComps = pairComps;
    statsResults.WithStimChInRegion.(regionNames{iRegion}).legLabel = cfgStats.legLabel;
    statsResults.WithStimChInRegion.(regionNames{iRegion}).bipolarChannels = cfgStats.bipolarChannels;
    
    for iComp=1:size(pairComps,1)
        titName = [titNamePerRegion,' ',num2str([pairComps(iComp,:)])];
        % ONLY keep those with at least minTrials and that are common to both states
        [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
        indIn1 = intersect(indIn1,indWithRespPerComp{iComp,1});
        indIn2 = intersect(indIn2,indWithRespPerComp{iComp,2});
        commonCh = cfgStats.bipolarChannels{pairComps(iComp,1)}(indIn1);
        if ~isempty(commonCh)
            
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).commonCh =commonCh;
 %           statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).indIn1 =indIn1;
 %           statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).indIn2 =indIn2;
            % # Resp Ch
            cfgStats.sheetName ='nResp';
            nRespInd1 =  nRespThisRegion{pairComps(iComp,1)}(indIn1);
            nRespInd2 =  nRespThisRegion{pairComps(iComp,2)}(indIn2);
            legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(indIn1)),')']);
           % Stats
            [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(nRespInd1, nRespInd2,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
            disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
            % compute relative values as Val1-Val2 / Val1+Val2 to use in next comparison
            relativeNResp{iComp,iRegion} = (nRespInd1 - nRespInd2) ./(nRespInd1 + nRespInd2);
            %save stats
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.pVal = pairedTtest;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.median1 = medianVal1;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.median2 = medianVal2;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.relativeNResp = relativeNResp{iComp,iRegion};
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.values1 = nRespInd1;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.values2 = nRespInd2;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).nResp.commonCh =commonCh;

            % percentage Resp Ch
            cfgStats.sheetName ='perResp';
            percThisRegion = percPerStatePerRegion(:,iRegion);
            percInd1 = percThisRegion{pairComps(iComp,1)}(indIn1);
            percInd2 = percThisRegion{pairComps(iComp,2)}(indIn2);
            [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(percInd1,percInd2,[titName,'_perResp'],legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
            disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}],' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
            relativePercResp{iComp,iRegion} = (percInd1 - percInd2) ./(percInd1 + percInd2);
            %save stats
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.pVal = pairedTtest;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.median1 = medianVal1;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.median2 = medianVal2;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.relativePercResp = relativePercResp{iComp,iRegion};
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.values1 = percInd1;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.values2 = percInd2;
            statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perResp.commonCh =commonCh;

            % percentage TOT Resp Ch
            if ~all(isnan(percTOTPerStatePerRegion{iState,iRegion}))
                cfgStats.sheetName ='perTOTAL';
                percThisRegion = percTOTPerStatePerRegion(:,iRegion);
                [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(percThisRegion{pairComps(iComp,1)}(indIn1),percThisRegion{pairComps(iComp,2)}(indIn2),[titName,'_perTOTAL'],legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
                disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}],' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
                relativePercTOTResp{iComp,iRegion} = (percThisRegion{pairComps(iComp,1)}(indIn1) - percThisRegion{pairComps(iComp,2)}(indIn2)) ./(percThisRegion{pairComps(iComp,1)}(indIn1) + percThisRegion{pairComps(iComp,2)}(indIn2));
                %save stats
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.pVal = pairedTtest;
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.median1 = medianVal1;
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.median2 = medianVal2;
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.relativePercTOTResp = relativePercTOTResp{iComp,iRegion};
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.values1 = percThisRegion{pairComps(iComp,1)}(indIn1);
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.values2 = percThisRegion{pairComps(iComp,2)}(indIn2);
               statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perTOTAL.commonCh =commonCh;
            end
            % percentage Resp Ch
            if ~all(isnan(percPerStateWithinRegion{iState,iRegion}))
                cfgStats.sheetName ='perWITHIN';
                percThisRegion = percPerStateWithinRegion(:,iRegion);
                [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(percThisRegion{pairComps(iComp,1)}(indIn1),percThisRegion{pairComps(iComp,2)}(indIn2),[titName,'_perWITHIN'],legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
                disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}],' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
                relativePercWithinResp{iComp,iRegion} = (percThisRegion{pairComps(iComp,1)}(indIn1) - percThisRegion{pairComps(iComp,2)}(indIn2)) ./(percThisRegion{pairComps(iComp,1)}(indIn1) + percThisRegion{pairComps(iComp,2)}(indIn2));
                %save stats
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.pVal = pairedTtest;
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.median1 = medianVal1;
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.median2 = medianVal2;
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.relativePercWithinResp = relativePercWithinResp{iComp,iRegion};
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.values1 = percThisRegion{pairComps(iComp,1)}(indIn1);
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.values2 = percThisRegion{pairComps(iComp,2)}(indIn2);
                statsResults.WithStimChInRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).perWITHIN.commonCh =commonCh;
            end
        end
        stimChPerCompRegion{iComp,iRegion} = commonCh;
    end
end

%% Relative comparison: Anesthesia-WakeOR vs Sleep-WakeEMU
relativeRespTypes = struct('nResp', relativeNResp,'perResp', relativePercResp, 'perTOTAL',relativePercTOTResp,'perWITHIN',relativePercWithinResp);
respTypeNames = fieldnames(relativeRespTypes);

%Plot
for iRegion=1:length(regionNames)
    for iRespType = 1:length(respTypeNames)
        figure; hold on;
        for iComp=1:size(pairComps,1)
            stRelativeResp = relativeRespTypes(iComp,iRegion);
            relativeResp = stRelativeResp.(respTypeNames{iRespType});
            subplot(1,2*size(pairComps,1),iComp*2-1)
            plot(relativeResp,'.','MarkerSize',20);
            line([1 length(relativeResp)],[0 0],'Color', 'k','LineWidth',3)
            line([1 length(relativeResp)],[median(relativeResp) median(relativeResp)],'Color', 'r','LineWidth',3)
            ylim([-1 1])
            xlim([0 length(relativeResp)+1])
            grid on;
            legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(relativeResp)),')']);
            xticklabels({})
            
            title([legLabel{:}]);
            % boxplot of same data
            subplot(1,2*size(pairComps,1),iComp*2)
            boxplot(relativeResp)
            ylim([-1 1])
            yticklabels({})
            xticklabels([regionNames{iRegion}, ' ', num2str([pairComps(iComp,:)])])
        end
        suptitle(['Rel ',respTypeNames{iRespType},' Ch ', regionNames{iRegion}])
        %Save figure
        titNameForFile = ['Rel_',regexprep([cfgStats.titName, respTypeNames{iRespType}, regionNames{iRegion}],'\W','_')];
        if ~exist([cfgStats.dirImages, filesep, respTypeNames{iRespType}],'dir'), mkdir([cfgStats.dirImages, filesep, respTypeNames{iRespType}]);end
        saveas(gcf,[cfgStats.dirImages, filesep, respTypeNames{iRespType},filesep, titNameForFile,'.png']);
        saveas(gcf,[cfgStats.dirImages, filesep,respTypeNames{iRespType},filesep, titNameForFile,'.svg']);
        savefig(gcf,[cfgStats.dirImages, filesep,respTypeNames{iRespType},filesep, titNameForFile,'.fig'],'compact');
    end
end
close all;

%% compare Anesthesia-WakeOR vs Sleep-WakeEMU ONLY for those with all states
indCompSleepWakeEMU =2;
indCompAnesthesiaWakeOR =3;
legComp = {[cfgStats.legLabel{pairComps(indCompSleepWakeEMU,:)}],[cfgStats.legLabel{pairComps(indCompAnesthesiaWakeOR,:)}]};
for iRegion=1:length(regionNames)
    [indIn1, indIn2, commonCh] = strmatchAll(stimChPerCompRegion{indCompSleepWakeEMU,iRegion}, stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion});
    if ~isempty(commonCh)
        statsResults.RelSleepAnesth.(regionNames{iRegion}).commonCh =commonCh;
        for iRespType = 1:length(respTypeNames)
            stRelativeRespSleep = relativeRespTypes(indCompSleepWakeEMU,iRegion);
            relativeRespSleep = stRelativeRespSleep.(respTypeNames{iRespType});
            stRelativeRespAnesthesia = relativeRespTypes(indCompAnesthesiaWakeOR,iRegion);
            relativeRespAnesthesia = stRelativeRespAnesthesia.(respTypeNames{iRespType});
            if ~isempty(relativeRespSleep) && ~all(isnan(relativeRespSleep)) && ~all(isnan(relativeRespAnesthesia(indIn2)))
                % # Responsive channels - PAIRED STATS!
                legLabel= strcat('RelPAIRED',legComp,[' (', num2str(length(indIn1)),')']);
                cfgStats.sheetName = ['RelPAIR_',regionNames{iRegion}(1:min(5,end)),'_',respTypeNames{iRespType}(1:min(6,end)),'SleepAnes'];
                titName = ['RelPAIRED ',regionNames{iRegion}, ' ',respTypeNames{iRespType},' Sleep-Anest'];%cfgStats.titName
                [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(relativeRespSleep(indIn1),relativeRespAnesthesia(indIn2),titName,legLabel,xlsFileName,[cfgStats.sheetName],[cfgStats.dirImages,filesep,'RelativePairedStats'],cfgStats.useParam);
                disp(['Wilcoxon: ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N= ',num2str(length(indIn1))])
                statsResults.RelSleepAnesth.(regionNames{iRegion}).(respTypeNames{iRespType}).pVal = pairedTtest;
                statsResults.RelSleepAnesth.(regionNames{iRegion}).(respTypeNames{iRespType}).medianRelSleepWakeEMU = medianVal1;
                statsResults.RelSleepAnesth.(regionNames{iRegion}).(respTypeNames{iRespType}).medianRelAnesthWakeOR = medianVal2;
                statsResults.RelSleepAnesth.(regionNames{iRegion}).(respTypeNames{iRespType}).commonCh =commonCh;
                statsResults.RelSleepAnesth.(regionNames{iRegion}).(respTypeNames{iRespType}).relSleepWakeEMU = relativeRespSleep(indIn1);
                statsResults.RelSleepAnesth.(regionNames{iRegion}).(respTypeNames{iRespType}).relAnesthesiaWakeOR = relativeRespAnesthesia(indIn2);
                % # Responsive channels NON-PAIR stats
                legLabel= strcat('RelNONPAIR',legComp,' (', {num2str(length(relativeRespSleep)),num2str(length(relativeRespAnesthesia))},')');
                cfgStats.sheetName = ['RelNONPAIR',regionNames{iRegion}(1:min(5,end)),respTypeNames{iRespType},'SlAn'];
                titName = ['RelNONPAIR ',cfgStats.titName,' ', respTypeNames{iRespType},' SlAn'];
                [nonpairedTtest, medianVal1, medianVal2] = computeRankSumSaveInXls(relativeRespSleep,relativeRespAnesthesia,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],[cfgStats.dirImages,filesep,'RelativeNonPairedStats'],cfgStats.useParam);
                disp(['RankSUM: ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relativeRespSleep)),' N2= ',num2str(length(relativeRespAnesthesia))])
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).pVal = nonpairedTtest;
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).medianRelSleepWakeEMU = medianVal1;
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).medianRelAnesthWakeOR = medianVal2;
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).chNamesEMU =stimChPerCompRegion{indCompSleepWakeEMU,iRegion};
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).chNamesOR =stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion};
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).relSleepWakeEMU = relativeRespSleep;
                statsResults.RelSleepAnesthNONPAIRED.(regionNames{iRegion}).(respTypeNames{iRespType}).relAnesthesiaWakeOR = relativeRespAnesthesia;
            end
        end
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
    thisRelState = [cfgStats.legLabel{pairComps(iRelState,1)}(1:2),cfgStats.legLabel{pairComps(iRelState,2)}(1:2)];
    for iCompRegion=1:size(pairRegionsComp,1)
        thisRegionsToCompare = [regionNames{pairRegionsComp(iCompRegion,:)}];
        for iRespType = 1:length(respTypeNames)
            stRelativeResp = relativeRespTypes(iRelState, pairRegionsComp(iCompRegion,1));
            relativeRespRegion1 = stRelativeResp.(respTypeNames{iRespType});
            stRelativeResp = relativeRespTypes(iRelState, pairRegionsComp(iCompRegion,2));
            relativeRespRegion2 = stRelativeResp.(respTypeNames{iRespType});
            
            if ~isempty(relativeRespRegion1) && ~isempty(relativeRespRegion2)
                % # Responsive channels NON-PAIR stats
                legLabel= strcat('Rel ',regionNames(pairRegionsComp(iCompRegion,:)),' (', {num2str(length(relativeRespRegion1)),num2str(length(relativeRespRegion2))},')');
                cfgStats.sheetName = ['Rel',respTypeNames{iRespType},thisRelState,thisRegionsToCompare];
                titName = ['Rel',cfgStats.titName, respTypeNames{iRespType},' ',thisRelState,' ',thisRegionsToCompare];
                [nonpairedTtest, medianVal1, medianVal2] = computeRankSumSaveInXls(relativeRespRegion1,relativeRespRegion2,titName,legLabel,xlsFileName,[cfgStats.sheetName,num2str([pairRegionsComp(iCompRegion,:)])],[cfgStats.dirImages,filesep,'RelativeCompareRegions'],cfgStats.useParam);
                disp(['RankSUM: ', cfgStats.sheetName,' between ',thisRegionsToCompare, ' ', cfgStats.anatRegionFor,' ', thisRelState,' ',respTypeNames{iRespType},' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relativeRespRegion1)),' N2= ',num2str(length(relativeRespRegion2))])
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).pVal = nonpairedTtest;
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).(['median',regionNames{pairRegionsComp(iCompRegion,1)}]) = medianVal1;
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).(['median',regionNames{pairRegionsComp(iCompRegion,2)}]) = medianVal2;
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).chNamesRegion1 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,1)};
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).chNamesRegion2 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,2)};
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).relativeRespRegion1 = relativeRespRegion1;
                statsResults.RelRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(respTypeNames{iRespType}).relativeRespRegion2 = relativeRespRegion2;
            end
        end
    end
end



%% Save info in MAT file
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    matFileNameResults = [filepath,filesep,'nRespChPerRegion_',name,'.mat'] ;

save([matFileNameResults], 'regionNames', 'stimSitesPerStatePerRegion', 'cfgStats', 'fileNameRespChAllPatAllStates',...
    'percPerStateWithinRegion','percTOTPerStatePerRegion','percPerStatePerRegion','nRespPerStatePerRegion', 'pairComps',...
    'anatRegionsRespChPerState', 'anatRegionsStimChPerState', 'anatRegionsPerChPerState', 'gralRegionsRespChPerState', 'gralRegionsStimChPerState',...
    'gralRegionsPerChPerState', 'chNamesRespPerState', 'chNamesPerState', 'stimSitesPerState', 'pNamesPerState', 'anatLabels', 'labelPerRegion',...
    'nRespPerState', 'perRespChPerState', 'stimSitesPerState', 'pNamesPerState', 'meanNRespPerState', 'nRespPerStatePerPat', 'stimSitesPerStatePerPat',...
    'relativeNResp','relativePercResp','relativePercTOTResp','relativePercWithinResp','stimChPerCompRegion','statsResults',...
    'respTypeNames','indWithRepCh','indWithRespPerComp','stimSitesPerComparison','regionNamesToCompare','pairRegionsComp');


diary off;
