function [pVals] = corrVariabilityDistanceToStim(variabilityFileName, dirImages, regionName, anatRegionType)

if ~exist('regionName','var'), regionName = 'all'; end % all together
if ~exist('anatRegionType','var'), anatRegionType = 'StimCh'; end % StimCh

%minNumRespCh = 5; % at least 5 responsive channels
thDistLocalFar = 30; % assuming it is in mm
considerChInElectrodeShaft = 1; %0=DO NOT COSIDER channels within SHAFT
dirImages = [dirImages, 'withChInShaft',num2str(considerChInElectrodeShaft)];

cfgStats.useParam =2; % permutation test since recording channels are not independent
cfgStats.dirImages = dirImages;

if ~isdir(dirImages), mkdir(dirImages);end

%% Load Variability
stVariability = load(variabilityFileName);
regionNamesVar = stVariability.regionNames;
allStates = stVariability.cfgStats.allStates;
nStates = numel(allStates);
indRegion = strcmpi(regionName, regionNamesVar);

stimSitesPerState = stVariability.stimSitesPerStatePerRegion(:,indRegion);
varPerState = stVariability.variabilityPerStatePerRegion(:,indRegion);
for iState=1:nStates
    if strcmpi(anatRegionType, 'StimCh') % stim in region recordings everywhere - look for region of  stim channel
        indChInRegion = find([stVariability.gralRegionsStimChPerState{iState}.(regionName){:}]); % STIM in region / to change to Rec in region use gralRegionsPerChPerState
    else % recording in region - look for region of recording channels
        indChInRegion = find([stVariability.gralRegionsPerChPerState{iState}.(regionName){:}]); % STIM in region / to change to Rec in region use gralRegionsPerChPerState
    end
    RASCoordStimChPerState{iState} = stVariability.RASCoordStimChPerState{iState}(indChInRegion,:);
    RASCoordRecChPerState{iState} = stVariability.RASCoordPerChPerState{iState}(indChInRegion,:);
    % consider channels in stim shaft electrode?
    if ~considerChInElectrodeShaft
        %remove channels in electrode shaft from this analysis
        isRecChInStimShaft = find(stVariability.rechInStimShaftPerState{iState}(indChInRegion));
        stimSitesPerState{iState}(isRecChInStimShaft)=[];
        varPerState{iState}(isRecChInStimShaft)=[];
        RASCoordStimChPerState{iState}(isRecChInStimShaft,:)=[];
        RASCoordRecChPerState{iState}(isRecChInStimShaft,:)=[];
    end
end

%% Compute Euclidean distance Responsive to STIM channels
for iState=1:nStates
    indAllZero = find(sum(RASCoordRecChPerState{iState},2)==0);
    RASCoordRecChPerState{iState}(indAllZero,:) = NaN(length(indAllZero),3); % change  0,0,0 to NaN -> corresponds to unassigned coordinates
    [distRecToStimCh{iState}] = RASdistanceToStim(RASCoordRecChPerState{iState}, RASCoordStimChPerState{iState});
    isLocal{iState} = find(distRecToStimCh{iState} < thDistLocalFar); % less than 10mm is considered "local"
    isDistant{iState} = 1:length(distRecToStimCh{iState});
    isDistant{iState}(isLocal{iState})=[];
end
   
%% Correlations
rxyPerState = cell(1,nStates);
%pVals.RxyPerState = cell(1,nStates);
titNameFig = ['Correlation Variability vs. Distance to STIM ', regionName];
name4Save = regexprep(titNameFig,'\s','');

figure('Name', titNameFig);
for iState=1:nStates    
    dataDist = distRecToStimCh{iState}';
    dataVar = varPerState{iState};
    [rxyVal, pVal, RL, RU] = corrcoef(dataDist, dataVar,'rows','complete');
    disp([regionName,'Correlation Coef: ', allStates{iState},' between ', 'VAriability and Distance ',  ' - pVal= ', num2str(pVal(1,2)),' rxyVal= ', num2str(rxyVal(1,2)),' RL= ', num2str(RL(1,2)),' RU= ', num2str(RU(1,2))])
    
    rxyPerState{iState} = rxyVal(1,2);
    pVals.rxyPearson.(allStates{iState}).pVal = pVal(1,2);
    pVals.rxyPearson.(allStates{iState}).rxy = rxyVal(1,2);
    % plot
    subplot(ceil(sqrt(nStates)),ceil(sqrt(nStates)),iState)
    hold on;
    plot(dataDist, dataVar,'o')
    if pVals.rxyPearson.(allStates{iState}).pVal<0.05
        b = regress(dataVar', [ones(length(dataVar),1) ,dataDist']);
        lineFit = b(1) + b(2) * dataDist;
        plot(dataDist, lineFit)
        legend(['rxy = ',num2str(rxyPerState{iState}), ' p=',num2str(pVals.rxyPearson.(allStates{iState}).pVal)])
    end
    titName = ['corr Variability vs. Distance ',allStates{iState}];
    title(titName)
    xlabel('Distance to Stim (mm)')
    ylabel('Variability')    
