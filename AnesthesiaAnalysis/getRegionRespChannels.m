function [anatRegionsRespChPerState, anatRegionsStimChPerState, anatRegionsPerChPerState, gralRegionsRespChPerState, gralRegionsStimChPerState, gralRegionsPerChPerState, chNamesRespPerState, chNamesPerState, stimSitesPerState, pNamesPerState, anatLabels, labelPerRegion] = getRegionRespChannels(fileNameRespChAllPatAllStates, stimChWithRespPerPat)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

if ~exist('stimChWithRespPerPat','var'), stimChWithRespPerPat = [];end % specify channels to keep - it is used to keep chanels with enough resp channels in any state

nRespPerStatePerPat = cell(nStates, nPatients);
stimSitesPerStatePerPat = cell(nStates, nPatients);
nRespPerState = cell(nStates, 1);

stimSitesPerState = cell(nStates, 1);
anatRegionsRespChPerState = cell(nStates, 1);
RASCoordRespChPerState = cell(nStates, 1);
anatRegionsPerChPerState = cell(nStates, 1);
RASCoordPerChPerState = cell(nStates, 1);
anatRegionsStimChPerState = cell(nStates, 1);
RASCoordPerChStimChPerState = cell(nStates, 1);
gralRegionsRespChPerState = cell(nStates, 1);
gralRegionsStimChPerState = cell(nStates, 1);
gralRegionsPerChPerState = cell(nStates, 1);
chNamesPerState = cell(nStates, 1);
chNamesRespPerState = cell(nStates, 1);
pNamesPerState  = cell(nStates, 1);
for iState=1:nStates
    nRespPerState{iState}=[];
    for iP=1:nPatients
        fileNameToLoad = fileNameRespChAllPatAllStates{iP, iState};
        stState = load(fileNameToLoad);
        if any(stState.nRespCh>0)
            indStimChData = find(~cellfun(@isempty, stState.stimSiteNames));
            nRespPerStatePerPat{iState, iP} = stState.nRespCh;
            stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames;
  %          pNamesPerState{iState} = [pNamesPerState{iState},repmat({stState.channInfo.pName},1,length(indStimChData))];
            for iStim=1:length(indStimChData)
                bipStimCh = strcat(stState.channInfoRespCh{indStimChData(iStim)}(1).stimSiteNames{2},'-',stState.channInfoRespCh{indStimChData(iStim)}(1).stimSiteNames{1});
                if isempty(stimChWithRespPerPat) || any(strcmpi(bipStimCh, stimChWithRespPerPat{iP})) % this channel is one of the responsive in any state
                    nRespPerState{iState} = [nRespPerState{iState},stState.nRespCh(indStimChData(iStim))'];
                    % Find region of Responsive channels and stim
                    chInfoRespPerStimCh = stState.channInfoRespCh{iStim}(1);
                    anatRegionsRespChPerState{iState} = [anatRegionsRespChPerState{iState}, {chInfoRespPerStimCh.anatRegionsResp}];
                    anatRegionsStimChPerState{iState} = [anatRegionsStimChPerState{iState}, chInfoRespPerStimCh.anatRegionsStimCh];
                    anatRegionsPerChPerState{iState} = [anatRegionsPerChPerState{iState}, chInfoRespPerStimCh.anatRegionsPerCh];
                    anatLabels = chInfoRespPerStimCh.cfgInfoPlot.targetLabels;
                    % Get RAS info
                    RASCoordRespChPerState{iState} = [RASCoordRespChPerState{iState}, {chInfoRespPerStimCh.RASCoordResp}];
                    RASCoordPerChPerState{iState} = [RASCoordPerChPerState{iState}; chInfoRespPerStimCh.RASCoordPerChStimCh];
                    RASCoordPerChStimChPerState{iState} = [RASCoordPerChStimChPerState{iState}; chInfoRespPerStimCh.RASCoordPerChStimCh];
                    % find general region per channels
                    [gralRegionPerCh, stChannelPerRegion, labelPerRegion] = getGralRegionPerChannel(chInfoRespPerStimCh.anatRegionsResp);
                    gralRegionsRespChPerState{iState} = [gralRegionsRespChPerState{iState}, stChannelPerRegion];
                    [gralRegionPerCh, stChannelPerRegion] = getGralRegionPerChannel(chInfoRespPerStimCh.anatRegionsStimCh);
                    gralRegionsStimChPerState{iState} = [gralRegionsStimChPerState{iState}, stChannelPerRegion];
                    [gralRegionPerCh, stChannelPerRegion] = getGralRegionPerChannel(chInfoRespPerStimCh.anatRegionsPerCh);
                    gralRegionsPerChPerState{iState} = [gralRegionsPerChPerState{iState}, stChannelPerRegion];
                    
                    chNamesPName = strcat(chInfoRespPerStimCh.lstResponsiveChannel,'_',stState.channInfo.pName);
                    chNamesRespPerState{iState} = [chNamesRespPerState{iState}, {chNamesPName}];
                    chNamesPName = strcat(chInfoRespPerStimCh.chNamesSelected,'_',stState.channInfo.pName);
                    chNamesPerState{iState} = [chNamesPerState{iState}, chNamesPName];
                    
                    stimPName = strcat(bipStimCh,'_',stState.channInfo.pName);
                    stimSitesPerState{iState} = [stimSitesPerState{iState}, {stimPName}];
                    pNamesPerState{iState} = [pNamesPerState{iState},{stState.channInfo.pName}];              
                end
            end
        end
    end
end