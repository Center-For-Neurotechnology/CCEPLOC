function plotTogetherWakeSleepAnesthesia(EEGtoPlotPerCh, chName, cfgInfoPlot, dirImages)

if ~exist('dirImages','var'), dirImages = cfgInfoPlot.dirImages; end

cfgInfoPlot.indXTimeForYlim = cfgInfoPlot.xTimeForYlim * cfgInfoPlot.Fs + cfgInfoPlot.timeOfStimSamples;
timePerTrialmiliSec = cfgInfoPlot.timePerTrialSec *1000;

allEEGPerCh = [EEGtoPlotPerCh{:}];
eegForLims = allEEGPerCh(cfgInfoPlot.indXTimeForYlim(1):cfgInfoPlot.indXTimeForYlim(2),:);
yLimVal = [min(eegForLims(:)) max(eegForLims(:))];
titNameForPlot = [cfgInfoPlot.titName, ' CCEP'];
titNameForFile = regexprep(titNameForPlot,'\W','_');

plotNComparisons(EEGtoPlotPerCh, timePerTrialmiliSec, chName, dirImages, titNameForPlot, titNameForFile, cfgInfoPlot.xlimZoomMiliSec, yLimVal, cfgInfoPlot.legLabel);

