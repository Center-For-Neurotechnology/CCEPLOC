function [newEEGStimTrialMATfileClean, trialsToExclude] = excludeTrialsWithArtifacts(EEGStimTrialMATfile, newEEGStimTrialMATfileClean, trialsToExclude, distInSecFromSTIM)

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
EEGStimTrialMATfileCleanSpecificTrials= newEEGStimTrialMATfileClean;

if ~exist('distInSecFromSTIM','var'), distInSecFromSTIM=5; end % exclude 5 trials following stim 


%% Remove specified trials with artifacts
[EEGStimTrialMATfileCleanSpecificTrials, trialsToExclude] = excludeSpecificTrialsWithArtifacts(EEGStimTrialMATfile, EEGStimTrialMATfileCleanSpecificTrials, trialsToExclude);

%% Remove STIM related artifacts (from channels 
[newEEGStimTrialMATfileClean, trialsToExcludePerCh] = excludeTrialsWithSTIMartifact(EEGStimTrialMATfileCleanSpecificTrials, newEEGStimTrialMATfileClean, distInSecFromSTIM);

disp(['File: ',newEEGStimTrialMATfileClean,' is clean'])


