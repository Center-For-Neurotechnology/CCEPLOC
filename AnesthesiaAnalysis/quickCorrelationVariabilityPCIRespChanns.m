function quickCorrelationVariabilityPCIRespChanns(PCIFileName, respChFileName, variabilityFileName, dirImages, regionNames)

if ~exist('regionNames','var'), regionNames = {'all'}; end % all together
if ~iscell(regionNames), regionNames={regionNames};end

minNumRespCh = 5; % at least 5 responsive channels
considerChInElectrodeShaft = 0;
dirImages = [dirImages, 'withChInShaft',num2str(considerChInElectrodeShaft)];

if ~isdir(dirImages), mkdir(dirImages);end

%% Load nResp Channels
stRespCh = load(respChFileName);
nRespPerStatePerRegionAll = stRespCh.nRespPerStatePerRegion;
if all(isnan(stRespCh.percTOTPerStatePerRegion{1}))
    percPerStateWithinRegionAll = stRespCh.percPerStatePerRegion; % stimRespCh case
else
    percPerStateWithinRegionAll = stRespCh.percTOTPerStatePerRegion; % Only Resp case
end

relRespPerRegion = stRespCh.relativeNResp; % relative # Resp
anatRegionsResp = stRespCh.anatRegionsStimChPerState;
stimSitesPerStateResp = stRespCh.stimSitesPerState;
stimSitesPerCompResp = stRespCh.stimChPerCompRegion;
regionNamesResp = stRespCh.regionNames;
% we might want to check that the regions and states are the same


%% Load PCI values
stPCI = load(PCIFileName);
regionNamesPCI = stPCI.regionNames;
PCIPerStatePerRegionTemp = stPCI.PCIPerStatePerRegion;
anatRegionsPCI = stPCI.anatRegionsStimChPerState;
stimSitesPerStatePCITemp = stPCI.stimSitesPerState;
relPCIPerStatePerRegion = stPCI.relativePCI;
pairComp = stPCI.pairComps;
nStates = numel(stPCI.cfgStats.allStates);
nRegions = numel(regionNamesPCI);
for iRegion=1:nRegions
    stimSitesPerCompPCI{1,iRegion} = stPCI.statsResults.WithStimChInRegion.(regionNamesPCI{iRegion}).WakeORWakeEMU.commonCh;
    stimSitesPerCompPCI{2,iRegion} = stPCI.statsResults.WithStimChInRegion.(regionNamesPCI{iRegion}).SleepWakeEMU.commonCh;
    stimSitesPerCompPCI{3,iRegion} = stPCI.statsResults.WithStimChInRegion.(regionNamesPCI{iRegion}).AnesthesiaWakeOR.commonCh;
end

for iState=1:nStates 
  %  [stimSitesPerStatePCI{iState}, indUniqueStimCh] = unique(regexprep(stimSitesPerStatePCI{iState},'-',''),'stable');
    [stimSitesPerStatePCI{iState}, indUniqueStimCh] = unique(stimSitesPerStatePCITemp{iState},'stable');
%   % invert stim ch numbers - it should be corrected in PCI calculation code
%     [splitStimChPat, matchVal] = regexp(stimSitesPerStatePCITemp{iState},'_\D','split','match');
%     for iCh=1:numel(splitStimChPat)
%         [splitStimCh] = regexp(splitStimChPat{iCh}{1},'-','split');
%         stimSitesPerStatePCI{iState}(iCh) = strcat(splitStimCh{2}, '-',splitStimCh{1},matchVal{iCh},splitStimChPat{iCh}{2});
%     end
  
    anatRegionsPCI{iState} = anatRegionsPCI{iState}(indUniqueStimCh);
    for iRegion=1:length(regionNamesPCI)
        PCIPerStatePerRegion{iState,iRegion} = PCIPerStatePerRegionTemp{iState,iRegion}(indUniqueStimCh);
    end
end


%% Load Variability - Variability is per responsive channel - use mean/std per STIM ch  instead of each value
stVariability = load(variabilityFileName);
regionNamesVar = stVariability.regionNames;
varPerState = stVariability.logVariabilityPerStatePerRegion;% USE LOG as it is more normal to compute mean per stim/  variabilityPerStatePerRegion; %
relVarPerState = stVariability.relativeVariability;
commonChVarPerCompRegion = stVariability.commonChPerCompRegion;

