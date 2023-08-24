function pVals = computePooledStatsNotNormalized(meanStatsEEGWakeEMU, meanStatsEEGSleep, meanStatsEEGORWake, meanStatsEEGAnesthesia, whatToCompare, titNameForPlot, cfgStats)

if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end
pVals=[];

%Put data together for the selected timeframe
meanData = [meanStatsEEGWakeEMU.meanVariability.(whatToCompare),meanStatsEEGSleep.meanVariability.(whatToCompare),meanStatsEEGORWake.meanVariability.(whatToCompare),meanStatsEEGAnesthesia.meanVariability.(whatToCompare)];

allChData = {meanStatsEEGWakeEMU.VariabilityPerCh.(whatToCompare),meanStatsEEGSleep.VariabilityPerCh.(whatToCompare),meanStatsEEGORWake.VariabilityPerCh.(whatToCompare),meanStatsEEGAnesthesia.VariabilityPerCh.(whatToCompare)};


% Bar Plot
plotErrorBars(meanData, allChData, titNameForPlot, cfgStats);

% Convert to log data
if cfgStats.useLog
    % already computed log for each time point before averaging
    log10AllChData = allChData;
    log10MeanData = meanData;
else
    for iComp=1:length(meanData)
        log10AllChData{iComp} = log10(allChData{iComp}); % compute Log10
        log10MeanData(iComp) = mean(log10AllChData{iComp});
    end
    % Bar Plot for Log10 data
    cfgStats.ylim = [1 2];
    plotErrorBars([], log10AllChData, [titNameForPlot,'log'], cfgStats);
    cfgStats.ylim = 'auto';
end


% ANOVA
allChDataForANOVA = [log10AllChData{:}];
groupLabels=[];
for iComp=1:length(log10AllChData)
    groupLabels = [groupLabels, repmat(cfgStats.legLabel(iComp),1,length(log10AllChData{iComp}))];
end

[pVals.ANOVA] = computeANOVASaveInXls(allChDataForANOVA, groupLabels, titNameForPlot, cfgStats.xlsFileName, whatToCompare, cfgStats.dirImages);

% Paired stats - 
% if length(cfgStats.bipChWakeEMU)~=length(cfgStats.bipChAnesthesia)
%     disp(['missing Wake-Anesthesia pairs of channels - Comparing ONLY WakeEMU-Sleep & WakeOR-Anesthesia'])
%     pairComps = [1,2;3,4];
%     pairCompsPlot = [3,4];
% else
    pairComps = [1,2;3,4;1,3]; %getPairsChannels(1:length(meanData));    
    pairCompsPlot = pairComps; %[3,4];
% end
% find pairs for sleep - the rest should be ALL
for iComp=1:size(pairComps,1)
    titName = [titNameForPlot,' ',num2str([pairComps(iComp,:)])];
    legLabel=cfgStats.legLabel(pairComps(iComp,:));
    [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
    [pVal, summaryVal1, summaryVal2, testName] = computePairedTtestSaveInXls(log10AllChData{pairComps(iComp,1)}(indIn1),log10AllChData{pairComps(iComp,2)}(indIn2),titName,legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,whatToCompare,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
    pVals.pairedTtest.([legLabel{:}]).pVal = pVal;
    pVals.pairedTtest.([legLabel{:}]).(['summaryVal',legLabel{1}]) = summaryVal1;
    pVals.pairedTtest.([legLabel{:}]).(['summaryVal',legLabel{2}]) = summaryVal2;
    pVals.pairedTtest.([legLabel{:}]).testName = testName;
end

% Plot one vs the other
plotWakeVsAnesthesiaPerCh(log10MeanData, log10AllChData, titNameForPlot, cfgStats, pairCompsPlot);

