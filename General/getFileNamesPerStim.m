function [EEGStimTrialMATfilePerStim, unStimSites] = getFileNamesPerStim(EEGStimTrialMATfile)

stimChNamesPerFile = cell(length(EEGStimTrialMATfile),1);
for iFile=1:length(EEGStimTrialMATfile)
    if ~isempty(EEGStimTrialMATfile{iFile})
        st = load(EEGStimTrialMATfile{iFile},'stimSiteNames');
        stimChNamesPerFile{iFile} = st.stimSiteNames{1,1}; % USE ONLY first channel of stim!
    else
        stimChNamesPerFile{iFile} = '';
    end
end

unStimSites = unique(stimChNamesPerFile);
unStimSites(find(strcmp(unStimSites,'')))=[]; % remove empty ones

EEGStimTrialMATfilePerStim = cell(0,0);
for iStim=1:numel(unStimSites)
    indInFile = find(strcmp(stimChNamesPerFile,unStimSites{iStim}));
    EEGStimTrialMATfilePerStim{iStim} = {EEGStimTrialMATfile{indInFile}};
end

