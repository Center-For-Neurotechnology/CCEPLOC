function [chNamesToKeep, indExcludedChannels, EEGStimDataToKeep] = excludeSpecificChannels(chNames, excludeChNames, EEGStimData)

if ~iscell(excludeChNames), excludeChNames = {excludeChNames};end
if ~exist('EEGStimData','var'), EEGStimData = cell(0,0);end
indExcludedChannels = [];
chNamesToKeep = chNames;
EEGStimDataToKeep = EEGStimData;
if isempty(chNames)
    return;
end
    
for iCh=1:numel(excludeChNames)
    chToExclude = excludeChNames{iCh};
    indExcludeCh = find(~cellfun(@isempty,strfind(chNames, chToExclude)));
    indExcludedChannels = [indExcludedChannels, indExcludeCh];    
end
indExcludedChannels = unique(indExcludedChannels);

% Keep channels that are not excluded
for iCh=length(indExcludedChannels):-1:1 % Start from the back otherwise we change the  number do not correspond to the real location!
    chNamesToKeep(indExcludedChannels(iCh))=[];
end


% Keep EEG data from channels that are not excluded
if ~isempty(EEGStimData)
    for iCh=length(indExcludedChannels):-1:1 % Start from the back otherwise we change the  number do not correspond to the real location!
        EEGStimDataToKeep(indExcludedChannels(iCh)) = [];
    end
end


