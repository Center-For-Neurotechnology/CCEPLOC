function pVals = computePooledStats(meanStatsEEGWake, meanStatsEEGSleep, meanStatsEEGORWake, meanStatsEEGAnesthesia, whatToCompare, titNameForPlot, cfgStats)

if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end
pVals=[];
switch upper(whatToCompare)
    case 'N1'
    meanData = [meanStatsEEGWake.meanNormVariabilityN1,meanStatsEEGSleep.meanNormVariabilityN1,meanStatsEEGORWake.meanNormVariabilityN1,meanStatsEEGAnesthesia.meanNormVariabilityN1];
    allChData = {meanStatsEEGWake.normVariabilityN1PerCh,meanStatsEEGSleep.normVariabilityN1PerCh,meanStatsEEGORWake.normVariabilityN1PerCh,meanStatsEEGAnesthesia.normVariabilityN1PerCh};

     case 'N2'
    meanData = [meanStatsEEGWake.meanNormVariabilityN2,meanStatsEEGSleep.meanNormVariabilityN2,meanStatsEEGORWake.meanNormVariabilityN2,meanStatsEEGAnesthesia.meanNormVariabilityN2];
    allChData = {meanStatsEEGWake.normVariabilityN2PerCh,meanStatsEEGSleep.normVariabilityN2PerCh,meanStatsEEGORWake.normVariabilityN2PerCh,meanStatsEEGAnesthesia.normVariabilityN2PerCh};
   
      case 'LONG'
    meanData = [meanStatsEEGWake.meanNormVariabilityLong,meanStatsEEGSleep.meanNormVariabilityLong,meanStatsEEGORWake.meanNormVariabilityLong,meanStatsEEGAnesthesia.meanNormVariabilityLong];
    allChData = {meanStatsEEGWake.normVariabilityLongPerCh,meanStatsEEGSleep.normVariabilityLongPerCh,meanStatsEEGORWake.normVariabilityLongPerCh,meanStatsEEGAnesthesia.normVariabilityLongPerCh};
   
end

% Bar Plot
plotErrorBars(meanData, allChData, titNameForPlot, cfgStats);

% Convert to log data
for iComp=1:length(meanData)
    log10AllChData{iComp} = log10(allChData{iComp});
end
log10MeanData = log10(meanData);

% ANOVA
allChDataForANOVA = [log10AllChData{:}];
groupLabels=[];
for iComp=1:length(log10AllChData)
    groupLabels = [groupLabels, repmat(cfgStats.legLabel(iComp),1,length(log10AllChData{iComp}))];
end
[pVals.ANOVA] = computeANOVASaveInXls(allChDataForANOVA, groupLabels, titNameForPlot, cfgStats.xlsFileName, whatToCompare, cfgStats.dirImages);

% Paired stats - 
if sum(strcmp(cfgStats.bipChAnesthesia,cfgStats.bipChWake))<length(cfgStats.bipChAnesthesia)
    disp(['missing Wake-Anesthesia pairs of channels'])
end
pairComps = getPairsChannels(1:length(meanData));
% find pairs for sleep - the rest should be ALL
for iComp=1:size(pairComps,1)
    titName = [titNameForPlot,' ',num2str([pairComps(iComp,:)])];
    legLabel=cfgStats.legLabel(pairComps(iComp,:));
    [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});

    [pVals.pairedTtest] = computePairedTtestSaveInXls(log10AllChData{pairComps(iComp,1)}(indIn1),log10AllChData{pairComps(iComp,2)}(indIn2),titName,legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,whatToCompare,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
end

% Plot one vs the other
plotWakeVsAnesthesiaPerCh(log10MeanData, log10AllChData, titNameForPlot, cfgStats);

