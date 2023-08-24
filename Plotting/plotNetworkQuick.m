function [dirImageComplete, titNameComplete] = plotNetworkQuick(EEGStimTrialMATfile, channInfo, dirImages, titName, whatToUse)

%% CONFIG
cfgInfoPlot.xlimZoomMiliSec = [-10 250];
cfgInfoPlot.xTimeForYlim = [3 100]/1000; % in seconds


%cfgInfoPlot.myColorOrder = zeros(50,3);
%cfgInfoPlot.myColorOrder(:,1) = (50:-1:1)/50;

cfgInfoPlot.numbToAverage =10; % to compare first 10 and last 10

%% LOAD data from MAT file
% (saved on AnesthesiaAnalysisFromAINP.m) 

stData = load(EEGStimTrialMATfile);
timePerTrialmiliSec = 1000*stData.timePerTrialSec;
stimSiteNames = stData.stimSiteNames;
chNamesSelected = stData.chNamesSelected;
tBeforeStimSec = stData.tBeforeStimSec;
tAfterStimSec = stData.tAfterStimSec;
Fs = stData.hdr.Fs;
useBipolar = stData.useBipolar;

%% Find WHICH stimulation channel is the one in this file
indStim = find(strcmpi(stimSiteNames{1},channInfo.stimChNames(1,:)));

%% File / Directory checking 
titNameForFile = regexprep(titName,'\W','_');
dirImageComplete = [dirImages,filesep,titNameForFile]; % Plot all in same directory - to get a single PPT before: ,'_',stimSiteNames{1},'-',stimSiteNames{2}];
if ~exist(dirImageComplete,'dir'), mkdir(dirImageComplete); end
titNameComplete = [titName,' ',whatToUse,' ',stimSiteNames{1},'-',stimSiteNames{2}];

%% Select specified channels if exist
if useBipolar
    chNamesForPlotInput = channInfo.recBipolarChPerStim{indStim};
else
    chNamesForPlotInput = channInfo.recReferentialChPerStim{indStim};
end
  
iChSel=1;
chNamesForPlot=cell(1,0);
indSelCh=[];
for iCh=1:numel(chNamesForPlotInput)
    indChFound = find(strcmpi(chNamesForPlotInput{iCh},chNamesSelected));
    if ~isempty(indChFound)
        indSelCh(iChSel) = indChFound;
        chNamesForPlot{iChSel} = chNamesForPlotInput{iCh};
        iChSel =iChSel+1;
    end
end
if isempty(chNamesForPlot)
    disp(['No Channels to plot. Probably from other NSP'])
    return
end

%% Select WHAT to plot
switch upper(whatToUse)
    case 'ZNORM'
        %before:useNormalized==1
        EEGtoPlot = stData.zNormEEGStim(indSelCh);
        cfgInfoPlot.ampUnits = 'Zscore (fromStart)';
        cfgInfoPlot.maxAmpVal = 5;
        cfgInfoPlot.minAmpVal = -5;
    case 'PERTRIAL'
        %before:useNormalized==1
        EEGtoPlot = stData.perTrialNormEEGStim(indSelCh);
        cfgInfoPlot.ampUnits = 'Zscore (perTrial)';
        cfgInfoPlot.maxAmpVal = 5;
        cfgInfoPlot.minAmpVal = -5;
        
    case 'EEG'
        EEGtoPlot = stData.EEGStimTrials(indSelCh);
        cfgInfoPlot.ampUnits = 'uV';
        cfgInfoPlot.maxAmpVal = 250;
        cfgInfoPlot.minAmpVal = -250;
end
nChannels = numel(EEGtoPlot);


%% PLOTS (Divided by STIM site)
cfgInfoPlot.indXTimeForYlim = cfgInfoPlot.xTimeForYlim * Fs + find(timePerTrialmiliSec>=0,1);

   for iCh=1:nChannels
        % Get Ch name and EEG data
        chName = regexprep(chNamesForPlot{iCh},'\W',''); %remove extra spaces & / and get contacts names
        EEGtoPlotPerCh = EEGtoPlot{iCh};
        [meanStim, q25DetStim, q75DetStim, stdDetStim, stdErrorDetStim]= meanQuantiles(EEGtoPlotPerCh, 2);
        nStim = size(EEGtoPlotPerCh,2);
        titNamePerCh = [' Rec Channel ', chName, ' ', titNameComplete, ' Stim (',num2str(nStim),')' ];
        eegForLims = EEGtoPlotPerCh(cfgInfoPlot.indXTimeForYlim(1):cfgInfoPlot.indXTimeForYlim(2),:);
        
    % 1. Plot Waterfall of stim data
    %  data must be in format: time x ntrials x channels matrix
    %    plotWaterFall(EEGtoPlotPerCh, timePerTrialmiliSec, chName, titNameComplete, dirImageComplete, cfgInfoPlot);
        
    
%     % 2. Plot Trial by Trial 
%         titNameForPlot = ['EEG ', titNamePerCh];
%         titNameForFile = regexprep(titNameForPlot,'\W','_');
%         figure('Name', titNameForPlot);
%         %plotTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec,[min(eegForLims(:)) max(eegForLims(:))], titNameForPlot, [dirImageComplete, filesep, titNameForFile]);
%         plotTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec,[cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal], titNameForPlot, [dirImageComplete, filesep, titNameForFile]);
        
    % 3. Plot all stim togetehr with different colors
        titNameForPlot = ['ERP EEG ', titNamePerCh];
        figure('Name',titNameForPlot);
        hold on;
        shadedErrorBar(timePerTrialmiliSec,EEGtoPlot{iCh}',{@mean,@std},'lineprops','-r','patchSaturation',0.3);
        if isfield(cfgInfoPlot,'myColorOrder') && ~isempty(cfgInfoPlot.myColorOrder), set(gca, 'ColorOrder', cfgInfoPlot.myColorOrder);end
        
        hall = plot(timePerTrialmiliSec, EEGtoPlotPerCh','LineWidth',0.5);
        hds = plot(timePerTrialmiliSec, meanStim,'k','LineWidth',3);
        
        line([0, 0], [min(q25DetStim) max(q75DetStim)], 'Color',[1 0.5 0],'LineWidth',2)
        title(titNameForPlot)
        ylabel(cfgInfoPlot.ampUnits)
        xlabel('Time (ms)')
        legend([hds, hall(1), hall(end)],{ ['mean ERP Stim'],'Stim #1',['Stim #',num2str(nStim)]},'Location', 'best');
        titNameForFile = regexprep(titNameForPlot,'\W','_');
        saveas(gcf,[dirImageComplete,filesep, titNameForFile],'png');
        savefig(gcf,[dirImageComplete, filesep,titNameForFile,'fig'],'compact');
        
        
        %4. Zoom in and save .png
        xlim(cfgInfoPlot.xlimZoomMiliSec)
        ylim([min(eegForLims(:)) max(eegForLims(:))]);
        saveas(gcf,[dirImageComplete,filesep, titNameForFile,'_zoom'],'png');

      
    end