end
savefig(gcf,[cfgStats.dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [cfgStats.dirImages,filesep, name4Save,'.png']);
saveas(gcf, [cfgStats.dirImages,filesep, name4Save,'.svg']);

% %% Histograms
% figure;
% for iState=1:nStates    
%     dataDist = distRecToStimCh{iState}';
%     dataVar = varPerState{iState};
%     [rxyVal, pVal, RL, RU] = corrcoef(dataDist, dataVar,'rows','complete');
%     disp(['Pearson Correlation: ', allStates{iState},' between ', 'VAriability and Distance ',  ' - pVal= ', num2str(pVal(1,2)),' rxyVal= ', num2str(rxyVal(1,2)),' RL= ', num2str(RL(1,2)),' RU= ', num2str(RU(1,2))])
%     
%     % plot
%     subplot(ceil(sqrt(nStates)),ceil(sqrt(nStates)),iState)
%     hold on;
%     histogram(dataVar)
% 
%     titName = ['Hist Variability vs. Distance ',allStates{iState}];
%     title(titName)
%     xlabel('Distance to Stim')
%     ylabel('Variability')    
% end
% savefig(gcf,[cfgStats.dirImages, filesep, name4Save,'.fig'],'compact');
% saveas(gcf, [cfgStats.dirImages,filesep, name4Save,'.png']);
% 


%% Compare variability per state for local vs distant
titNameFig = ['Comp Local vs Distant Variability ', regionName];
name4Save = regexprep(titNameFig,'\s','');
cfgStats.xlsFileName = [cfgStats.dirImages, filesep, name4Save];
cfgStats.sheetName = ['LocalDistVar',num2str(thDistLocalFar)];

for iState=1:nStates    
    dataLocal = varPerState{iState}(isLocal{iState});
    dataDistant = varPerState{iState}(isDistant{iState});
    legLabel = {['Local (',num2str(length(dataLocal)),')'],['Distant (',num2str(length(dataDistant)),')']};
    [unpairedTest, medianVal1, medianVal2, testName] = computeRankSumSaveInXls(dataLocal,dataDistant,[titNameFig,allStates{iState}],legLabel,[cfgStats.xlsFileName,'_TTEST.xls'],[cfgStats.sheetName, allStates{iState}],cfgStats.dirImages,cfgStats.useParam);
    pVals.LocalDist.unpairedTtest.(allStates{iState}) = unpairedTest;
    disp([regionName,' ',testName,': ', cfgStats.sheetName, ' ',allStates{iState},' between ',[legLabel{:}], ' ',  ' - pVal= ', num2str(unpairedTest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])

end

% %% Compare variability between states for local and distant
% pairComps = [1,3;1,2;3,4];
% % Local
% titNameFig = ['Comp Local Variability', regionName];
% name4Save = regexprep(titNameFig,'\s','');
% cfgStats.xlsFileName = [cfgStats.dirImages, filesep, name4Save, '.xlsx'];
% cfgStats.sheetName = 'LocalVar';
% figure('Name', titNameFig);
% for iComp=1:size(pairComps,1)
%     [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
%     hs(iComp) = subplot(1,size(pairComps,1),iComp);
%     if ~isempty(commonCh)
%         % Local
%         dataComp1 = varPerState{pairComps(iComp,1)}(intersect(indIn1,isLocal{pairComps(iComp,1)}));
%         dataComp2 = varPerState{pairComps(iComp,2)}(intersect(indIn2,isLocal{pairComps(iComp,2)}));
%         legLabel = {[allStates{pairComps(iComp,1)}, ' (',num2str(length(dataComp1)),')'],[allStates{pairComps(iComp,2)},' (',num2str(length(dataComp2)),')']};
%         [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(dataComp1, dataComp2,titNameFig,legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])], cfgStats.dirImages, cfgStats.useParam);
%         pVals.Local.pairedTtest{iComp} = pairedTtest;
%         pVals.Local.pairedTtest{iComp}.legLabel = legLabel;
%         disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ',  ' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
%     end
% end
% 
% % Distant
% titNameFig = ['Comp Distant Variability ', regionName];
% name4Save = regexprep(titNameFig,'\s','');
% cfgStats.xlsFileName = [cfgStats.dirImages, filesep, name4Save, '.xlsx'];
% cfgStats.sheetName = 'DistantVar';
% figure('Name', titNameFig);
% for iComp=1:size(pairComps,1)
%     [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
%     hs(iComp) = subplot(1,size(pairComps,1),iComp);
%     if ~isempty(commonCh)
%         % Local
%         dataComp1 = varPerState{pairComps(iComp,1)}(intersect(indIn1,isDistant{pairComps(iComp,1)}));
%         dataComp2 = varPerState{pairComps(iComp,2)}(intersect(indIn2,isDistant{pairComps(iComp,2)}));
%         legLabel = {[stateNames{pairComps(iComp,1)}, ' (',num2str(length(dataComp1)),')'],[stateNames{pairComps(iComp,2)},' (',num2str(length(dataComp2)),')']};
%         [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(dataComp1, dataComp2,titNameFig,legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])], cfgStats.dirImages, cfgStats.useParam);
%         pVals.Distant.pairedTtest{iComp} = pairedTtest;
%         pVals.Distant.pairedTtest{iComp}.legLabel = legLabel;
%         disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ',  ' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
%     end
% end
% 
% 
