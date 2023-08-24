function [PCIstAllStates, PCIValsMATfileAllStates] = script_computePCI_AnesthesiaAllStates(fileNameAllChMATfiles, channInfo)
% Find responsive channels using data from Wake EMU tests.
% PerTrial normalization results on channels similar to visual inspection

%% CONFIG
useAVERAGE=1;
tN1 = [10 60]/1000; % time (sec) to compute N1 peak amplitude -(similar to Keller2018)
tN2 = [60 250]/1000; % time (sec) to compute N2 peak amplitude
tCCEP = [10 300]/1000; %time (sec) to compute CCEP peak amplitude (Dionisio2019)

tLimitsSec = [0 600]/1000; %[10 300]/1000; %[tN1(1) tN2(2)]; %s
whatToUse = 'PERTRIAL'; % Options are: 'ZNORM', 'PERTRIAL', 'ZEROMEANZNORM', 'EEG', 'EEG0MEAN'
cfgInfoPlot.tPlotSec = [-250 1000]/1000; % time to plot
cfgInfoPlot.minNumberTrials = 5; % before at least 10 trials to display/compute PCI (same as min for responsive chanels)

if ~exist('channInfo','var'), channInfo = struct();end
if ~isfield(channInfo,'pName'), channInfo.pName = 'test';end
if ~isfield(channInfo,'originalDir'), channInfo.originalDir = [];end
if ~isfield(channInfo,'thisPCDir'), channInfo.thisPCDir = channInfo.originalDir;end
if ~isfield(channInfo,'posFixDir'), channInfo.posFixDir = [];end

pName = channInfo.pName;

cfgInfoPlot.useColorPerRegion=1;

%% Files
if ~exist('fileNameAllChMATfiles','var')
    [file1, path1] = uigetfile('*.*','Select MAT File With FileNames');
    fileNameAllChMATfiles = [path1,file1];
end
if isdir(fileNameAllChMATfiles)  % compatibility - before we were passing a directory
    fileNameAllChMATfiles = [fileNameAllChMATfiles,filesep,'dataPerStimAllChannels_',pName,'.mat'];
end

[fileNamesAnesthesia, fileNamesWakeOR, fileNamesWakeEMU, fileNamesSleep] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameAllChMATfiles,channInfo.originalDir,channInfo.thisPCDir,channInfo);
allFiles = {fileNamesWakeEMU, fileNamesSleep, fileNamesWakeOR, fileNamesAnesthesia};
allStates = {'WakeEMU', 'Sleep','WakeOR','Anesthesia'};

dirResults = [fileparts(fileNameAllChMATfiles),filesep,'PCIValsAllStates',whatToUse,channInfo.posFixDir];
dirImages = [dirResults, filesep, 'images_AllStates'];
if ~exist(dirImages,'dir'), mkdir(dirImages); end

%% Compute PCI for each STIM channel in all Brain States - with plots
diary([dirResults, filesep, 'logPCIst',pName,'_AllStates',num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2)),'_Average.log'])
PCIstAllStates=cell(length(allFiles),1);
PCIValsMATfileAllStates=cell(length(allFiles),1);
for iState=1:length(allFiles)
    thisState = allStates{iState};
    disp(['Computing PCI during ',thisState]);
    PCIstPerStimCh = cell(length(allFiles{iState}),1);
    stimSiteNames=cell(length(allFiles{iState}),1);
    stimSiteNamePNames=cell(length(allFiles{iState}),1);
    channInfoPCIPerStimCh = struct('PCIstVal',[],'PCAVals',[],'dNST',[],...
        'chNamesSelected',cell(0,0),'stimPatChNames',cell(0,0),'chNamesExcluded',[],'stimSiteNames',[],'titName',[],'whatToUse',whatToUse,'useAverage',useAVERAGE,'tLimitsSec',tLimitsSec,...
        'anatRegionsStimCh',cell(0,0),'RASCoordPerChStimCh',[],'anatRegionsPerCh',cell(0,0),'RASCoordPerCh',[],...
        'cfgInfoPlot',[],'cfgInfoPeaks',[],'channInfo',channInfo,'paramsPCI',[]);
    filesPerState = allFiles{iState};
    for iFile=1:length(filesPerState)
        if ~isempty(filesPerState{iFile})
            [PCIstVal, channInfoPCI] = computePCIperStimChannel(filesPerState{iFile}, dirImages, whatToUse, useAVERAGE, [], tLimitsSec, channInfo);
            PCIstPerStimCh{iFile} = PCIstVal;
            channInfoPCIPerStimCh{iFile} = channInfoPCI;
            stimSiteNames{iFile} = strcat(channInfoPCI.stimSiteNames{2},'-',channInfoPCI.stimSiteNames{1});
            stimSiteNamePNames{iFile} = channInfoPCI.stimPatChNames;
        end
        close all
    end
%% save
    channInfo.channInfoPCI = channInfoPCIPerStimCh;
    channInfo.stimSiteNames = stimSiteNames;
    channInfo.stimSiteNamePNames = stimSiteNamePNames;

    PCIValsMATfile = [dirResults, filesep, 'PCIVals2',pName,'_',allStates{iState},num2str(tLimitsSec(1)),'_',num2str(tLimitsSec(2)),'.mat'];
    save(PCIValsMATfile,'PCIstPerStimCh','channInfoPCIPerStimCh','stimSiteNames','stimSiteNamePNames','thisState', 'channInfoPCIPerStimCh','allFiles','allStates','channInfo');
    PCIValsMATfileAllStates{iState} = PCIValsMATfile;
    PCIstAllStates{iState} = PCIstPerStimCh;
end

diary off




