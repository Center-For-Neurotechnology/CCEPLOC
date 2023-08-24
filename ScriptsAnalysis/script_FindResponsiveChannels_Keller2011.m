function [lstResponsiveChannel_AllStates, lstResponsiveChannelMATfileAllStates] = script_FindResponsiveChannels_Keller2011(dataPerStimAllChannelsMATfileName, channInfo)
% Find responsive channels using data from Wake EMU tests.
% PerTrial normalization results on channels similar to visual inspection

%% CONFIG
useAVERAGE=1; % in this case is the mean
tLimitsSec = [50 500]/1000; % 50-500 as in Keller2011
whatToUse = 'PERTRIAL'; % Options are: 'ZNORM', 'PERTRIAL', 'ZEROMEANZNORM', 'EEG', 'EEG0MEAN'
cfgInfoPlot.tPlotSec = [-250 1000]/1000; % time to plot
cfgInfoPlot.minNumberTrials = 5; % at least 5 (before: 10 trials) to display/compute responsive chanels

if ~exist('channInfo','var'), channInfo = struct();end
if ~isfield(channInfo,'pName'), channInfo.pName = 'test';end
if ~isfield(channInfo,'originalDir'), channInfo.originalDir = [];end
if ~isfield(channInfo,'thisPCDir'), channInfo.thisPCDir = channInfo.originalDir;end
if ~isfield(channInfo,'posFixDir'), channInfo.posFixDir = [];end

pName = channInfo.pName;

cfgInfoPlot.useColorPerRegion=1;

%% Files
if ~exist('dataPerStimAllChannelsMATfileName','var')
    [file1, path1] = uigetfile('*.*','Select MAT File With FileNames');
    dataPerStimAllChannelsMATfileName = [path1,file1];
end
if isdir(dataPerStimAllChannelsMATfileName)  % compatibility - before we were passing a directory
    dataPerStimAllChannelsMATfileName = [dataPerStimAllChannelsMATfileName,filesep,'dataPerStimAllChannels_',pName,'.mat'];
end

[fileNamesAnesthesia, fileNamesWakeOR, fileNamesWakeEMU, fileNamesSleep] = getAnesthesiaWakeSleepFilesFromAllFile(dataPerStimAllChannelsMATfileName,channInfo.originalDir,channInfo.thisPCDir,channInfo);
allFiles = {fileNamesWakeEMU, fileNamesSleep, fileNamesWakeOR, fileNamesAnesthesia};
allStates = {'WakeEMU', 'Sleep','WakeOR','Anesthesia'};

dirResults = [fileparts(dataPerStimAllChannelsMATfileName),filesep,'ResponsiveChannelsAllStates',whatToUse,channInfo.posFixDir,'_Keller2011'];
dirImages = [dirResults, filesep, 'images_AllStates'];
if ~exist(dirImages,'dir'), mkdir(dirImages); end


