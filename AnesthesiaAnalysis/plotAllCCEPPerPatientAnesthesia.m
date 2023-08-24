function plotAllCCEPPerPatientAnesthesia(fileNameMATfiles, dirImages, whatToUse, channInfo, cfgInfoPlot, lstResponsiveChannelMATfile)

% whatToUse Options are: 'ZNORM', 'PERTRIAL', 'ZEROMEANZNORM', 'EEG', 'EEG0MEAN'
if ~exist('whatToUse','var'), whatToUse='EEG0MEAN'; end
if ~exist('channInfo','var'), channInfo=[]; end
if ~exist('cfgInfoPlot','var'), cfgInfoPlot=[]; end
if ~exist('lstResponsiveChannelMATfile','var'), lstResponsiveChannelMATfile=[]; end

if ~isfield(channInfo,'originalDir'), channInfo.originalDir = [];end % where the files were originally
if ~isfield(channInfo,'thisPCDir'), channInfo.thisPCDir = channInfo.originalDir;end  % where are the files with respect to fileNameMATfiles


%% Trials
% Trials
if ~isfield(channInfo,'trialsAnesthesia'), channInfo.trialsAnesthesia = 15; end
if ~isfield(channInfo,'trialsWakeOR'), channInfo.trialsWakeOR = 1:channInfo.trialsAnesthesia; end
if ~isfield(channInfo,'trialsWakeEMU'), channInfo.trialsWakeEMU = 1:15; end
if ~isfield(channInfo,'trialsSleep'), channInfo.trialsSleep = 1:15; end
% Trials to exclude
if ~isfield(channInfo,'trialsToExcludeAnesthesia'), channInfo.trialsToExcludeAnesthesia = []; end
if ~isfield(channInfo,'trialsToExcludeWakeEMU'), channInfo.trialsToExcludeWakeEMU = []; end
if ~isfield(channInfo,'trialsToExcludeWakeOR'), channInfo.trialsToExcludeWakeOR = []; end
if ~isfield(channInfo,'trialsToExcludeSleep'), channInfo.trialsToExcludeSleep = []; end

% Stim channels
if ~isfield(channInfo,'stimBipChNames')
    channInfo.stimBipChNames(1,:) = strcat(channInfo.stimChNames(1,:),'-',channInfo.stimChNames(2,:));
end
% SOZ channels
if ~isfield(cfgInfoPlot,'lstSOZChNames') && isfield(channInfo,'channelsSOZ')
    cfgInfoPlot.lstSOZChNames = channInfo.channelsSOZ;
end
%% CONFIG
cfgInfoPlot.useColorPerRegion=0;

%% Files and Directories
[fileNamesAnesthesia, fileNamesWakeOR, fileNamesWakeEMU, fileNamesSleep] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameMATfiles,channInfo.originalDir,channInfo.thisPCDir,channInfo);

%% Get info from responsive channels - then for each stim find appropriate ones
stimSiteNamesAllStim=[];
if ~isempty(lstResponsiveChannelMATfile)
    stRespFile = load(lstResponsiveChannelMATfile);
    lstResponsiveChannelAllStim = stRespFile.lstResponsiveChannel_AveragePerTrial;
    stimSiteNamesAllStim = stRespFile.stimSiteNames;
end

%% Wake OR
for iFile=1:length(fileNamesWakeOR)
    EEGStimTrialMATfile =fileNamesWakeOR{iFile};
    if ~isempty(EEGStimTrialMATfile)
        cfgInfoPlot.titName = [num2str(iFile),'WakeOR'];
        % Organize trials
        cfgInfoPlot.trialsToPlot = channInfo.trialsWakeOR;
        % Get File
         st = load(EEGStimTrialMATfile,'stimSiteNames');
        if ~isempty(channInfo.trialsToExcludeWakeOR)
            iStimCh = find(contains(channInfo.stimBipChNames, st.stimSiteNames{1}));
            indTrialToExclude=[];
            trialsToExclude = channInfo.trialsToExcludeWakeOR{iStimCh};
            for iTrial=1:length(trialsToExclude)
                indTrialToExclude = [indTrialToExclude, find(cfgInfoPlot.trialsToPlot==trialsToExclude(iTrial))];
                cfgInfoPlot.trialsToPlot(indTrialToExclude)=[];
            end
        end
        % get responsive channels
         cfgInfoPlot.lstResponsiveChannel=[];
        if ~isempty(stimSiteNamesAllStim)
            indStimInRespChLst = find(strcmpi(stimSiteNamesAllStim(1,:), st.stimSiteNames{1}));
            if ~isempty(indStimInRespChLst)
                cfgInfoPlot.lstResponsiveChannel = [lstResponsiveChannelAllStim{indStimInRespChLst}];
            end
        end
        % Plot all CCEP for all files
        plotAllCCEPPerElectrode(EEGStimTrialMATfile, dirImages, whatToUse, cfgInfoPlot);
        disp([cfgInfoPlot.titName, 'File ',EEGStimTrialMATfile, ' plotted!'])
    end
end
close all;