for iState=1:nStates
   % [stimSitesPerStateVar{iState}, indStimSitesInFull, indStimSites] = unique(regexprep(stVariability.stimSitesPerState{iState},'-',''),'stable');
    [stimSitesPerStateVar{iState}, indStimSitesInFull, indStimSites] = unique(stVariability.stimSitesPerState{iState},'stable');
    anatRegionsStimVar{iState} = stVariability.anatRegionsStimChPerState{iState}(indStimSitesInFull);
    for iRegion=1:length(stVariability.regionNames)
        meanVariabilityPerState{iState,iRegion} = nan(1, length(stimSitesPerStateVar{iState}));
        for iStimCh=1:length(stimSitesPerStateVar{iState})
            indRecChPerStim = find(strcmpi(stimSitesPerStateVar{iState}{iStimCh}, stVariability.stimSitesPerStatePerRegion{iState,iRegion}));
%             % consider channels in stim shaft electrode?
            if ~considerChInElectrodeShaft
                %remove channels in electrode shaft from this analysis
                 isRecChInStimShaft = find(stVariability.rechInStimShaftPerState{iState}(indRecChPerStim));
                indRecChPerStim(isRecChInStimShaft)=[];
            end
             if ~isempty(indRecChPerStim)
                [meanVal, q25, q75, stdVal, stdErrorVal,medianVal,coeffVar]= meanQuantiles(varPerState{iState,iRegion}(indRecChPerStim), 2,0);
                meanVariabilityPerState{iState,iRegion}(iStimCh) = meanVal;  %medianVal; %
                stdVariabilityPerState{iState,iRegion}(iStimCh) = stdVal;
            else
                meanVariabilityPerState{iState,iRegion}(iStimCh) = NaN;
                stdVariabilityPerState{iState,iRegion}(iStimCh) = NaN;                
            end
        end
    end
end

% repeat for relative variability
nComp = size(commonChVarPerCompRegion,1);
for iComp=1:nComp
    for iRegion=1:length(stVariability.regionNames)
        if ~isempty(commonChVarPerCompRegion{iComp, iRegion})
            stimChPNameComparison = split(commonChVarPerCompRegion{iComp, iRegion},'st');
            %       stimChComparison = split(commonChVarPerCompRegion{iComp, iRegion},{'st','_'});
            [stimSitesPerCompVar{iComp, iRegion}, indStimSitesInFull, indStimSites] = unique(squeeze(stimChPNameComparison(1,:,2)),'stable');
            
            meanVariabilityPerComp{iComp,iRegion} = nan(1, length(stimSitesPerCompVar{iComp, iRegion}));
            for iStimCh=1:length(stimSitesPerCompVar{iComp, iRegion})
                indRecChPerStim = find(strcmpi(stimSitesPerCompVar{iComp, iRegion}{iStimCh}, squeeze(stimChPNameComparison(1,:,2))));
                [meanVal, q25, q75, stdVal, stdErrorVal,medianVal,coeffVar]= meanQuantiles(relVarPerState{iComp,iRegion}(indRecChPerStim), 2,0);
                meanVariabilityPerComp{iComp,iRegion}(iStimCh) = meanVal;  %medianVal; %
                stdVariabilityPerComp{iComp,iRegion}(iStimCh) = stdVal;
            end
        else
            meanVariabilityPerComp{iComp,iRegion} = NaN;
            stdVariabilityPerComp{iComp,iRegion} = NaN;
        end
    end
end
%% Keep only stim channels with at least 5 RespCh - look in Region=all
stimChEnoughRespChAnyState = cell(0,0);
for iState=1:nStates
    stimChEnoughRespChAnyState = unique([stimChEnoughRespChAnyState, stimSitesPerStateResp{iState}(find(nRespPerStatePerRegionAll{iState,1}>=minNumRespCh))]);
end