%% Find Responsive all Brain States - with plots
diary([dirResults, filesep, 'logResponsiveChannels',pName,'_AllStates',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2)),'_AverageKeller2011.log'])
lstResponsiveChannel_AllStates=cell(length(allFiles),1);
lstResponsiveChannelMATfileAllStates=cell(length(allFiles),1);
for iState=1:length(allFiles)
    thisState = allStates{iState};
    disp(['Finding Responsive channels during ',thisState]);
    lstResponsiveChannel_AveragePerTrialPerFile = cell(length(allFiles{iState}),1);
    stimSiteNamesPerFile=cell(length(allFiles{iState}),1);
    nRespChPerFile=cell(length(allFiles{iState}),1);
    channInfoRespCh_AveragePerTrial=struct('lstResponsiveChannel',cell(0,0),'ampResponsiveCh',cell(0,0),'ptpResponsiveCh',cell(0,0),'locFirstPeakRespCh',cell(0,0),'locMaxPeakRespCh',cell(0,0),'rmsDataPerCh',cell(0,0),...
        'areaPerCh',cell(0,0),'areaP2PPerCh',cell(0,0),'prominencePerCh',cell(0,0),'p2P2PAmpPerCh',cell(0,0),'peakMaxMinAmpPerCh',cell(0,0),'nPeaksCh',cell(0,0),...
        'chNamesSelected',[],'chNamesExcluded',[],'chNamesSelectedOrig',[],'indExcludedChannels',[],'isChExcluded',[],'isChResponsive',[],'stimSiteNames',[],...
        'titName',[],'whatToUse',whatToUse,'useAverage',1,'tLimitsSec',tLimitsSec,...
        'anatRegionsResp',cell(0,0),'RASCoordResp',cell(0,0),'anatRegionsStimCh',cell(0,0),'RASCoordPerChStimCh',cell(0,0),'anatRegionsPerCh',cell(0,0),'RASCoordPerCh',cell(0,0),...
        'avPeakToPeakAmpPerCh',cell(0,0),'cfgInfoPlot',[],'cfgInfoPeaks',[],...
        'relAmpPerCh',cell(0,0),'relP2PPerCh',cell(0,0),'relP2P2PPerCh',cell(0,0),'relAreaPerCh',cell(0,0),'relP2PAreaPerCh',cell(0,0),'relP2P2PAreaPerCh',cell(0,0),'relMaxMinAmpPerCh',cell(0,0));

    for iFile=1:length(allFiles{iState})
        if ~isempty(allFiles{iState}{iFile})
       %     [responsiveChannel_AveragePerTrial, channInfoRespChPerStim] = findResponsiveChannelsRelativeToBaseline(allFiles{iState}{iFile}, dirImages, whatToUse, useAVERAGE, [],tLimitsSec, channInfo);
            [responsiveChannel_AveragePerTrial, channInfoRespChPerStim] = findResponsiveChannelsKeller2011(allFiles{iState}{iFile}, dirImages, whatToUse, useAVERAGE, [],tLimitsSec, channInfo);
            lstResponsiveChannel_AveragePerTrialPerFile{iFile} = responsiveChannel_AveragePerTrial;
            nRespChPerFile{iFile} = length(responsiveChannel_AveragePerTrial);
            channInfoRespCh_AveragePerTrial(iFile) = channInfoRespChPerStim;
            stimSiteNamesPerFile(iFile) = strcat(channInfoRespCh_AveragePerTrial(iFile).stimSiteNames(2),'-',channInfoRespCh_AveragePerTrial(iFile).stimSiteNames(1));
            disp(['# resp channels ', stimSiteNamesPerFile(iFile)', nRespChPerFile(iFile)])
            %% Plot all channels with responsive information
            cfgInfoPlot.lstResponsiveChannel = responsiveChannel_AveragePerTrial;
            cfgInfoPlot.lstSOZChNames = unique([channInfo.excludedChannelsSOZ, channInfoRespChPerStim.chNamesExcluded]); % to incorporate specified SOZ channels and rejected for other reasons
            plotAllCCEPPerElectrode(allFiles{iState}{iFile},[dirImages,filesep,'Keller_AllCCEPwRespCh_',allStates{iState},'_',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2))], whatToUse, cfgInfoPlot);
        end
    end
    % reorganize per stimSite (to concatenate together NSP1 and NSP2)
    stimSiteNames=[];
    nRespCh = [];
    channInfoRespCh=cell(0,0);
    lstResponsiveChannel_AveragePerTrial=cell(0,0);
    if ~isempty(stimSiteNamesPerFile)
        %allStimSites = [stimSiteNamesPerFile{:}];
        stimSiteNames = unique(stimSiteNamesPerFile); %strcat(allStimSites(2,:),'-',allStimSites(1,:)); %
        nRespCh = zeros(length(stimSiteNames),1);
        lstResponsiveChannel_AveragePerTrial = cell(length(stimSiteNames),1);
        channInfoRespCh = cell(length(stimSiteNames),1);
        for iFile=1:length(stimSiteNamesPerFile)
            if ~isempty(stimSiteNames)
                indPerStim = find(strcmp(stimSiteNames, stimSiteNamesPerFile{iFile}));
                nRespCh(indPerStim) = nRespCh(indPerStim)+ nRespChPerFile{iFile};
                lstResponsiveChannel_AveragePerTrial{indPerStim} = [lstResponsiveChannel_AveragePerTrial{indPerStim},lstResponsiveChannel_AveragePerTrialPerFile{iFile}];
                channInfoRespCh{indPerStim} = [channInfoRespCh{indPerStim}, channInfoRespCh_AveragePerTrial(iFile)];
            end
        end
    end
%% save
  %  channInfoRespCh = channInfoRespCh_AveragePerTrial; % per trial is the default one
    channInfo.channInfoRespCh=channInfoRespCh;
    lstResponsiveChannelMATfile = [dirResults, filesep, 'lstResponsiveChannel',pName,'_',allStates{iState},'_P2P2std',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2)),'.mat'];
    save(lstResponsiveChannelMATfile,'lstResponsiveChannel_AveragePerTrial','channInfoRespCh','stimSiteNames','nRespCh','thisState', 'allFiles','allStates','channInfo');
    lstResponsiveChannelMATfileAllStates{iState} = lstResponsiveChannelMATfile;
    lstResponsiveChannel_AllStates{iState} = lstResponsiveChannel_AveragePerTrialPerFile;
end

diary off




