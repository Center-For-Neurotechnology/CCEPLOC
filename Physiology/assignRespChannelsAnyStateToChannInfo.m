function [channInfo respChInfo] = assignRespChannelsAnyStateToChannInfo (lstResponsiveChannelMATfiles, channInfo)

if ~exist('channInfo','var'),channInfo=struct();end
if ~isfield(channInfo,'stimBipChNames') && ~isfield(channInfo,'stimChNames')
    channInfo.stimChNames = [];
    channInfo.stimBipChNames = [];
elseif isfield(channInfo,'stimBipChNames') && ~isfield(channInfo,'stimChNames')
    channInfo.stimChNames = squeeze([split(channInfo.stimBipChNames,'-')])';
elseif ~isfield(channInfo,'stimBipChNames') && isfield(channInfo,'stimChNames') && ~isempty(channInfo.stimChNames)
    channInfo.stimBipChNames = strcat(channInfo.stimChNames(2,:),'-',channInfo.stimChNames(1,:));
end
if ~isfield(channInfo,'excludedChannels'),  channInfo.excludedChannels=[];end
if ~isfield(channInfo,'excludeChannelsInShaft'), channInfo.excludeChannelsInShaft = 0;end

% reorganize/complete  channInfo.excludedChannels
excludedChannels = channInfo.excludedChannels;
if ~isempty(excludedChannels)
    indExcChWholeShaft = find(cellfun(@isempty,regexp(channInfo.excludedChannels,'\d')));
    excludedChannels(indExcChWholeShaft)=[];
    % add all the number  of the shaft
    for iCh=1: length(indExcChWholeShaft)
        % if only electrode name -> add all the number
        excludedChannels = [excludedChannels, strcat(channInfo.excludedChannels{indExcChWholeShaft(iCh)},cellfun(@num2str,num2cell(1:16),'UniformOutput',false))];
    end
    
    % add 01 /1 combinations
    indStimChWithout0 = find(cellfun(@length,regexp(excludedChannels,'\d{1,1}'))<2);
    for iCh=1:length(indStimChWithout0)
        indNumber = regexp(excludedChannels{indStimChWithout0(iCh)},'\d'); % not taking 9-10 into accoount!
        excludedChannels = [excludedChannels, strcat(excludedChannels{indStimChWithout0(iCh)}(1:indNumber-1),'0',excludedChannels{indStimChWithout0(iCh)}(indNumber:end))];
    end
    excludedChannels = unique([excludedChannels, regexprep(excludedChannels,'0(?=\d)','')]);
end

