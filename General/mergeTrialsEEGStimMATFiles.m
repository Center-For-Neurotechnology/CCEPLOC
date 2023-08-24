function newMATFileName = mergeTrialsEEGStimMATFiles(fileNameEEGStimTrial, newMATFileName, newTitName)
% Merge files for Anesthesia or Network data 
% files must contain different trials with the same channels
% Assumes that channel orfder is the same - RIZ: we might want to
% generalize this
%
% use mergeEEGStimMATFilesAllChannels for Decider data

if ~exist('newMATFileName','var'), newMATFileName=[]; end % newMATFileName could be a filename or a directory
if ~exist('newTitName','var'), newTitName=[]; end

%load first file to get all the common variables
load(fileNameEEGStimTrial{1});
nChannels = length(chNamesSelected);

if ~isempty(newTitName)
    titName = newTitName;
end
hdr.allFiles{1} = hdr;
infoBaseline.allFiles{1} = infoBaseline;
fileNameEEGStimAllTrials = fileNameEEGStimTrial; % save under a different name to store at the end

% store information of where each event is coming from
for iCh=1:length(chNamesSelected)
    indFileAllEv{iCh} = ones(1,size(EEGStimTrials{iCh},2));
end
chNamesSelectedInFile{1} = chNamesSelected;

% Add trials from all other files - ASSUME SAME CHANNELS
for iFile =2:numel(fileNameEEGStimTrial) %First one is already loaded
    %indStimFile = find(~cellfun(@isempty,strfind(fileNameEEGStimTrial, channInfo.stimBipChNames{iStim})));
    stEEGStim = load(fileNameEEGStimTrial{iFile});
    %  stimSiteNames = stEEGStim.stimSiteNames;
    chNamesSelectedInFile{iFile} = stEEGStim.chNamesSelected;
    if ~strcmp(chNamesSelectedInFile{iFile}, chNamesSelected) %compare to names of first file
        disp('WARNING:: channel names are different!')
    end
    % ASUME that channels are the same - USE ALL
    indSelCh = 1:length(chNamesSelectedInFile{iFile});
    
    for iCh=1:length(indSelCh)
        EEGStimTrials{iCh} = [EEGStimTrials{iCh}, stEEGStim.EEGStimTrials{indSelCh(iCh)}];
        zNormEEGStim{iCh} = [zNormEEGStim{iCh}, stEEGStim.zNormEEGStim{indSelCh(iCh)}];
        perTrialNormEEGStim{iCh} = [perTrialNormEEGStim{iCh}, stEEGStim.perTrialNormEEGStim{indSelCh(iCh)}];
        zNormZeroMeanEEGStim{iCh} = [zNormZeroMeanEEGStim{iCh}, stEEGStim.zNormZeroMeanEEGStim{indSelCh(iCh)}];
        
        indFileAllEv{iCh} = [indFileAllEv{iCh}, iFile*ones(1,size(stEEGStim.EEGStimTrials{indSelCh(iCh)},2))];
        
    end
    hdr.allFiles{iFile} = hdr;
    infoBaseline.allFiles{iFile} = infoBaseline;
    % Add stim info - also check that SAME STIM channel
    if strcmp(stimSiteNames{1}, stEEGStim.stimSiteNames{1}) && strcmp(stimSiteNames{2}, stEEGStim.stimSiteNames{2})
        indPerSite{1} = [indPerSite{1}; stEEGStim.indPerSite{1}+size(stimSitesFromLog,1)]; % add as consecutive stim - after the last stim of the previous file - must come before the next line that changes stimSitesFromLog
        stimSitesFromLog = [stimSitesFromLog; stEEGStim.stimSitesFromLog];
        indTimePerStimPerSite{1} = [indTimePerStimPerSite{1}, stEEGStim.indTimePerStimPerSite{1}+indTimeSTIM(end)]; % must come before the next line - otherwise indTimeStim is changed
        indTimeSTIM = [indTimeSTIM, stEEGStim.indTimeSTIM+indTimeSTIM(end)];
        %stWithStimInfo = [stWithStimInfo, stEEGStim.stWithStimInfo]; %THIS INFO SHOULD BE THE SAME - no need to add
    else
        disp(['WARNING::: Different STIM channels! ',stimSiteNames{1},'<>', stEEGStim.stimSiteNames{1}]);
    end
   
end

% compute mean and std baseline again
indBaselineStart = round(infoBaseline.tBaselinePerTrialStartSec*hdr.Fs);
indBaselineEnd = round(infoBaseline.tBaselinePerTrialEndSec*hdr.Fs);
for iCh=1:length(chNamesSelected)
    data = EEGStimTrials{iCh}(indBaselineStart:indBaselineEnd,:);
    [meanBaselinePerCh,  q25, q75, stdBaselinePerCh, stdErrorVal, medianVal] = meanQuantiles(data(:),1);
    meanBaseline(iCh) = meanBaselinePerCh;
    stdBaseline(iCh) = stdBaselinePerCh;
end
infoBaseline.meanBaseline = meanBaseline;
infoBaseline.stdBaseline = stdBaseline;

%% Save in new file
if isempty(newMATFileName)
    dirResults = fileparts(fileNameEEGStimTrial{1});
    newMATFileName = [dirResults, filesep, pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],'_bipEEG_StimTrials.mat']; % if nothing changed - at least titName SHOULD BE NEW 
end
if isfolder(newMATFileName)
    dirResults = newMATFileName;
    newMATFileName = [dirResults, filesep, pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],'_bipEEG_StimTrials.mat']; % if nothing changed - at least titName SHOULD BE NEW 
end  
copyfile(fileNameEEGStimTrial{1}, newMATFileName)
newPath = fileparts(newMATFileName);
if ~exist(newPath,'dir'), mkdir(newPath); end
save(newMATFileName, 'EEGStimTrials','zNormEEGStim','zNormZeroMeanEEGStim','perTrialNormEEGStim', ...
                     'stdBaseline','meanBaseline','infoBaseline','indFileAllEv','chNamesSelectedInFile',...
                     'stimSitesFromLog','indTimeSTIM','indPerSite','indTimePerStimPerSite',...
                     'hdr', 'titName','-append');

