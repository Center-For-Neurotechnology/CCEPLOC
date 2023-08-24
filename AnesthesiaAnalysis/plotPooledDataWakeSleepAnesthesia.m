function plotPooledDataWakeSleepAnesthesia(allData, allIndTrialPerCh, cfgStats)
%allData = {allDataWake,allDataSleep,allDataORWake,allDataAnesthesia};
%allIndTrialPerCh={indTrialWakePerCh,indTrialSleepPerCh,indTrialORWakePerCh,indTrialAnesthesiaPerCh};
cfgInfoPlot = cfgStats;
cfgInfoPlot.xlimZoomMiliSec = [-25 600];
cfgInfoPlot.xTimeForYlim = [3 100]/1000; % in seconds

% Organize in channels
nComparisons = length(allData);
chNames = unique([cfgStats.bipolarChannels{:}]);
nChannels=length(chNames);
% Reorganize per channel to plot each channel separately
allDataPerCh = cell(1,nChannels);
dirImages = cell(1,nChannels);
%chNamesPerComp = cell(1,nChannels);
for iCh=1:nChannels
    allDataPerCh{iCh} = cell(1,nComparisons);
 %   chNamesPerComp{iCh} = cell(1,nComparisons);
     nCompPerCh=0;
    for iComp=1:nComparisons
        indSelChName = find(strncmpi(cfgStats.bipolarChannels{iComp}, chNames{iCh},length(chNames{iCh})));
        if ~isempty(indSelChName)
            indChInComp = find(allIndTrialPerCh{iComp}==indSelChName);
            allDataPerCh{iCh}{iComp} =  allData{iComp}(:,indChInComp);
           % chNamesPerComp{iCh}{iComp} = chNames{iCh};
           nCompPerCh = nCompPerCh+1;
        end
    end
    dirImages{iCh} = [cfgInfoPlot.dirImages,'perCh_',num2str(nCompPerCh),'comp'];
end

%Plot together per channel
parfor iCh=1:nChannels
    %Compute mean/std etc.
    chName = chNames{iCh};
    plotTogetherWakeSleepAnesthesia(allDataPerCh{iCh}, chName, cfgInfoPlot,dirImages{iCh});
    close all;
end