% read resp ch file to get stim ch
lstResponsiveChannelAllStates=[];
stimChNamesInFile=[];
channInfoRespCh=[];
nRespChPerStimCh=[];
whichState=[];
allChNamesSelected=cell(0,0);
for iFile=1:length(lstResponsiveChannelMATfiles)
    stRespCh = load(lstResponsiveChannelMATfiles{iFile});
    if ~isempty(stRespCh.stimSiteNames)
        channInfoRespChPerFileTemp = [stRespCh.channInfoRespCh{:,1}];
        % only keep 1 stimChannel (in case there are more than 1 in the same state
        stimNamesInStruct = [channInfoRespChPerFileTemp.stimSiteNames];
        [uniqueChStim1, indIn1, indInUnique] = unique(stimNamesInStruct(1,:),'stable');
        [uniqueChStim2, indIn2, indInUnique] = unique(stimNamesInStruct(2,:),'stable');
        indChUnique = intersect(indIn1,indIn2);
        channInfoRespChPerFile = channInfoRespChPerFileTemp(indChUnique);
        % Assign only the kept stimChannels
        lstResponsiveChannelAllStates = [lstResponsiveChannelAllStates,{channInfoRespChPerFile.lstResponsiveChannel}];
        channInfoRespCh = [channInfoRespCh, channInfoRespChPerFile];
        nRespChPerStimCh = [nRespChPerStimCh, cellfun(@length, {channInfoRespChPerFile.lstResponsiveChannel})]; %stRespCh.nRespCh'];
        %stimChNamesInFile = stRespCh.stimSiteNames;
        stimChNamesInFile = [stimChNamesInFile, [channInfoRespChPerFile.stimSiteNames]];
        whichState = [whichState, repmat({stRespCh.thisState}, 1, length(stRespCh.nRespCh))];
        allChNamesSelected = unique([allChNamesSelected, channInfoRespChPerFile.chNamesSelected]);
    end
end

% Assign all stim channels present in 2 STATES if stimChNames is empty
if isempty(channInfo.stimChNames)    
    [uniqueChStim, indInChInfo, indInUnique] = unique(strcat(stimChNamesInFile(2,:),'-',stimChNamesInFile(1,:)),'stable');
    nStatePerStimCh = histc(indInUnique, unique(indInUnique)); % histcounts does not work becasue does not consider the last one - combines them!
    % Keep only those stim channels with at least minRespCh in ANY state
    if isfield(channInfo,'minNumberRespCh') && ~isempty(channInfo.minNumberRespCh)
        indChWithRepCh = unique(indInUnique(nRespChPerStimCh>=channInfo.minNumberRespCh));
        indStimChToKeepNResp = intersect(find(nStatePerStimCh>1), indChWithRepCh);
    else
        indStimChToKeepNResp = find(nStatePerStimCh>1);
    end
    % remove stim channels as specified - useful to remove stim in SOZ channels
    indStimChNotToExclude=1:length(uniqueChStim);
    if ~isempty(excludedChannels)
        indStimChToExclude = [];
        for iStim=1:length(uniqueChStim)
            contacts = split(uniqueChStim{iStim},'-');
            for iCont=1:length(contacts)
                if any(strcmpi(contacts{iCont}, excludedChannels))
                    indStimChToExclude = [indStimChToExclude, iStim];
                end
            end
        end
        indStimChNotToExclude(indStimChToExclude)=[];
        channInfo.indStimChToExclude = indStimChToExclude;
    end
    indStimChToKeep = intersect(indStimChToKeepNResp, indStimChNotToExclude);
    channInfo.stimBipChNames = uniqueChStim(indStimChToKeep); % only keep channels with STIM in >=2 states 
   % channInfo.stimChNames = squeeze([split(channInfo.stimBipChNames,'-')])';
   channInfo.stimChNames = reshape([split(channInfo.stimBipChNames,'-')],[length(indStimChToKeep),2])';
   channInfo.allStimBipChNames = uniqueChStim; % Keep all for future reference
   channInfo.indStimChToKeep = indStimChToKeep;
end

recBipolarChPerStimWResp = cell(1,size(channInfo.stimChNames,2));
respChInfo = cell(1,size(channInfo.stimChNames,2));
recBipChInStimShaft = cell(1,size(channInfo.stimChNames,2));
for iStim = 1: size(stimChNamesInFile,2)
    stimChNameInFile = stimChNamesInFile(:,iStim);
    % find in channInfo
    [~, indStimChInChInfo1] = find(strcmpi(channInfo.stimChNames, stimChNameInFile{1}));
    [~, indStimChInChInfo2] = find(strcmpi(channInfo.stimChNames, stimChNameInFile{2}));
    indStimChInChInfo = intersect(indStimChInChInfo1, indStimChInChInfo2);
    if ~isempty(indStimChInChInfo)
        recBipolarChPerStimWRespTemp = unique([recBipolarChPerStimWResp{indStimChInChInfo},lstResponsiveChannelAllStates{iStim}]);
        respChInfo{indStimChInChInfo} = [respChInfo{indStimChInChInfo},channInfoRespCh(iStim)]; % reorganize also info about the resp channels
        % Remove specified channels
        recBipolarChPerStimWResp{indStimChInChInfo} = excludeSpecificChannels(recBipolarChPerStimWRespTemp, channInfo.excludedChannels);
        %Assign if channel in stim electrode
        [recBipChInStimShaft{indStimChInChInfo}, uniqueElectStim] = isChannelInStimShaft(recBipolarChPerStimWResp{indStimChInChInfo}, stimChNameInFile);
    end
end


% Remove specified channels - usually the ones in the same shaft
for iStim = 1: numel(recBipolarChPerStimWResp)
    if channInfo.excludeChannelsInShaft
        % find corresponding Shaft and add to excluded channels
        [uniqueElect, indElecPerCh, nContactsPerElectrode] = getElectrodeNames(stimChNameInFile{1});
        [channelsInStimShaft, indStimChInChInfo1] = find(strncmpi(recBipolarChPerStimWResp, uniqueElect,length(uniqueElect)));
        excludedChannelsPerStim = [channInfo.excludedChannels, channelsInStimShaft];
    else
        excludedChannelsPerStim = channInfo.excludedChannels;
    end
    % Remove channels
    recBipolarChPerStimWResp{iStim} = excludeSpecificChannels(recBipolarChPerStimWResp{iStim}, excludedChannelsPerStim);
end

% remove excluded channels from chNamesSelected
indChToExclude=[];
for iCh=1:length(allChNamesSelected)
    contacts = split(allChNamesSelected{iCh},'-');
    for iCont=1:length(contacts)
        if any(strcmpi(contacts{iCont}, excludedChannels))
            indChToExclude = [indChToExclude, iCh];
        end
    end
end
indChToKeep=1:length(allChNamesSelected);
indChToKeep(indChToExclude)=[];
channInfo.indChToExclude = indChToExclude;
channInfo.indChToKeep = indChToKeep;
channInfo.chNamesSelected = allChNamesSelected(indChToKeep); % after excluding SOZ 

% assign responsive channels as bipolarRecChannels
channInfo.allChNamesSelected = allChNamesSelected;
channInfo.recBipolarChPerStim = recBipolarChPerStimWResp;
channInfo.recBipChInStimShaft = recBipChInStimShaft;
% add also general info about the responsive channel (e.g. p2p amp)
%channInfo.respChInfo = respChInfo;