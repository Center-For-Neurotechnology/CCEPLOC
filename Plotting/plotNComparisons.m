function plotNComparisons(allStimTrials, tBeforeAfterStim, chName, dirImages, titNameFig, titNameFile, xLimVal, yLimVal, legLabel)
% titNameFile = 'rndDetFeat_',titName;
% titNameFig = 'Random vs Det Stim vs. Det NO Stim Features' 
% allStimTrials is a cell with comparison's data in each cell

nComparisons = length(allStimTrials);

if ~exist('xLimVal','var'), xLimVal=[];end
if ~exist('yLimVal','var'), yLimVal=[];end
colorsPerComp = {'b','m','g','r','c','k'};
    
%Plot

meanStim=cell(1,nComparisons);
nStim=cell(1,nComparisons);
for iComp=1:nComparisons
    [meanStim{iComp}, q05Stim{iComp}, q95Stim{iComp}, stdStim{iComp}, stdErrorStim{iComp},medianStim{iComp}]= meanQuantiles(allStimTrials{iComp}, 2);
    nStim{iComp} = size(allStimTrials{iComp},2);
end
minMeanStim = min(min([meanStim{:}]));
maxMeanStim = max(max([meanStim{:}]));

%Plot mean comparison
legendStr=[];
figure('Name',[ chName, ' ',titNameFig]);
subplot(2,1,1)
hold on;
hds=[];
for iComp=1:nComparisons
    if ~isempty(medianStim{iComp})
       hComp = plot(tBeforeAfterStim, medianStim{iComp},'Color',colorsPerComp{iComp},'LineWidth',2);
       hds = [hds, hComp];
       legendStr = [legendStr,{strcat(legLabel{iComp},' (',num2str(nStim{iComp}),')')}];
    end
end
line([0, 0], [minMeanStim maxMeanStim], 'Color',[1 0.5 0],'LineWidth',1)
title([chName,' ', titNameFig])
%ylabel('uV')
xlabel('Time')
if ~isempty(yLimVal) && ~any(isnan(yLimVal)), ylim(yLimVal);end
% ylim([quantile([medEEGDetStim;medEEGRandStim;medEEGDetNoStim], 0.01) quantile([medEEGDetStim;medEEGRandStim;medEEGDetNoStim], 0.99)]) %quantile instead of 1 to avoid stim artifact
legend(hds,legendStr,'Location', 'best'); % {['Random Stim (',num2str(nRandomStim),')'], ['Detect Stim (',num2str(nStim),')'], ['Detect NO Stim (',num2str(nDetNoStim),')']},'Location', 'best')
%saveFigToExt(gcf,dirImages, [titNameFile,'_ch',chName],'png');
%saveFigToExt(gcf,dirImages, [titNameFile,'_ch',chName],'fig');
% if ~isempty(xLimVal) % we are already saving the zoomed version with shade
%     xlim(xLimVal);
%     saveFigToExt(gcf,dirImages, [titNameFile,'_ch',chName,'_zoom'],'png');
% end

% Plot mean + std as shade
%figure('Name',[chName, ' ', titNameFig]);
subplot(2,1,2) % let's reduce number of figures
hold on;
for iComp=1:nComparisons
    if ~isempty(meanStim{iComp})
        shadedErrorBar(tBeforeAfterStim,allStimTrials{iComp}',{@mean,@std},'lineprops',['-',colorsPerComp{iComp}],'patchSaturation',0.2);
    end
end
hds=[];
for iComp=1:nComparisons % plot mean after to have it on top of shade
    if ~isempty(meanStim{iComp})
        hComp = plot(tBeforeAfterStim, meanStim{iComp},'Color',colorsPerComp{iComp},'LineWidth',2);
       hds = [hds, hComp];
    end
end
line([0, 0], [minMeanStim maxMeanStim], 'Color',[1 0.5 0],'LineWidth',1)
title([chName, ' ', titNameFig])
%ylabel('uV')
xlabel('Time')
%legend(hds,legendStr,'Location', 'best'); % {['Random Stim (',num2str(nRandomStim),')'], ['Detect Stim (',num2str(nStim),')'], ['Detect NO Stim (',num2str(nDetNoStim),')']},'Location', 'best')
if ~isempty(xLimVal), xlim(xLimVal);end
if ~isempty(yLimVal) && ~any(isnan(yLimVal)), ylim(yLimVal);end
saveFigToExt(gcf,dirImages, [titNameFile,'_all_ch',chName],'png');
saveFigToExt(gcf,dirImages, [titNameFile,'_all_ch',chName],'fig');
saveFigToExt(gcf,dirImages, [titNameFile,'_all_ch',chName],'svg');

