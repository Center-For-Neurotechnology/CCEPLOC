function plotExampleForPaperLOC(EEGStimTrialMATfiles, dirImages, cfgInfoPlot,chNamesForPlotInput)

% EEGStimTrialMATfiles: struct with files: EEGStimTrialMATfileWakeEMU, EEGStimTrialMATfileSleep,  EEGStimTrialMATfileWakeOR, EEGStimTrialMATfileAnest,
% whatToUse = 'EEG0MEAN'; %Options are: 'ZNORM', 'PERTRIAL', 'ZEROMEANZNORM', 'EEG', 'EEG0MEAN'
%cfgInfoPlot=[];
nTrials=10;
indTrials=randperm(nTrials);

allStates = cfgInfoPlot.allStates;
titName = cfgInfoPlot.titName;
whatToUse = cfgInfoPlot.whatToUse;

cfgInfoPlot.xlimZoomMiliSec = [-500 1000];
cfgInfoPlot.xTimeForYlim = [3 500]/1000; % in seconds
cfgInfoPlot.timeOfStimSamples=0;
cfgInfoPlot.legLabel =allStates;

nStates = length(EEGStimTrialMATfiles);
for iState=1:nStates
    % Load data
    stData = load(EEGStimTrialMATfiles{iState});
    cfgInfoPlot.timePerTrialSec = stData.timePerTrialSec;
    timePerTrialmiliSec = 1000*stData.timePerTrialSec;
    stimSiteNames = stData.stimSiteNames;
    chNamesSelected = stData.chNamesSelected;
    tBeforeStimSec = stData.tBeforeStimSec;
    tAfterStimSec = stData.tAfterStimSec;
    Fs = stData.hdr.Fs;
    cfgInfoPlot.Fs = Fs;
%useBipolar = stData.useBipolar;
    stimChannInfo = stData.stimChannInfo;
    
    
    % find ind of channels
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
    [EEGtoPlot{iState}, indSelCh, cfgInfoPlot] = selectWhatSignalToUse(stData, whatToUse, indSelCh, cfgInfoPlot);
    nChannels = numel(EEGtoPlot{iState});
    
end

%% PLOTS (Divided by STIM site)
cfgInfoPlot.indXTimeForYlim = cfgInfoPlot.xTimeForYlim * Fs + find(timePerTrialmiliSec>=0,1);
% allEEGToPlot = [EEGtoPlot{:}];
% eegForLims = allEEGToPlot(cfgInfoPlot.indXTimeForYlim(1):cfgInfoPlot.indXTimeForYlim(2),:);
% minMaxEEGAllChFromLims = [quantile([eegForLims(:)]',0.01) quantile([eegForLims(:)]',0.99)] ;
scrsz = get(groot,'ScreenSize');
for iCh=1:nChannels
    % Get Ch name and EEG data
    chName = regexprep(chNamesForPlot{iCh},'\W',''); %remove extra spaces & / and get contacts names
    allDataPerCh = cell(0,0);
    for iState=1:nStates
        EEGtoPlotPerCh = EEGtoPlot{iState}{iCh}(:,indTrials);
        if size(EEGtoPlotPerCh,2)>0
            titNamePerCh = [titName,' ' whatToUse,' ',allStates{iState}, ' ', chName];
            % 3. Plot Stacked plots Trial by Trial
            titNameForPlot = ['Stacked10Trials ', titNamePerCh];
            titNameForFile = regexprep(titNameForPlot,'\W','_');
            figure('Name', titNameForPlot, 'Position',[1 1 scrsz(3)/3 scrsz(4)]);
            plotStackedTrialByTrial(EEGtoPlotPerCh', -tBeforeStimSec, tAfterStimSec,[cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal], titNameForPlot, [dirImages, filesep, titNameForFile]);
            allDataPerCh{iState} = EEGtoPlotPerCh;
        end
    end
    plotTogetherWakeSleepAnesthesia(allDataPerCh, chName, cfgInfoPlot,dirImages);
    
end

   