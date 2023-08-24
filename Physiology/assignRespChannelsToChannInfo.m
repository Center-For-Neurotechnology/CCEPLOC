function [channInfo] = assignRespChannelsToChannInfo (lstResponsiveChannelMATfile, channInfo)

if ~exist('channInfo','var'),channInfo=[];end

stRespCh = load(lstResponsiveChannelMATfile);

lstResponsiveChannel = stRespCh.lstResponsiveChannel_AveragePerTrial;
channInfoRespCh = stRespCh.channInfoRespCh;
%stimChNamesInFile = stRespCh.stimSiteNames;
stimChNamesInFile = split(stRespCh.stimSiteNames,'-')';%[stRespCh.channInfoRespCh_AveragePerTrial.stimSiteNames];
if isfield(channInfo,'stimBipChNames') && ~isfield(channInfo,'stimChNames')
    channInfo.stimChNames = squeeze([split(channInfo.stimBipChNames,'-')])';
end
if ~isfield(channInfo,'excludedChannels'), channInfo.excludedChannels = [];end

recBipolarChPerStimWResp = cell(1,size(channInfo.stimChNames,2));
respChInfo = cell(1,size(channInfo.stimChNames,2));
for iStim = 1: size(stimChNamesInFile,2)
    stimChNameInFile = stimChNamesInFile(:,iStim);
    % find in channInfo
    [~, indStimChInChInfo1] = find(strncmpi(channInfo.stimChNames, stimChNameInFile{1}));
    [~, indStimChInChInfo2] = find(strncmpi(channInfo.stimChNames, stimChNameInFile{2}));
    indStimChInChInfo = intersect(indStimChInChInfo1, indStimChInChInfo2);
    recBipolarChPerStimWResp{indStimChInChInfo} = [ recBipolarChPerStimWResp{indStimChInChInfo},lstResponsiveChannel{iStim}];
    respChInfo{indStimChInChInfo} = [respChInfo{indStimChInChInfo},channInfoRespCh{iStim}]; % reorganize also info about the resp channels
end

% Remove specified channels
for iStim = 1: numel(recBipolarChPerStimWResp)
    recBipolarChPerStimWResp{iStim} = excludeSpecificChannels(recBipolarChPerStimWResp{iStim}, channInfo.excludedChannels);
end

% assign responsive channels as bipolarRecChannels
channInfo.recBipolarChPerStim = recBipolarChPerStimWResp;
% add also general info about the responsive channel (e.g. p2p amp)
channInfo.respChInfo = respChInfo;