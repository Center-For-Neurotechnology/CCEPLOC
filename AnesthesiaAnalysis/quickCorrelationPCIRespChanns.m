function quickCorrelationPCIRespChanns(PCIFileName, respChFileName, variabilityFileName, dirImages)

regionNames = {'all'}; % all together
if ~isdir(dirImages), mkdir(dirImages);end

%% Load PCI values
stPCI = load(PCIFileName);
regionNamesPCI = stPCI.regionNames;
PCIPerStatePerRegion = stPCI.PCIPerStatePerRegion;
anatRegionsPCI = stPCI.anatRegionsStimChPerState;
stimSitesPerStatePCI = stPCI.stimSitesPerState;

nStates = numel(stPCI.cfgStats.allStates);
nRegions = numel(regionNames);

for iState=1:nStates 
    [stimSitesPerStatePCI{iState}, indUniqueStimCh] = unique(regexprep(stimSitesPerStatePCI{iState},'-',''),'stable');
    anatRegionsPCI{iState} = anatRegionsPCI{iState}(indUniqueStimCh);
    for iRegion=1:length(regionNamesPCI)
        PCIPerStatePerRegion{iState,iRegion} = PCIPerStatePerRegion{iState,iRegion}(indUniqueStimCh);
    end
end



%% Load nResp Channels
stRespCh = load(respChFileName);
nRespPerStatePerRegion = stRespCh.nRespPerStatePerRegion;
anatRegionsResp = stRespCh.anatRegionsStimChPerState;
stimSitesPerStateResp = stRespCh.stimSitesPerState;
regionNamesResp = stRespCh.regionNames;

% we might want to check that the regions and states are the same

%% Load Variability
stVariability = load(variabilityFileName);
for iState=1:nStates
    for iRegion=1:length(stVariability.regionNames)
        
        variabilityPerState{iState} = stVariability.variabilityPerStatePerRegion{iState,  ;
        anatRegionsVar{iState} = stVariability.anatRegionsStimChPerState;
        stimSitesPerStateVar{iState} = stVariability.stimSitesPerState;
        regionNamesVar{iState} = stVariability.regionNames;
    end
end

%% Correlations
allData1=[];
allData2=[];
for iState=1:nStates
        [ind1, ind2, commonStimCh] = strmatchAll(stimSitesPerStatePCI{iState}, stimSitesPerStateResp{iState});
    for iRegion=1:nRegions
        indRegion1 = find(strcmpi(regionNames{iRegion},regionNamesPCI));
        indRegion2 = find(strcmpi(regionNames{iRegion},regionNamesResp));
        data1 = [PCIPerStatePerRegion{iState,indRegion1}(ind1)];
        allData1 = [allData1, data1];
        data2 = [nRespPerStatePerRegion{iState,indRegion2}(ind2)];
        allData2 = [allData2, data2];
        [rxyVal, pVal] = corrcoef(data1, data2);
        rxyPerState{iState,iRegion} = rxyVal(1,2);
        pValRxyPerState{iState,iRegion} = pVal(1,2);
        % plot
        figure; hold on;
        plot(data1, data2,'o')
        if pValRxyPerState{iState,iRegion}<0.05
            b = regress(data2', [ones(length(data2),1) ,data1']);
            lineFit = b(1) + b(2) * data1;
            plot(data1, lineFit)
            legend(['rxy = ',num2str(rxyPerState{iState,iRegion}), ' p=',num2str(pValRxyPerState{iState,iRegion})])
        end
        titName = ['corr PCI vs. nResp ',regionNames{iRegion},' ',stPCI.cfgStats.allStates{iState}];
        title(titName)
        xlabel('PCI')
        ylabel('nResp')
    name4Save = regexprep(titName,'\s','');
    savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
    saveas(gcf, [dirImages,filesep, name4Save,'.png']);
    end
end

%% All together
[rxyVal, pVal] = corrcoef(allData1, allData2);
rxyPerStateAll= rxyVal(1,2);
pValRxyPerStateAll = pVal(1,2);
% plot
figure; hold on;
plot(allData1, allData2,'o')
if pValRxyPerStateAll<0.05
    b = regress(allData2', [ones(length(allData2),1) ,allData1']);
    lineFit = b(1) + b(2) * data1;
    plot(data1, lineFit)
    legend(['rxy = ',num2str(rxyPerStateAll), ' p=',num2str(pValRxyPerStateAll)])
end
titName = ['corr PCI vs. nResp All'];
title(titName)
xlabel('PCI')
ylabel('nResp')
name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'.png']);
