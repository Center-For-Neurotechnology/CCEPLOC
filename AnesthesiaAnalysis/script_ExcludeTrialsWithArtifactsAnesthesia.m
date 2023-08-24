function  [fileNameAllChMATfilesClean, channInfo] = script_ExcludeTrialsWithArtifactsAnesthesia(fileNameAllChMATfiles, channInfo)

distInSecFromSTIM = 7.5; % at least 7.5 seconds between STIM to ensure the amps settled 
stateNames = {'WakeEMU', 'Sleep', 'WakeOR', 'Anesthesia'};

[dirName, onlyFileName] = fileparts(fileNameAllChMATfiles);
dirNameClean = [dirName, filesep,'Clean20']; %Clean50
if ~exist(dirNameClean,'dir'), mkdir(dirNameClean); end
fileNameAllChMATfilesClean = [dirName, filesep, onlyFileName,'_Clean','.mat'];
logFile = [dirNameClean,filesep,'cleanScript',channInfo.pName,'_',date,'.log'];
diary(logFile)

%% Files and Directories
[fileNames.Anesthesia, fileNames.WakeOR, fileNames.WakeEMU, fileNames.Sleep] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameAllChMATfiles,[],[],channInfo);

%% Find channel names
if isfield(channInfo, 'stimChNames')
    chInfoStimChNames = channInfo.stimChNames(1,:);
else
    chInfoStimChNames = []; % if empty we will use the order in the file
end
nChStim = length(chInfoStimChNames);

%% Trials to exclude - reorganize
if ~isfield(channInfo,'trialsToExclude'), channInfo.trialsToExclude=[];end
for iState=1:length(stateNames)
    if ~isfield(channInfo.trialsToExclude,stateNames{iState}), channInfo.trialsToExclude.(stateNames{iState}) = cell(1,max(nChStim,length(fileNames.(stateNames{iState})))); end
    if ~iscell(channInfo.trialsToExclude.(stateNames{iState})), channInfo.trialsToExclude.(stateNames{iState}) = repmat({channInfo.trialsToExclude.(stateNames{iState})},1,length(fileNames.(stateNames{iState}))); end
end

%% Remove artifacts
stimChNamesAllStates=[];
for iState=1:length(stateNames)
    fileNamesPerState = fileNames.(stateNames{iState});
    EEGStimTrialMATfilePerState.(stateNames{iState}) =cell(1,length(fileNamesPerState));
    if ~isempty(fileNamesPerState)
        for iFile=1:length(fileNamesPerState)
            if ~isempty(fileNamesPerState{iFile})
                stInfo = load(fileNamesPerState{iFile},'stimSiteNames');
                if ~isempty(chInfoStimChNames)
                    indStimCh = find(strcmpi(chInfoStimChNames, stInfo.stimSiteNames{1,1}));
                else
                    indStimCh = iFile;
                end
                [EEGStimTrialMATfileClean, trialsToExcludeAllCh, trialsToExcludePerCh] = excludeTrialsWithArtifactsAllTrialsTogether(fileNamesPerState{iFile}, dirNameClean, channInfo.trialsToExclude.(stateNames{iState}){indStimCh}, distInSecFromSTIM);
  %              [EEGStimTrialMATfileClean, trialsToExclude] = excludeTrialsWithArtifacts(fileNamesPerState{iFile}, dirNameClean, channInfo.trialsToExclude.(stateNames{iState}){indStimCh}, distInSecFromSTIM);
                EEGStimTrialMATfilePerState.(stateNames{iState}){iFile} = EEGStimTrialMATfileClean;
                stimChNamesAllStates = [stimChNamesAllStates, stInfo.stimSiteNames];
             %   trialsToExclude.trialsToExcludeAllCh{iState}{iFile} = trialsToExcludeAllCh;
             %   trialsToExclude.trialsToExcludePerCh{iState}{iFile} = trialsToExcludePerCh;
            end
        end
    end
    
end

%% All chStim
if ~isfield(channInfo, 'stimChNames')
    [unStimCh, indInUnique, indInAll] = unique(stimChNamesAllStates(1,:)); % assumes consequetive channels!!!!
    channInfo.stimChNames = [stimChNamesAllStates(1,indInUnique); stimChNamesAllStates(2,indInUnique)];
end

%% Save all together
% bad hack to keep names are they are... it should be changed all over 
EEGStimTrialMATfileAnest = EEGStimTrialMATfilePerState.Anesthesia;
EEGStimTrialMATfileWakeOR = EEGStimTrialMATfilePerState.WakeOR;
EEGStimTrialMATfileWakeEMU = EEGStimTrialMATfilePerState.WakeEMU;
EEGStimTrialMATfileSleep = EEGStimTrialMATfilePerState.Sleep;
% Save
copyfile(fileNameAllChMATfiles, fileNameAllChMATfilesClean)
save(fileNameAllChMATfilesClean,'EEGStimTrialMATfileAnest','EEGStimTrialMATfileWakeOR','EEGStimTrialMATfileWakeEMU','EEGStimTrialMATfileSleep','EEGStimTrialMATfilePerState',...
                                'stimChNamesAllStates', 'channInfo','trialsToExcludeAllCh','trialsToExcludePerCh','-append');

%% remove trials to exclude from channelInfo - already removed!
for iState=1:length(stateNames)
    channInfo.trialsToExclude.(stateNames{iState}) = [];
end

diary('off')
