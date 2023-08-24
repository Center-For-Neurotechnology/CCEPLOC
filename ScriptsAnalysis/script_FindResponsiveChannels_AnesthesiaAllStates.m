function [lstResponsiveChannel_AllStates, lstResponsiveChannelMATfileAllStates] = script_FindResponsiveChannels_AnesthesiaAllStates(dataPerStimAllChannelsMATfileName, channInfo, whatToUse)
% Find responsive channels using data from Wake EMU tests.
% PerTrial normalization results on channels similar to visual inspection

%% CONFIG
useAVERAGE=1;
% tN1 = [10 60]/1000; % time (sec) to compute N1 peak amplitude -(similar to Keller2018)
% tN2 = [60 250]/1000; % time (sec) to compute N2 peak amplitude
% tCCEP = [10 300]/1000; %time (sec) to compute CCEP peak amplitude (Dionisio2019)

tLimitsSec =  [0 600]/1000; %[10 300]/1000; %[tN1(1) tN2(2)]; %s
cfgInfoPlot.tPlotSec = [-250 1000]/1000; % time to plot
cfgInfoPlot.minNumberTrials = 5; % at least 5 (before: 10 trials) to display/compute responsive chanels

if ~exist('whatToUse','var'), whatToUse = 'PERTRIAL'; end % Options are: 'ZNORM', 'PERTRIAL', 'ZEROMEANZNORM', 'EEG', 'EEG0MEAN'

if ~exist('channInfo','var'), channInfo = struct();end
if ~isfield(channInfo,'pName'), channInfo.pName = 'test';end
if ~isfield(channInfo,'originalDir'), channInfo.originalDir = [];end
if ~isfield(channInfo,'thisPCDir'), channInfo.thisPCDir = channInfo.originalDir;end
if ~isfield(channInfo,'posFixDir'), channInfo.posFixDir = [];end

useMedian =1; % 0=mean / 1=median
channInfo.posFixDir = [channInfo.posFixDir,'MEDIAN'];

% Files and Directories
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

dirResults = [fileparts(dataPerStimAllChannelsMATfileName),filesep,'ResponsiveChannelsAllStates',whatToUse,channInfo.posFixDir];
dirImages = [dirResults, filesep, 'images_AllStates'];
if ~exist(dirImages,'dir'), mkdir(dirImages); end

%% Find Responsive all Brain States - with plots
diary([dirResults, filesep, 'logResponsiveChannels',pName,'_AllStates',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2)),'_Average.log'])
lstResponsiveChannel_AllStates=cell(length(allFiles),1);
lstResponsiveChannelMATfileAllStates=cell(length(allFiles),1);
for iState=1:length(allFiles)
    thisState = allStates{iState};
    disp(['Finding Responsive channels during ',thisState]);
    lstResponsiveChannel_AveragePerTrialPerFile = cell(length(allFiles{iState}),1);
    stimSiteNamesPerFile=cell(length(allFiles{iState}),1);
    nRespChPerFile=cell(length(allFiles{iState}),1);
    %run wmpty to get structure of data
    [~, channInfoRespChPerStim] = findResponsiveChannelsRelativeToBaseline([], dirImages, whatToUse, useAVERAGE, [],tLimitsSec, channInfo);
    channInfoRespCh_AveragePerTrial = channInfoRespChPerStim;

    for iFile=1:length(allFiles{iState})
        if ~isempty(allFiles{iState}{iFile})
            [responsiveChannel_AveragePerTrial, channInfoRespChPerStim] = findResponsiveChannelsRelativeToBaseline(allFiles{iState}{iFile}, dirImages, whatToUse, useAVERAGE, [],tLimitsSec, channInfo, useMedian);
            lstResponsiveChannel_AveragePerTrialPerFile{iFile} = responsiveChannel_AveragePerTrial;
            nRespChPerFile{iFile} = length(responsiveChannel_AveragePerTrial);
            channInfoRespCh_AveragePerTrial(iFile) = channInfoRespChPerStim;
            stimSiteNamesPerFile(iFile) = strcat(channInfoRespCh_AveragePerTrial(iFile).stimSiteNames(2),'-',channInfoRespCh_AveragePerTrial(iFile).stimSiteNames(1));
            disp(['# resp channels ', stimSiteNamesPerFile(iFile)', nRespChPerFile(iFile)])
            %% Plot all channels with responsive information
            cfgInfoPlot.lstResponsiveChannel = responsiveChannel_AveragePerTrial;
            cfgInfoPlot.lstSOZChNames = unique([channInfo.excludedChannelsSOZ, channInfoRespChPerStim.chNamesExcluded]); % to incorporate specified SOZ channels and rejected for other reasons
            plotAllCCEPPerElectrode(allFiles{iState}{iFile},[dirImages,filesep,'AllCCEPwRespCh_',allStates{iState},'_',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2))], whatToUse, cfgInfoPlot);
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
    channInfo.channInfoRespCh=channInfoRespCh;
    lstResponsiveChannelMATfile = [dirResults, filesep, 'lstResponsiveChannel',pName,'_',allStates{iState},'_P2P2std',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2)),'.mat'];
    save(lstResponsiveChannelMATfile,'lstResponsiveChannel_AveragePerTrial','channInfoRespCh','stimSiteNames','nRespCh','thisState', 'allFiles','allStates','channInfo');
    lstResponsiveChannelMATfileAllStates{iState} = lstResponsiveChannelMATfile;
    lstResponsiveChannel_AllStates{iState} = lstResponsiveChannel_AveragePerTrialPerFile;
end

diary off




