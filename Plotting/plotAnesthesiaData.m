function [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfile, channInfo, dirImages, titName, whatToUse)

%% CONFIG
cfgInfoPlot.xlimZoomMiliSec = [-10 250];
cfgInfoPlot.xTimeForYlim = [3 100]/1000; % in seconds


cfgInfoPlot.myColorOrder = zeros(50,3);
cfgInfoPlot.myColorOrder(:,1) = (50:-1:1)/50;

cfgInfoPlot.numbToAverage =10; % to compare first 10 and last 10

cfgInfoPlot.tBaselineForZeroMean  =  -[26 1]/1000;% 25 ms right before stim

%% LOAD data from MAT file
% (saved on AnesthesiaAnalysisFromAINP.m) 
if isempty(EEGStimTrialMATfile)
    titNameComplete = titName;
    dirImageComplete = dirImages;
    return;
end

stData = load(EEGStimTrialMATfile);
timePerTrialmiliSec = 1000*stData.timePerTrialSec;
stimSiteNames = stData.stimSiteNames;
chNamesSelected = stData.chNamesSelected;
tBeforeStimSec = stData.tBeforeStimSec;
tAfterStimSec = stData.tAfterStimSec;
Fs = stData.hdr.Fs;
useBipolar = stData.useBipolar;
stimChannInfo = stData.stimChannInfo;

if isfield(stData, 'firstLossConscTrial'), firstLossConscTrial= stData.firstLossConscTrial; end
    

%% File / Directory checking 
titNameForFile = regexprep(titName,'\W','_');
dirImageComplete = [dirImages,filesep,titNameForFile,'_',stimSiteNames{2},'-',stimSiteNames{1}];
if ~exist(dirImageComplete,'dir'), mkdir(dirImageComplete); end
titNameComplete = [titName,' ',whatToUse,' ',stimSiteNames{2},'-',stimSiteNames{1}];

%% Select specified channels if exist
if useBipolar 
    if isfield(channInfo,'recBipolarChPerStim') && ~isempty( channInfo.recBipolarChPerStim)
        % Find WHICH stimulation channel is the one in this file
        indStim = find(strcmpi(stimSiteNames{1},channInfo.stimChNames(1,:)));
        chNamesForPlotInput = channInfo.recBipolarChPerStim{indStim};
    else
        indStim = find(strcmpi(stimSiteNames{1},stimChannInfo.stimChNames(1,:)));
        chNamesForPlotInput = stimChannInfo.recBipolarChPerStim{indStim};
    end
else
    if isfield(channInfo,'recReferentialChPerStim') && ~isempty( channInfo.recReferentialChPerStim)
        % Find WHICH stimulation channel is the one in this file
        indStim = find(strcmpi(stimSiteNames{1},channInfo.stimChNames(1,:)));
        chNamesForPlotInput = channInfo.recReferentialChPerStim{indStim};
    else
        indStim = find(strcmpi(stimSiteNames{1},stimChannInfo.stimChNames(1,:)));
        chNamesForPlotInput = stimChannInfo.recReferentialChPerStim{indStim};
    end
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
[EEGtoPlot, indSelCh, cfgInfoPlot] = selectWhatSignalToUse(stData, whatToUse, indSelCh, cfgInfoPlot);
nChannels = numel(EEGtoPlot);

