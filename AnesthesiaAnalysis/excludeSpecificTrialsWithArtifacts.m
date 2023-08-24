function [newEEGStimTrialMATfile, trialsToExcludeAllCh, trialsToExcludePerCh] = excludeSpecificTrialsWithArtifacts(EEGStimTrialMATfile, newEEGStimTrialMATfile, trialsToExcludeAllCh, trialsToExcludePerCh)

%% Trials to EXCLUDE - per Channel
% Exclude trials specified in trials to exclude
% In this case trials are excluded for ALL channels

%% COnfig
if ~exist('newEEGStimTrialMATfile','var') || isempty(newEEGStimTrialMATfile)
    newEEGStimTrialMATfile= [EEGStimTrialMATfile(1:end-4),'_Clean','.mat'];
end 

if ~exist('trialsToExcludeAllCh','var'), trialsToExcludeAllCh=[]; end
if ~exist('trialsToExcludePerCh','var'), trialsToExcludePerCh=cell(0,0); end

%% Copy file if new name
if ~strcmpi(EEGStimTrialMATfile, newEEGStimTrialMATfile)
    copyfile(EEGStimTrialMATfile, newEEGStimTrialMATfile);
end

% return if nothing to exclude
if isempty(trialsToExcludeAllCh) && ~any(cellfun(@isempty,trialsToExcludePerCh))
    return;
end

%% Load data
stEEGStimTrial = load(EEGStimTrialMATfile);
stimSitesFromLog = stEEGStimTrial.stimSitesFromLog;
allChNamesReferential = stEEGStimTrial.allChNamesReferential;
chNamesSelected = stEEGStimTrial.chNamesSelected;
EEGStimTrialsOrig = stEEGStimTrial.EEGStimTrials;
perTrialNormEEGStimOrig = stEEGStimTrial.perTrialNormEEGStim;
indBaselinePerTrial = stEEGStimTrial.infoBaseline.indBaselinePerTrial;
%zNormEEGStimOrig = stEEGStimTrial.zNormEEGStim;
%zNormZeroMeanEEGStimOrig = stEEGStimTrial.zNormZeroMeanEEGStim;
indPerSite{1} = stEEGStimTrial.indPerSite{1}; %trial number that correspond to these data
indTimePerStimPerSite{1} = stEEGStimTrial.indTimePerStimPerSite{1}; %time of each stim that correspond to these data
nStim =length(indTimePerStimPerSite{1});

%% Remove trials with Artifcats artifacts
nChannels = length(chNamesSelected);
EEGStimTrials=cell(1,nChannels);
perTrialNormEEGStim=cell(1,nChannels);
zNormEEGStim=cell(1,nChannels);
zNormZeroMeanEEGStim=cell(1,nChannels);
for iCh =1: nChannels
    trialsToKeep=1:size(EEGStimTrialsOrig{iCh},2);
    trialsToExcThisCh = unique([trialsToExcludeAllCh'; trialsToExcludePerCh{iCh}]);% general trials to exclude + channel specific trials to exclude (e.g. from stim srtifact relying)
    trialsToKeep(intersect(trialsToKeep, trialsToExcThisCh))=[]; 
    EEGStimTrials{iCh} = EEGStimTrialsOrig{iCh}(:,trialsToKeep);
    % Compute perTrial Normalized considering only the clean trials and the mean baseline signal
  %  meanBaselineEEG = mean(EEGStimTrials{iCh}(indBaselinePerTrial,:),2);
    allBaselineEEG = EEGStimTrials{iCh}(indBaselinePerTrial,:);
    perTrialNormEEGStim{iCh} = (EEGStimTrials{iCh} - mean(allBaselineEEG(:))) ./ std(allBaselineEEG(:)) ;
%    perTrialNormEEGStim{iCh} = perTrialNormEEGStimOrig{iCh}(:,trialsToKeep);
   % zNormEEGStim{iCh} = zNormEEGStimOrig{iCh}(:,trialsToKeep);
   % zNormZeroMeanEEGStim{iCh} = zNormZeroMeanEEGStimOrig{iCh}(:,trialsToKeep);
end

indPerSite{1}(intersect([1:nStim],trialsToExcludeAllCh))=[];
indTimePerStimPerSite{1}(intersect([1:nStim],trialsToExcludeAllCh))=[];

%% save new file
save(newEEGStimTrialMATfile,'EEGStimTrials','perTrialNormEEGStim','zNormEEGStim','zNormZeroMeanEEGStim',...
    'trialsToExcludeAllCh','trialsToExcludePerCh','indPerSite','indTimePerStimPerSite','-append');


