function plotErrorBars(meanData, allChDataForErrorBars, titNameForPlot, cfgStats)


if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end
%log 10
%log10MeanData = log10(meanData);

%compute error bars
if iscell(allChDataForErrorBars)
    errLow = [];
    errHigh = [];
    for iComp=1:length(allChDataForErrorBars)
        [meanVal(iComp), q25, q75, stdVal, stdErrorVal,medianVal]= meanQuantiles(allChDataForErrorBars{iComp},2); % per channel
        errLow(iComp) = stdErrorVal; %q25;
        errHigh(iComp) = stdErrorVal;% q75;
    end
    
else % assume that limits are provided as values to use (q25 and q75
    errLow = allChDataForErrorBars(1,:);
    errHigh = allChDataForErrorBars(2,:);
end
if isempty(meanData)
    meanData = meanVal;
end
%Plot
figure('Name', titNameForPlot);
hold on;
bar(meanData)
title(titNameForPlot)
%xlabel('log10 mean STD - 0:equal')

er = errorbar(1:length(meanData),meanData,errLow,errHigh);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
xticks(1:length(meanData));
xticklabels(cfgStats.legLabel);
if isfield(cfgStats, 'ylabel'), ylabel(cfgStats.ylabel);end
if isfield(cfgStats, 'ylim'), ylim(cfgStats.ylim);end

%Save figure
titNameForFile = ['Bar_',regexprep(titNameForPlot,'\W','_')];
saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.png']);
savefig(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.fig'],'compact');