% Keep only those with at least 5 Resp channels
for iState=1:nStates
    % PCI
    [indToKeepPCI, ind2, commonChPCI] = strmatchAll(stimSitesPerStatePCI{iState}, stimChEnoughRespChAnyState);
    stimSitesPerStatePCI{iState} = stimSitesPerStatePCI{iState}(indToKeepPCI);
    anatRegionsPCI{iState} = anatRegionsPCI{iState}(indToKeepPCI);
    % Resp
    [indToKeepResp, ind2, commonChResp] = strmatchAll(stimSitesPerStateResp{iState}, stimChEnoughRespChAnyState);
    stimSitesPerStateResp{iState} = stimSitesPerStateResp{iState}(indToKeepResp);
    anatRegionsResp{iState} = anatRegionsResp{iState}(indToKeepResp);
    % Variability
    [indToKeepVar, ind2, commonChVar] = strmatchAll(stimSitesPerStateVar{iState}, stimChEnoughRespChAnyState);
    stimSitesPerStateVar{iState} = stimSitesPerStateVar{iState}(indToKeepVar);
    anatRegionsStimVar{iState} = anatRegionsStimVar{iState}(indToKeepVar);
   
    % Measures
    for iRegion=1:length(regionNamesPCI)
        PCIPerStatePerRegion{iState,iRegion} = PCIPerStatePerRegion{iState,iRegion}(indToKeepPCI);
  %      relPCIPerStatePerRegion{iState,iRegion} = relPCIPerStatePerRegion{iState,iRegion}(indToKeepPCI);
    end
    for iRegion=1:length(regionNamesVar)
        meanVariabilityPerState{iState,iRegion} = meanVariabilityPerState{iState,iRegion}(indToKeepVar);
        stdVariabilityPerState{iState,iRegion} = stdVariabilityPerState{iState,iRegion}(indToKeepVar);
    end

end

%% Correlations
nRegions = numel(regionNames);
measNames = {'PCI','Resp','Var'};
allDataPCI=[];
allDataNResp=[];
allDataVar=[];
for iState=1:nStates
    [ind11, ind12, commonStimCh1] = strmatchAll(stimSitesPerStatePCI{iState}, stimSitesPerStateResp{iState});
    [ind21, ind22, commonStimCh2] = strmatchAll(stimSitesPerStateVar{iState}, stimSitesPerStateResp{iState});
    for iRegion=1:nRegions
        indRegion1 = find(strcmpi(regionNames{iRegion},regionNamesPCI));
        indRegion2 = find(strcmpi(regionNames{iRegion},regionNamesResp));
        indRegion3 = find(strcmpi(regionNames{iRegion},regionNamesVar));
        dataPCI = [PCIPerStatePerRegion{iState,indRegion1}(ind11)];
        allDataPCI = [allDataPCI, dataPCI];
       % dataResp = [nRespPerStatePerRegionAll{iState,indRegion2}(ind12)];
        dataResp = [percPerStateWithinRegionAll{iState,indRegion2}(ind12)];
        allDataNResp = [allDataNResp, dataResp];
        dataVar = [meanVariabilityPerState{iState,indRegion3}(ind21)];
        allDataVar = [allDataVar, dataVar];

        % Correlations and plot
