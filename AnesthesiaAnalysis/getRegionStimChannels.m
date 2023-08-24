function [anatRegionsStimChPerState, anatRegionsPerChPerState, gralRegionsStimChPerState, gralRegionsPerChPerState, chNamesPerState, stimSitesPerState, pNamesPerState, anatLabels] = getRegionStimChannels(fileNameRespChAllPatAllStates, stimChWithRespPerPat)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

%nRespPerStatePerPat = cell(nStates, nPatients);
stimSitesPerStatePerPat = cell(nStates, nPatients);
%nRespPerState = cell(nStates, 1);

stimSitesPerState = cell(nStates, 1);
anatRegionsPerChPerState = cell(nStates, 1);
RASCoordPerChPerState = cell(nStates, 1);
anatRegionsStimChPerState = cell(nStates, 1);
RASCoordPerChStimChPerState = cell(nStates, 1);
gralRegionsStimChPerState = cell(nStates, 1);
gralRegionsPerChPerState = cell(nStates, 1);
chNamesPerState = cell(nStates, 1);
pNamesPerState  = cell(nStates, 1);
for iState=1:nStates
   % nRespPerState{iState}=[];
    for iP=1:nPatients
        fileNameToLoad = fileNameRespChAllPatAllStates{iP, iState};
        stState = load(fileNameToLoad);
        if (isfield(stState,'nRespCh') && any(stState.nRespCh>0)) || (isfield(stState,'PCIstPerStimCh') && ~isempty(stState.PCIstPerStimCh))
            indStimChData = find(~cellfun(@isempty, stState.stimSiteNames));
      %      nRespPerState{iState} = [nRespPerState{iState},stState.nRespCh(indStimChData)'];
       %     nRespPerStatePerPat{iState, iP} = stState.nRespCh;
%        pNamesPerState{iState} = [pNamesPerState{iState},repmat({stState.channInfo.pName},1,length(indStimChData))];
%        stimSitesPerState{iState} = [stimSitesPerState{iState}, stState.stimSiteNamePNames'];
           stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames;
            for iStim=1:length(indStimChData)
                % Find region of Responsive channels and stim
                if isfield(stState,'channInfoRespCh'), chInfoPerStimCh = stState.channInfoRespCh{iStim}(1);
                elseif isfield(stState,'channInfoPCIPerStimCh'), chInfoPerStimCh = stState.channInfoPCIPerStimCh{iStim}(1);
                else, disp('NO field with per stim chan info found - Exiting!'); return;
                end
                bipStimCh = strcat(chInfoPerStimCh.stimSiteNames{2},'-',chInfoPerStimCh.stimSiteNames{1});
                if isempty(stimChWithRespPerPat) || any(strcmpi(bipStimCh, stimChWithRespPerPat{iP})) % this channel is one of the responsive in any state
                    chNamesPerState{iState} = [chNamesPerState{iState}, chInfoPerStimCh.chNamesSelected];
                    anatRegionsStimChPerState{iState} = [anatRegionsStimChPerState{iState}, chInfoPerStimCh.anatRegionsStimCh];
                    anatRegionsPerChPerState{iState} = [anatRegionsPerChPerState{iState}, chInfoPerStimCh.anatRegionsPerCh];
                    anatLabels = chInfoPerStimCh.cfgInfoPlot.targetLabels;
                    % Get RAS info
                    RASCoordPerChPerState{iState} = [RASCoordPerChPerState{iState}; chInfoPerStimCh.RASCoordPerChStimCh];
                    RASCoordPerChStimChPerState{iState} = [RASCoordPerChStimChPerState{iState}; chInfoPerStimCh.RASCoordPerChStimCh];
                    % find general region per channels
                    [gralRegionPerCh, stChannelPerRegion] = getGralRegionPerChannel(chInfoPerStimCh.anatRegionsStimCh);
                    gralRegionsStimChPerState{iState} = [gralRegionsStimChPerState{iState}, stChannelPerRegion];
                    [gralRegionPerCh, stChannelPerRegion] = getGralRegionPerChannel(chInfoPerStimCh.anatRegionsPerCh);
                    gralRegionsPerChPerState{iState} = [gralRegionsPerChPerState{iState}, stChannelPerRegion];
                    
                    stimPName = strcat(bipStimCh,'_',stState.channInfo.pName);
                    stimSitesPerState{iState} = [stimSitesPerState{iState}, {stimPName}];
                    pNamesPerState{iState} = [pNamesPerState{iState},{stState.channInfo.pName}];              
                end
            end
        end
    end
end