%% Anesthesia
for iFile=1:length(fileNamesAnesthesia)
    EEGStimTrialMATfile =fileNamesAnesthesia{iFile};
    if ~isempty(EEGStimTrialMATfile)
        cfgInfoPlot.titName = [num2str(iFile),'Anesthesia'];
        % Organize trials
        cfgInfoPlot.trialsToPlot = channInfo.trialsAnesthesia;
        % Get File
         st = load(EEGStimTrialMATfile,'stimSiteNames');
        if ~isempty(channInfo.trialsToExcludeAnesthesia)
            iStimCh = find(contains(channInfo.stimBipChNames, st.stimSiteNames{1}));
            indTrialToExclude=[];
            trialsToExclude = channInfo.trialsToExcludeAnesthesia{iStimCh};
            for iTrial=1:length(trialsToExclude)
                indTrialToExclude = [indTrialToExclude, find(cfgInfoPlot.trialsToPlot==trialsToExclude(iTrial))];
                cfgInfoPlot.trialsToPlot(indTrialToExclude)=[];
            end
        end
        % get responsive channels
         cfgInfoPlot.lstResponsiveChannel=[];
        if ~isempty(stimSiteNamesAllStim)
            indStimInRespChLst = find(strcmpi(stimSiteNamesAllStim(1,:), st.stimSiteNames{1}));
            if ~isempty(indStimInRespChLst)
                cfgInfoPlot.lstResponsiveChannel = [lstResponsiveChannelAllStim{indStimInRespChLst}];
            end
        end
        % Plot all CCEP for all files
        plotAllCCEPPerElectrode(EEGStimTrialMATfile, dirImages, whatToUse, cfgInfoPlot);
        disp([cfgInfoPlot.titName, 'File ',EEGStimTrialMATfile, ' plotted!'])
    end
end
close all;
%% Wake EMU
for iFile=1:length(fileNamesWakeEMU)
    EEGStimTrialMATfile =fileNamesWakeEMU{iFile};
    if ~isempty(EEGStimTrialMATfile)
        cfgInfoPlot.titName = [num2str(iFile),'WakeEMU'];
        % Organize trials
        cfgInfoPlot.trialsToPlot = channInfo.trialsWakeEMU;
        % Get File
        % remove trial exclusions (make sure that there is a corresponding stim bipolar
        st = load(EEGStimTrialMATfile,'stimSiteNames'); %load only stim names
        if ~isempty(channInfo.trialsToExcludeWakeEMU)
            iStimCh = find(contains(channInfo.stimBipChNames, st.stimSiteNames{1}));
            indTrialToExclude=[];
            trialsToExclude = channInfo.trialsToExcludeWakeEMU{iStimCh};
            for iTrial=1:length(trialsToExclude)
                indTrialToExclude = [indTrialToExclude, find(cfgInfoPlot.trialsToPlot==trialsToExclude(iTrial))];
                cfgInfoPlot.trialsToPlot(indTrialToExclude)=[];
            end
        end
        % get responsive channels
         cfgInfoPlot.lstResponsiveChannel=[];
        if ~isempty(stimSiteNamesAllStim)
            indStimInRespChLst = find(strcmpi(stimSiteNamesAllStim(1,:), st.stimSiteNames{1}));
            if ~isempty(indStimInRespChLst)
                cfgInfoPlot.lstResponsiveChannel = [lstResponsiveChannelAllStim{indStimInRespChLst}];
            end
        end
        % Plot all CCEP for all files
        plotAllCCEPPerElectrode(EEGStimTrialMATfile, dirImages, whatToUse, cfgInfoPlot);
        disp([cfgInfoPlot.titName, 'File ',EEGStimTrialMATfile, ' plotted!'])
    end
end
close all;

%% Sleep EMU
for iFile=1:length(fileNamesSleep)
    EEGStimTrialMATfile =fileNamesSleep{iFile};
    if ~isempty(EEGStimTrialMATfile)
        cfgInfoPlot.titName = [num2str(iFile),'Sleep'];
        % Organize trials
        cfgInfoPlot.trialsToPlot = channInfo.trialsSleep;
        % Get Stim information
        st = load(EEGStimTrialMATfile,'stimSiteNames'); %load only stim names
        % remove trial exclusions (make sure that there is a corresponding stim bipolar
        if ~isempty(channInfo.trialsToExcludeSleep)
            iStimCh = find(contains(channInfo.stimBipChNames, st.stimSiteNames{1}));
            indTrialToExclude=[];
            trialsToExclude = channInfo.trialsToExcludeSleep{iStimCh};
            for iTrial=1:length(trialsToExclude)
                indTrialToExclude = [indTrialToExclude, find(cfgInfoPlot.trialsToPlot==trialsToExclude(iTrial))];
                cfgInfoPlot.trialsToPlot(indTrialToExclude)=[];
            end
        end
        % get responsive channels
         cfgInfoPlot.lstResponsiveChannel=[];
        if ~isempty(stimSiteNamesAllStim)
            indStimInRespChLst = find(strcmpi(stimSiteNamesAllStim(1,:), st.stimSiteNames{1}));
            if ~isempty(indStimInRespChLst)
                cfgInfoPlot.lstResponsiveChannel = [lstResponsiveChannelAllStim{indStimInRespChLst}];
            end
        end
        % Plot all CCEP for all files
        plotAllCCEPPerElectrode(EEGStimTrialMATfile, dirImages, whatToUse, cfgInfoPlot);
        disp([cfgInfoPlot.titName, 'File ',EEGStimTrialMATfile, ' plotted!'])
    end
end
close all;