%         [rxyVal, pVal, RL, RU] = corrcoef([dataPCI', dataResp',dataVar'],'rows','complete');
        
        % plot
        titName = ['corr PCI vs. nResp vs. Var ',regionNames{iRegion},' ',stPCI.cfgStats.allStates{iState}];
        figure('Name',titName);
        [rxyVal, pVal, hFig] = corrplot([dataPCI', dataResp',dataVar'],'type','Pearson','varNames',measNames,'testR','on');
        rxyPerState{iState,iRegion} = rxyVal;
        pValRxyPerState{iState,iRegion} = pVal;
        name4Save = regexprep(titName,'\s','');
        savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
        saveas(gcf, [dirImages,filesep, name4Save,'.png']);
        saveas(gcf, [dirImages,filesep, name4Save,'.svg']);
      
        disp(titName)
        disp({'Measure1','Measure2','Rxy','pVal'})
        disp([measNames(1), measNames(2) rxyVal(1,2), pVal(1,2)])
        disp([measNames(1), measNames(3) rxyVal(1,3), pVal(1,3)])
        disp([measNames(2), measNames(3) rxyVal(2,3), pVal(2,3)])
        
%        figure; hold on;
%         plot(dataPCI, dataResp,'o')
%         if pValRxyPerState{iState,iRegion}<0.05
%             b = regress(dataResp', [ones(length(dataResp),1) ,dataPCI']);
%             lineFit = b(1) + b(2) * dataPCI;
%             plot(dataPCI, lineFit)
%             legend(['rxy = ',num2str(rxyPerState{iState,iRegion}), ' p=',num2str(pValRxyPerState{iState,iRegion})])
%         end
%         xlabel('PCI')
%         ylabel('nResp')
    end
end

%% Correlations
measNames = {'relPCI','relResp','relVar'};
allDataRelPCI=[];
allDataRelNResp=[];
allDataRelVar=[];

for iComp=1:nComp
    for iRegion=1:nRegions
        indRegion1 = find(strcmpi(regionNames{iRegion},regionNamesPCI));
        indRegion2 = find(strcmpi(regionNames{iRegion},regionNamesResp));
        indRegion3 = find(strcmpi(regionNames{iRegion},regionNamesVar));
    [ind11, ind12, commonStimCh1] = strmatchAll(stimSitesPerCompPCI{iComp, indRegion1}, stimSitesPerCompResp{iComp, indRegion2});
    [ind21, ind22, commonStimCh2] = strmatchAll(stimSitesPerCompVar{iComp, indRegion3}, stimSitesPerCompResp{iComp, indRegion2});
        dataPCI = [relPCIPerStatePerRegion{iComp,indRegion1}(ind11)];
        allDataRelPCI = [allDataRelPCI, dataPCI];
        dataResp = [relRespPerRegion{iComp,indRegion2}(ind12)];
        allDataRelNResp = [allDataRelNResp, dataResp];
        dataVar = [meanVariabilityPerComp{iComp,indRegion3}(ind21)];
        allDataRelVar = [allDataRelVar, dataVar];

        % Correlations and plot
%         [rxyVal, pVal, RL, RU] = corrcoef([dataPCI', dataResp',dataVar'],'rows','complete');
        
        % plot
        titName = ['corr relPCI vs. relnResp vs. relVar ',regionNames{iRegion},' ',stPCI.cfgStats.allStates{pairComp(iComp,:)}];
        figure('Name',titName);
        [rxyVal, pVal, hFig] = corrplot([dataPCI', dataResp',dataVar'],'type','Pearson','varNames',measNames,'testR','on');
        rxyPerComp{iComp,iRegion} = rxyVal;
        pValRxyPerComp{iComp,iRegion} = pVal;
        name4Save = regexprep(titName,'\s','');
        savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
        saveas(gcf, [dirImages,filesep, name4Save,'.png']);
        saveas(gcf, [dirImages,filesep, name4Save,'.svg']);
      
        disp(titName)
        disp({'Measure1','Measure2','Rxy','pVal'})
        disp([measNames(1), measNames(2) rxyVal(1,2), pVal(1,2)])
        disp([measNames(1), measNames(3) rxyVal(1,3), pVal(1,3)])
        disp([measNames(2), measNames(3) rxyVal(2,3), pVal(2,3)])
    end
end

%% All together
titName = ['corr PCI vs. nResp vs. Var ',regionNames{iRegion},' allStates'];
figure('Name',titName);
[rxyVal, pVal, hFig] = corrplot([allDataPCI', allDataNResp',allDataVar'],'type','Pearson','varNames',measNames,'testR','on');
rxyPerStateAll= rxyVal;
pValRxyPerStateAll = pVal;

name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'.png']);
saveas(gcf, [dirImages,filesep, name4Save,'.svg']);


disp(titName)
disp({'Measure1','Measure2','Rxy','pVal'})
disp([measNames(1), measNames(2) rxyVal(1,2), pVal(1,2)])
disp([measNames(1), measNames(3) rxyVal(1,3), pVal(1,3)])
disp([measNames(2), measNames(3) rxyVal(2,3), pVal(2,3)])


%% All together Relative values
titName = ['corr RelPCI vs. RelnResp vs. RelVar ',regionNames{iRegion},' allStates'];
figure('Name',titName);
[rxyVal, pVal, hFig] = corrplot([allDataRelPCI', allDataRelNResp',allDataRelVar'],'type','Pearson','varNames',measNames,'testR','on');
rxyPerStateAll= rxyVal;
pValRxyPerStateAll = pVal;

name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'.png']);
saveas(gcf, [dirImages,filesep, name4Save,'.svg']);


disp(titName)
disp({'Measure1','Measure2','Rxy','pVal'})
disp([measNames(1), measNames(2) rxyVal(1,2), pVal(1,2)])
disp([measNames(1), measNames(3) rxyVal(1,3), pVal(1,3)])
disp([measNames(2), measNames(3) rxyVal(2,3), pVal(2,3)])


% [rxyVal, pVal] = corrcoef(allDataPCI, allDataNResp);
% % plot
% figure; hold on;
% plot(allDataPCI, allDataNResp,'o')
% if pValRxyPerStateAll<0.05
%     b = regress(allDataNResp', [ones(length(allDataNResp),1) ,allDataPCI']);
%     lineFit = b(1) + b(2) * dataPCI;
%     plot(dataPCI, lineFit)
%     legend(['rxy = ',num2str(rxyPerStateAll), ' p=',num2str(pValRxyPerStateAll)])
% end
% titName = ['corr PCI vs. nResp All'];
% title(titName)
% xlabel('PCI')
% ylabel('nResp')

