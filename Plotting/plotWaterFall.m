function plotWaterFall(EEGtoPlotPerCh, timePerTrialSec, chName, titName, dirImages, cfgInfoPlot)

%plot waterfall of stimData.
% axes are: time , trial, amplitude

%cfgInfoPlot contains the following fields: maxAmpVal, minAmpVal, ampUnits, indXTimeForYlim, xlimZoomSec
if isempty(EEGtoPlotPerCh) || size(EEGtoPlotPerCh,2)<2
    disp(['Nothing to Plot - ',titName])
    return
end

if ~exist(dirImages,'dir'), mkdir(dirImages); end

nStim = size(EEGtoPlotPerCh,2);
[X, Y] = meshgrid(timePerTrialSec, 1:nStim);
titNameForPlot = ['EEG ', ' Rec Channel ', chName, ' ', titName];
figure('Name', titNameForPlot);
CVal = repmat(1:nStim,length(timePerTrialSec),1)'; %EEGtoPlot{iCh}'; %gradient(EEGtoPlot{iCh}');
%CVal(CVal>cfgInfoPlot.maxAmpVal)= cfgInfoPlot.maxAmpVal;
%CVal(CVal<cfgInfoPlot.minAmpVal)= cfgInfoPlot.minAmpVal;

% Use meshz with MeshStyle=Row to create waterfall plot
% colormap corresponds to stim # (could be changed to amplitude)

hMesh = meshz(X, Y, EEGtoPlotPerCh',CVal);
hMesh.CData(end-1,:) = hMesh.CData(end-2,:); % BAD HACK: LAST 2 stim trials are the same color! (before the last one was getting the mean value)
hMesh.MeshStyle = 'Row';
hMesh.FaceAlpha = 0;
title(titNameForPlot);
if ~isempty(cfgInfoPlot)
    xlim(cfgInfoPlot.xlimZoomMiliSec)
    eegForLims = EEGtoPlotPerCh(cfgInfoPlot.indXTimeForYlim(1):cfgInfoPlot.indXTimeForYlim(2),:);
    zlim ([min(eegForLims(:)) max(eegForLims(:))]);
end
set(gca,'View',[10 25])
xlabel('Time(ms)');
ylabel('Stim #');
if ~isempty(cfgInfoPlot)
    zlabel(cfgInfoPlot.ampUnits);
end
colorbar;
%Save figure
titNameForFile = ['Wfall_',regexprep(titNameForPlot,'\W','_')];
saveas(gcf,[dirImages, filesep,titNameForFile,'.png']);
savefig(gcf,[dirImages, filesep,titNameForFile,'.fig'],'compact');

% Change view to XZ and save as .png
set(gca,'View',[0 0])
saveas(gcf,[dirImages, filesep,titNameForFile,'_XZ.png']);
