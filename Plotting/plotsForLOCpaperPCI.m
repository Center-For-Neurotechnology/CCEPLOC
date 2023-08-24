function plotsForLOCpaperPCI(dirGralResults)
 
regionNames = {'all'}; % NOT implemented:, 'anterior', 'posterior', 'temporal'};
nPatients= 20;
posFixDir = '_Neuron2023'; %'_LP_CCEP'; %'_noSTIM'; %'_LP_CCEP2'; %'_raw'; %'_ALPHA';

dirImages = [dirGralResults, filesep, 'plotsLOCpaper',posFixDir,filesep,'imagesPCI'];

PCIFileName = [dirGralResults, filesep, 'PCIResults', filesep, 'PERTRIALnonSOZ','t0-600',posFixDir,filesep,'PCIStimCh',filesep,'PCIPerRegion_PCI StimCh',num2str(nPatients),'pat.mat'];
 
if ~isdir(dirImages), mkdir(dirImages);end

%% 20 different colors...
posColors = {'#e6194b', '#3cb44b', '#ffe119', '#4363d8', '#f58231', '#911eb4', '#46f0f0', '#f032e6', '#bcf60c', '#fabebe', '#008080', ...
             '#e6beff', '#9a6324', '#fffac8', '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000075', '#808080'};
         
%'#e6194B', '#3cb44b', '#ffe119', '#4363d8', '#f58231', '#911eb4', '#42d4f4', '#f032e6', '#bfef45', '#fabed4', '#469990', '#dcbeff', '#9A6324', '#fffac8', '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000075', '#a9a9a9', '#ffffff', '#000000'

%% Figure 1 - PCI
indRegion = 1; % USE ALL!
markerPerState ={'s','^','s','o'};
colorPerState ={'b','m','g','r'};

stPCI = load(PCIFileName);
pNamesPerState = stPCI.pNamesPerState;
pNamesMaxPCIperState = stPCI.pNamesMaxPCI;
PCIPerStatePerRegion = stPCI.PCIPerStatePerRegion;
maxPCIperPat = stPCI.maxPCIperPat;
cfgStats = stPCI.cfgStats;
allStates = cfgStats.allStates;
pNames = unique([pNamesPerState{:}]);
nPatients = length(pNames);
nStates = length(allStates);
maxPCIAllPat = NaN(nPatients,nStates);
% per patient PCI
titName = ['PCI per patient N ',num2str(nPatients),' ',regionNames{indRegion}];

scrsz = get(groot,'ScreenSize');
figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)/2]);
hold on;
for iP=1:nPatients
   for iState=1:nStates
       indPerPatMax = find(strcmpi(pNamesMaxPCIperState{iState}, pNames{iP}));
       indPerPat = find(strcmpi(pNamesPerState{iState}, pNames{iP}));
       if ~isempty(indPerPat)
           PCIperPat = PCIPerStatePerRegion{iState, indRegion}(indPerPat);
          % maxPCIperPat(iP,iState) = max(PCIperPat);
            maxPCIAllPat(iP,iState) = maxPCIperPat{iState}(indPerPatMax);
            
           % plot
           plot(repmat(iP,length(PCIperPat),1), PCIperPat, [markerPerState{iState},colorPerState{iState}],'MarkerSize',20)%+0.1*iState
           hMax(iState) = plot(iP, maxPCIAllPat(iP,iState), [markerPerState{iState},colorPerState{iState}],'MarkerSize',30,'MarkerFaceColor',colorPerState{iState});
       end
   end  
end
xlim([0 nPatients+1])
xticks(1:nPatients)
xticklabels(pNames)
xlabel('Participant')
ylabel('PCI')
legend(hMax, allStates);
title(titName)

name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'2.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'2.png']);
saveas(gcf, [dirImages,filesep, name4Save,'2.svg']);

%% PLot MaxValues
pNumber = strcat('p',cellfun(@num2str, num2cell(1:nPatients), 'UniformOutput', false));

titName = ['Max PCI per patient N ',num2str(nPatients),' ',regionNames{indRegion}];
cfgStats.sheetName ='MaxPCI';
for iComp=1:size(stPCI.pairComps,1)
    % PCI per region
    cfgStats.sheetName ='MaxPCI';
    legLabel= strcat(cfgStats.legLabel(stPCI.pairComps(iComp,:)),[' (', num2str(sum(sum(~isnan(maxPCIAllPat(:,stPCI.pairComps(iComp,:))),2)>=2)),')']);
    [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(maxPCIAllPat(:,stPCI.pairComps(iComp,1)),maxPCIAllPat(:,stPCI.pairComps(iComp,2)),[titName,' ',allStates{stPCI.pairComps(iComp,:)}],legLabel,[],[], dirImages,cfgStats.useParam);
    disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', cfgStats.anatRegionFor,' ',regionNames{indRegion}, ' - pVal= ', num2str(pairedTtest),...
        ' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' m1>m2=',num2str(sum(maxPCIAllPat(:,stPCI.pairComps(iComp,1))>maxPCIAllPat(:,stPCI.pairComps(iComp,2)))),' N= ',num2str(sum(sum(~isnan(maxPCIAllPat(:,stPCI.pairComps(iComp,:))),2)>=2))])
end


figure('Name', titName);
colororder(posColors)
subplot(1,2,1)
plot(maxPCIAllPat(:,[1,2])','-o','MarkerSize',10,'MarkerFaceColor','auto')
xticks(1:2)
xticklabels(allStates([1,2]))
xlim([0.5 2+0.5])
ylabel('Max PCI')
ylim([0 125])%max(maxPCIAllPat(:))
legend(pNumber,'Location','eastoutside')
subplot(1,2,2)
plot(maxPCIAllPat(:,[3,4])','-o','MarkerSize',10,'MarkerFaceColor','auto')
xticks(1:2)
xticklabels(allStates([3,4]))
xlim([0.5 2+0.5])
ylabel('Max PCI')
ylim([0 125])
legend(pNames,'Location','eastoutside')
%legend(pNumber,'Location','eastoutside')
name4Save = regexprep(titName,'\s','');
savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
saveas(gcf, [dirImages,filesep, name4Save,'.png']);
saveas(gcf, [dirImages,filesep, name4Save,'.svg']);

