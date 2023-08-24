function plotsForLOCpaperDensity(densityPerState,dirImages, cfgStats)
 
regionNames = {'all'}; % NOT implemented:, 'anterior', 'posterior', 'temporal'};
posFixDir = '_Neuron2023'; %'_LP_CCEP'; %'_noSTIM'; %'_LP_CCEP2'; %'_raw'; %'_ALPHA';

%dirImages = [dirGralResults, filesep, 'plotsLOCpaper',posFixDir,filesep,'imagesCentrality'];
 
if ~isdir(dirImages), mkdir(dirImages);end

%% 20 different colors...
posColors = {'#e6194b', '#3cb44b', '#ffe119', '#4363d8', '#f58231', '#911eb4', '#46f0f0', '#f032e6', '#bcf60c', '#fabebe', '#008080', ...
             '#e6beff', '#9a6324', '#fffac8', '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000075', '#808080'};
         
%'#e6194B', '#3cb44b', '#ffe119', '#4363d8', '#f58231', '#911eb4', '#42d4f4', '#f032e6', '#bfef45', '#fabed4', '#469990', '#dcbeff', '#9A6324', '#fffac8', '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000075', '#a9a9a9', '#ffffff', '#000000'


%% Figure 1 - Dens
indRegion = 1; % USE ALL!
markerPerState ={'s','^','o'};
colorPerState ={'b','m','r'};
pairComps = cfgStats.pairComps;
allStates = cfgStats.allStates;
pNames = cfgStats.pNames;
nPatients = length(pNames);
nComp = length(densityPerState);
DensityAllPat = NaN(nPatients,nComp);
maxVal= max(max([densityPerState{:}]));
minVal= min(min([densityPerState{:}]));

% per patient Dens
scrsz = get(groot,'ScreenSize');
    titName = ['Density per patient ', ' ',regionNames{indRegion}];
figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)/2]);
for iComp=1:nComp
    compNames{iComp}= [allStates{pairComps(iComp,:)}];
    titNameComp = ['Density per patient ', compNames{iComp},' ',regionNames{indRegion}];
    subplot(nComp,1,iComp)
    % plot
    plot(1:nPatients, densityPerState{iComp}, [markerPerState{iComp}],'MarkerSize',20);
    title(titNameComp)
    ylabel('Density')
    ylim([minVal maxVal])
    legend(allStates(pairComps(iComp,:)));
    xlim([0 nPatients+1])
    
end
  
%xticklabels(pNames)
xticks(1:nPatients)
xlabel('Participant')

name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'.png']);
saveas(gcf, [dirImages,filesep, name4Save,'.svg']);
%% Compare Values
pNumber = strcat('p',cellfun(@num2str, num2cell(1:nPatients), 'UniformOutput', false));

titName = ['Density per patient N ',num2str(nPatients),' ',regionNames{indRegion}];
cfgStats.sheetName ='Density';
for iComp=1:nComp
    % Dens per region
    cfgStats.sheetName =['Density',compNames{iComp}];
    legLabel= strcat(allStates(pairComps(iComp,:)),[' (', num2str(sum(sum(~isnan(densityPerState{iComp}'),2)>=2)),')']);
    [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(densityPerState{iComp}(1,:)',densityPerState{iComp}(2,:)',['Density ',compNames{iComp}],legLabel,[],[], dirImages,cfgStats.useParam);
    disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ',regionNames{indRegion}, ' - pVal= ', num2str(pairedTtest),...
        ' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' m1>m2=',num2str(sum(densityPerState{iComp}(1,:)>densityPerState{iComp}(2,:))),' N= ',num2str(sum(sum(~isnan(densityPerState{iComp}'),2)>=2))])
end

%% Plot XY
figure('Name', titName);
colororder(posColors)
subplot(1,2,1)
plot(densityPerState{2},'-o','MarkerSize',10,'MarkerFaceColor','auto')
xticks(1:2)
xticklabels(allStates([1,2]))
xlim([0.5 2+0.5])
ylabel('Density')
ylim([0 0.02])%max(DensityAllPat(:))
legend(pNumber,'Location','eastoutside')
subplot(1,2,2)
plot(densityPerState{3},'-o','MarkerSize',10,'MarkerFaceColor','auto')
xticks(1:2)
xticklabels(allStates([3,4]))
xlim([0.5 2+0.5])
ylabel('Density')
ylim([0 0.02])
%legend(pNames,'Location','eastoutside')
legend(pNumber,'Location','eastoutside')
name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'.png']);
saveas(gcf, [dirImages,filesep, name4Save,'.svg']);

