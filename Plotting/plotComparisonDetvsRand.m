function plotComparisonDetvsRand(detStimTrials, randomStimTrials, detNoStimTrials, tBeforeAfterStim, tBeforeStimUsedInDet, chNames, dirImages, titNameFig, titNameFile,thresholdperDet,xLimVal, yLimVal)
% titNameFile = 'rndDetFeat_',titName;
% titNameFig = 'Random vs Det Stim vs. Det NO Stim Features' 

nChannels = length(chNames);
if isempty(detNoStimTrials),detNoStimTrials=cell(nChannels,1);end
if ~exist('xLimVal','var'), xLimVal=[];end
if ~exist('yLimVal','var'), yLimVal=[];end

%Plot  
for iCh=1:nChannels
    chName = chNames{iCh};
    [meanDetStim, q05DetStim, q95DetStim, stdDetStim, stdErrorDetStim,medianDetStim]= meanQuantiles(detStimTrials{iCh}, 2);
    [meanRandStim, q05RandStim, q95RandStim, stdRandStim, stdErrorRandStim,medianRandStim]= meanQuantiles(randomStimTrials{iCh}, 2);
    [meanDetNoStim, q05DetNoStim, q95DetNoStim, stdDetNoStim, stdErrorDetNoStim, medianDetNoStim]= meanQuantiles(detNoStimTrials{iCh}, 2);
    nDetStim = size(detStimTrials{iCh},2);
    nRandomStim = size(randomStimTrials{iCh},2);
    nDetNoStim = size(detNoStimTrials{iCh},2);
    
    %Plot
    figure('Name',[titNameFig, ' Channel ', chName]);
    hold on;
    plot(tBeforeAfterStim, medianRandStim,'c','LineWidth',2)
    plot(tBeforeAfterStim, medianDetStim,'r','LineWidth',2)
    if ~isempty(medianDetNoStim), plot(tBeforeAfterStim, medianDetNoStim,'g','LineWidth',2); end
    line([0, 0], [min([meanDetStim;meanRandStim]) max([meanDetStim;meanRandStim])], 'Color',[1 0.5 0],'LineWidth',1)
    if ~isempty(tBeforeStimUsedInDet), line([-tBeforeStimUsedInDet, -tBeforeStimUsedInDet], [min([meanDetStim;meanRandStim]) max([meanDetStim;meanRandStim])], 'Color',[0.5 0.5 0],'LineWidth',1); end
    if ~isempty(thresholdperDet),line([tBeforeAfterStim(1) tBeforeAfterStim(end)],[thresholdperDet{1}(end,end) thresholdperDet{1}(end,end)], 'Color',[0.75 0.75 0.75],'LineWidth',0.5,'LineStyle','--');end
    title([titNameFig,' Ch: ', chName])
    %ylabel('uV')
    xlabel('Time')
    if ~isempty(xLimVal), xlim(xLimVal);end
    if ~isempty(yLimVal), ylim(yLimVal);end
    % ylim([quantile([medEEGDetStim;medEEGRandStim;medEEGDetNoStim], 0.01) quantile([medEEGDetStim;medEEGRandStim;medEEGDetNoStim], 0.99)]) %quantile instead of 1 to avoid stim artifact
    legend({['Random Stim (',num2str(nRandomStim),')'], ['Detect Stim (',num2str(nDetStim),')'], ['Detect NO Stim (',num2str(nDetNoStim),')']},'Location', 'best')
    saveFigToExt(gcf,dirImages, [titNameFile,'_ch',chName],'png');
    saveFigToExt(gcf,dirImages, [titNameFile,'_ch',chName],'fig');
    
end

%Plot  
for iCh=1:nChannels
    chName = chNames{iCh};
    [meanDetStim, q25DetStim, q75DetStim, stdDetStim, stdErrorDetStim, medianDetStim]= meanQuantiles(detStimTrials{iCh}, 2);
    [meanRandStim, q25RandStim, q75RandStim, stdRandStim, stdErrorRandStim, medianRandStim]= meanQuantiles(randomStimTrials{iCh}, 2);
    [meanDetNoStim, q25DetNoStim, q75DetNoStim, stdDetNoStim, stdErrorDetNoStim, medianDetNoStim]= meanQuantiles(detNoStimTrials{iCh}, 2);
    nDetStim = size(detStimTrials{iCh},2);
    nRandomStim = size(randomStimTrials{iCh},2);
    nDetNoStim = size(detNoStimTrials{iCh},2);
    
    %Plot
    figure('Name',[titNameFig, ' Channel ', chName]);
    hold on;
    if size(detNoStimTrials{iCh},2)>1,shadedErrorBar(tBeforeAfterStim,detNoStimTrials{iCh}',{@mean,@std},'lineprops','-g','patchSaturation',0.5); end
    shadedErrorBar(tBeforeAfterStim,randomStimTrials{iCh}',{@mean,@std},'lineprops','-c','patchSaturation',0.5); 
    shadedErrorBar(tBeforeAfterStim,detStimTrials{iCh}',{@mean,@std},'lineprops','-r','patchSaturation',0.5); 

    if ~isempty(meanDetNoStim), hdns=plot(tBeforeAfterStim, meanDetNoStim,'g','LineWidth',2); end
    hrs = plot(tBeforeAfterStim, meanRandStim,'c','LineWidth',2);
    hds = plot(tBeforeAfterStim, meanDetStim,'r','LineWidth',2);

    line([0, 0], [min([q25DetStim;q25RandStim]) max([q75DetStim;q75RandStim])], 'Color',[1 0.5 0],'LineWidth',2)
    if ~isempty(tBeforeStimUsedInDet), line([-tBeforeStimUsedInDet, -tBeforeStimUsedInDet], [min([q25DetStim;q25RandStim]) max([q75DetStim;q75RandStim])], 'Color',[0.5 0.5 0],'LineWidth',2);end
    if ~isempty(thresholdperDet), line([tBeforeAfterStim(1) tBeforeAfterStim(end)],[thresholdperDet{1}(end,end) thresholdperDet{1}(end,end)], 'Color',[0.75 0.75 0.75],'LineWidth',0.5,'LineStyle','--'); end
    title([titNameFig,' Ch: ', chName])
    %ylabel('uV')
    xlabel('Time')
    % ylim([quantile([medEEGDetStim;medEEGRandStim;medEEGDetNoStim], 0.01) quantile([medEEGDetStim;medEEGRandStim;medEEGDetNoStim], 0.99)]) %quantile instead of 1 to avoid stim artifact
    legend([hrs,hds],{['Random Stim (',num2str(nRandomStim),')'], ['Detect Stim (',num2str(nDetStim),')']},'Location', 'southeast'); 
    if ~isempty(meanDetNoStim),legend([hrs,hds,hdns],{['Random Stim (',num2str(nRandomStim),')'], ['Detect Stim (',num2str(nDetStim),')'], ['Detect NO Stim (',num2str(nDetNoStim),')']},'Location', 'best'); end
    if ~isempty(xLimVal), xlim(xLimVal);end
    if ~isempty(yLimVal), ylim(yLimVal);end
    saveFigToExt(gcf,dirImages, [titNameFile,'_all_ch',chName],'png');
    saveFigToExt(gcf,dirImages, [titNameFile,'_all_ch',chName],'fig');
    
end
