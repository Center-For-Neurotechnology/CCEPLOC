function [newEEGStimTrialMATfileClean, trialsToExcludeAllCh, indTrialsToExcludePerCh] = excludeTrialsWithArtifactsAllTrialsTogether(EEGStimTrialMATfile, newEEGStimTrialMATfileClean, trialsToExcludeInput, distInSecFromSTIM)

%% EXCLUDE specified trials and stim
% Exclude trials specified in trials to exclude
% In this case trials are excluded for ALL channels
% newEEGStimTrialMATfileClean could be a file or a directory
% if it is a directory filename is the same with _Clean posfix

%% CONFIG
if ~exist('newEEGStimTrialMATfileClean','var') || isempty(newEEGStimTrialMATfileClean)
    newEEGStimTrialMATfileClean= [EEGStimTrialMATfile(1:end-4),'_Clean','.mat'];
end 
if isfolder(newEEGStimTrialMATfileClean)
    [dirName, onlyFileName] = fileparts(EEGStimTrialMATfile);
    dirNameClean = newEEGStimTrialMATfileClean;
    if ~exist(dirNameClean,'dir'), mkdir(dirNameClean); end
    newEEGStimTrialMATfileClean = [dirNameClean, filesep, onlyFileName,'_Clean','.mat'];
end

if ~exist('distInSecFromSTIM','var'), distInSecFromSTIM=5; end % exclude 5 trials following stim 


%% Find STIM related artifacts to remove (for STIM channels) 
[indTrialsToExcludePerCh, trialsToExcludeFromTotal] = excludeTrialsWithSTIMartifact(EEGStimTrialMATfile, distInSecFromSTIM, dirNameClean);

%% Check Amplitude and remove trials with really large zscore amplitude (if some but not all trials are above threshold )
[trialsWithArtifacts, indChWithProblems, indLargeTrials, stimSiteName] = checkAmplitudeStimResponseIsNeuronal(EEGStimTrialMATfile, dirNameClean);
%trialsWithArtifacts=[];

%% Remove user-specified & artifact trials in all channels & stim ralying from specific channels
trialsToExcludeAllCh = [trialsToExcludeInput, trialsWithArtifacts];
[newEEGStimTrialMATfileClean, trialsToExclude] = excludeSpecificTrialsWithArtifacts(EEGStimTrialMATfile, newEEGStimTrialMATfileClean, trialsToExcludeAllCh, indTrialsToExcludePerCh);


disp(['File: ',newEEGStimTrialMATfileClean,' is clean'])