%% PLOTS (Divided by STIM site)
cfgInfoPlot.indXTimeForYlim = cfgInfoPlot.xTimeForYlim * Fs + find(timePerTrialmiliSec>=0,1);
allEEGToPlot = [EEGtoPlot{:}];
eegForLims = allEEGToPlot(cfgInfoPlot.indXTimeForYlim(1):cfgInfoPlot.indXTimeForYlim(2),:);
minMaxEEGAllChFromLims = [quantile([eegForLims(:)]',0.01) quantile([eegForLims(:)]',0.99)] ;

   for iCh=1:nChannels
        % Get Ch name and EEG data
        chName = regexprep(chNamesForPlot{iCh},'\W',''); %remove extra spaces & / and get contacts names
        EEGtoPlotPerCh = EEGtoPlot{iCh};
        if size(EEGtoPlotPerCh,2)>0
            [meanStim, q25DetStim, q75DetStim, stdDetStim, stdErrorDetStim]= meanQuantiles(EEGtoPlotPerCh, 2);
            nStim = size(EEGtoPlotPerCh,2);
            titNamePerCh = [' Rec ', chName,' ', titNameComplete, ' Stim (',num2str(nStim),')'];
            eegForLims = EEGtoPlotPerCh(cfgInfoPlot.indXTimeForYlim(1):cfgInfoPlot.indXTimeForYlim(2),:);
            
            % 1. Plot Waterfall of stim data
            %  data must be in format: time x ntrials x channels matrix
            plotWaterFall(EEGtoPlotPerCh, timePerTrialmiliSec, chName, titNameComplete, dirImageComplete, cfgInfoPlot);
            
            
            % 2. Plot Trial by Trial
            titNameForPlot = ['Trials ', titNamePerCh];
            titNameForFile = regexprep(titNameForPlot,'\W','_');
            figure('Name', titNameForPlot);
            %plotTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec,[min(eegForLims(:)) max(eegForLims(:))], titNameForPlot, [dirImageComplete, filesep, titNameForFile]);
            plotTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec,[cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal], titNameForPlot, [dirImageComplete, filesep, titNameForFile], firstLossConscTrial);
            
            % 3. Plot Stacked plots Trial by Trial
            titNameForPlot = ['StackedTrials ', titNamePerCh];
            titNameForFile = regexprep(titNameForPlot,'\W','_');
            figure('Name', titNameForPlot);
            plotStackedTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec,[cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal], titNameForPlot, [dirImageComplete, filesep, titNameForFile], firstLossConscTrial);
            %plotStackedTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec, minMaxEEGAllChFromLims, titNameForPlot, [dirImageComplete, titNameForFile], firstLossConscTrial); % save in main dir - for easy checking!

            %3.2 Zoom in and save .png
            xlim(cfgInfoPlot.xlimZoomMiliSec*2)
           % ylim([min(eegForLims(:)) max(eegForLims(:))]); 
           % saveas(gcf,[dirImageComplete,filesep, titNameForFile,'_zoom'],'png'); % RIZ: use this later on!
            saveas(gcf,[dirImageComplete, titNameForFile,'_zoom'],'png'); % for easy access!

            % 4. Plot all stim togetehr with different colors
            titNameForPlot = ['ERP ', titNamePerCh];
            figure('Name',titNameForPlot);
            hold on;
            %shadedErrorBar(timePerTrialSec,EEGtoPlot{iCh}',{@mean,@std},'lineprops','-r','patchSaturation',0.5);
            set(gca, 'ColorOrder', cfgInfoPlot.myColorOrder);
            hall = plot(timePerTrialmiliSec, EEGtoPlotPerCh','LineWidth',0.5);
            hds = plot(timePerTrialmiliSec, meanStim,'r','LineWidth',3);
            
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
            
            %5. Plot average of first 10 vs last 10 trials
            titNameForPlot = ['Av ERP 1st Last ', titNamePerCh];
            figure('Name',titNameForPlot);
            hold on;
            %shadedErrorBar(timePerTrialSec,EEGtoPlot{iCh}',{@mean,@std},'lineprops','-r','patchSaturation',0.5);
            %set(gca, 'ColorOrder', cfgInfoPlot.myColorOrder);
            h1 = plot(timePerTrialmiliSec, mean(EEGtoPlotPerCh(:,1: min(cfgInfoPlot.numbToAverage,size(EEGtoPlotPerCh,2))),2),'LineWidth',2);
        hlast = plot(timePerTrialmiliSec, mean(EEGtoPlotPerCh(:,max(end-cfgInfoPlot.numbToAverage+1,1):end),2),'LineWidth',2);
        
        line([0, 0], [min(q25DetStim) max(q75DetStim)], 'Color',[1 0.5 0],'LineWidth',2)
        ylim([min(eegForLims(:)) max(eegForLims(:))]);
        title(titNameForPlot)
        ylabel(cfgInfoPlot.ampUnits)
        xlabel('Time (ms)')
        legend([h1, hlast],{ ['Stim #1-',num2str(min(cfgInfoPlot.numbToAverage,size(EEGtoPlotPerCh,2)))],['Stim #',num2str(nStim-min(cfgInfoPlot.numbToAverage,size(EEGtoPlotPerCh,2))),'-',num2str(nStim)]},'Location', 'best');
        titNameForFile = regexprep(titNameForPlot,'\W','_');
        saveas(gcf,[dirImageComplete,filesep, titNameForFile],'png');
        savefig(gcf,[dirImageComplete, filesep,titNameForFile,'fig'],'compact');
         %6. Zoom in and save .png
        xlim(cfgInfoPlot.xlimZoomMiliSec)
        ylim([min(eegForLims(:)) max(eegForLims(:))]);
        saveas(gcf,[dirImageComplete,filesep, titNameForFile,'_zoom'],'png');
        end
    end



