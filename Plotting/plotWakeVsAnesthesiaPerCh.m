function plotWakeVsAnesthesiaPerCh(summaryData, allChData, titNameForPlot, cfgStats, pairComps)


if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end
if ~exist('pairComps','var') || isempty(pairComps), pairComps = [1,3;1,4;3,4]; end
%compute error bars
meanVal=zeros(1,length(allChData));
medianVal=zeros(1,length(allChData));
errLow=zeros(1,length(allChData));
errHigh=zeros(1,length(allChData));
for iComp=1:length(allChData)
    if ~isempty(allChData{iComp})
        [meanVal(iComp), q25, q75, stdVal, stdErrorVal,medianVal(iComp)]= meanQuantiles(allChData{iComp},2); % per channel
        errLow(iComp) = q25;
        errHigh(iComp) = q75;
        % convert to log10
        %    log10AllChData{iComp} = log10(allChData{iComp});
        %    log10MeanData = log10(meanData);
    end
end
if isempty(summaryData)
    summaryData=medianVal;
end

%Find corresponding channels for sleep
%Plot
maxData = max([allChData{:}]);
minData = min([allChData{:}]);
if minData==maxData, minData = maxData-1; end % ad hoc to solve issue of scale

figure('Name', titNameForPlot);
for iComp=1:size(pairComps,1)
    [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
    hs(iComp) = subplot(1,size(pairComps,1),iComp);
    if ~isempty(commonCh)
        hold on;
        plot([allChData{pairComps(iComp,1)}(indIn1);allChData{pairComps(iComp,2)}(indIn2)])
        plot(summaryData(pairComps(iComp,:)),'k-s','LineWidth',4)
        xticks([1,2])
        xticklabels(strcat(cfgStats.legLabel(pairComps(iComp,:)), ' (',{num2str(length(indIn1)),num2str(length(indIn2))},')'))
        ylim([minData maxData])
        legend(regexprep(commonCh,'_',' '))
        legend('off') % don't show but keep info
    end
end
if isfield(cfgStats,'ylabel') && ~isempty(cfgStats.ylabel)
    ylabel(hs(1), cfgStats.ylabel)
else
      ylabel(hs(1), [' log10 mean STD',' 0:equal']);
end  

%Save figure
titNameForFile = ['XYPlot_',regexprep(titNameForPlot,'\W','_')];
saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.png']);
saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.svg']);
savefig(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.fig'],'compact');

