function [stimSitesFromLog, stWithStimInfo] = readFileWithSTIMsitesPerTrial(fileNameStimSites)

stWithStimInfo=[];
stimSitesFromLog = [];
if isempty(fileNameStimSites)
    return;
end
%cellWithStimInfo=cell(0,0);
if contains(lower(fileNameStimSites),'.txt')
    [stimSitesFromLog] = readStimSiteFromTxtFile(fileNameStimSites);
elseif contains(lower(fileNameStimSites),'.mat') %assumes .mat file
    stStimSites = load(fileNameStimSites);
    if isfield(stStimSites,'stimSitesFromLog')
        stimSitesFromLog = stStimSites.stimSitesFromLog;
        stWithStimInfo = stStimSites.stWithStimInfo;
     %   cellWithStimInfo = stStimSites.cellWithStimInfo;
    elseif isfield(stStimSites,'stimchans') % directly use the original .mat file with stim info (only 2 columns with Cerestim ch number)
        stimSitesFromLog = stStimSites.stimchans;
        stimSitesFromLog = [[0:(size(stimSitesFromLog,1)-1)]',stimSitesFromLog];
    elseif isfield(stStimSites,'databystim') % use Older dataset to get stim channel 
        stimSitesFromLog = stStimSites.databystim{1}.stimchans';
        stimSitesFromLog = [stimSitesFromLog,stimSitesFromLog+1]; % add second channel (assuming it was the next one)
        stimSitesFromLog = [[0:(size(stimSitesFromLog,1)-1)]',stimSitesFromLog];
    end
else % if NO file Return empty and then ->USE ALL STIM
    stimSitesFromLog = [];
end
