function [dataPerCh, chNamesSelected, iChToAnalyse] = organizeiEEGChannels(dataPerAllCh, chNamesAll, chNamesToExclude, stimSiteNames)

if ~exist('stimSiteNames','var'), stimSiteNames=[];end

%% Separate scalp from iEEG and Keep only useful channels (remove bipolar of different shafts, AINPs)
iChToAnalyse=1; 
dataPerCh = []; 
chNamesSelected = [];  
nAllChannels = numel(chNamesAll);
for iCh=1:nAllChannels
    contacts = split(chNamesAll{iCh},'-');
    indContactName = regexp(upper(contacts),'[A-Z]','start');
    
    keepChannel =1; % whether to keep data as iEEG channel
    % Decide if keeping this channel for bipolar consecutive
    if (length(contacts)== 2) && (length(indContactName{1})~=length(indContactName{2}) || ~ strcmpi(contacts{1}(indContactName{1}),contacts{2}(indContactName{2}))) % To ONLY consider Bipolar channels within shaft
        keepChannel=0;
    end
    % Exclude Stimulation channels
    for iStim=1:length(stimSiteNames)
        if any([strcmpi(contacts, stimSiteNames{iStim}{1});strcmpi(contacts, stimSiteNames{iStim}{2})])
            keepChannel=0;
        end
    end
    
    % remove specific channels
    for iChExclude=1:numel(chNamesToExclude)
        if  any((strncmpi(contacts, chNamesToExclude{iChExclude},length(chNamesToExclude{iChExclude}))))
            keepChannel=0;
        end
    end
    
    if keepChannel
        dataPerCh(:,iChToAnalyse) = dataPerAllCh(:,iCh);
        chNamesSelected{iChToAnalyse} = chNamesAll{iCh};
        iChToAnalyse =iChToAnalyse+1;
    end
end

nChannels = size(dataPerCh,2);

