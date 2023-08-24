function [RASCoordRespChPerState, RASCoordPerChStimChPerState,RASCoordPerChPerState,chNamesRespPerState, chNamesPerState, stimSitesPerState, pNamesPerState] = getRASRespChannels(fileNameRespChAllPatAllStates)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

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
            nRespPerState{iState} = [nRespPerState{iState},stState.nRespCh(indStimChData)'];
            nRespPerStatePerPat{iState, iP} = stState.nRespCh;
            stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames;
            pNamesPerState{iState} = [pNamesPerState{iState},repmat({stState.channInfo.pName},1,length(indStimChData))];
            for iStim=1:length(indStimChData)
                % Find distance between Responsive channels and stim
                anatRegionsRespChPerState{iState} = [anatRegionsRespChPerState{iState}, {stState.channInfoRespCh{iStim}.anatRegionsResp}];
                RASCoordRespChPerState{iState} = [RASCoordRespChPerState{iState}, {stState.channInfoRespCh{iStim}.RASCoordResp}];
                anatRegionsPerChPerState{iState} = [anatRegionsPerChPerState{iState}, stState.channInfoRespCh{iStim}.anatRegionsPerCh];
                RASCoordPerChPerState{iState} = [RASCoordPerChPerState{iState}; stState.channInfoRespCh{iStim}.RASCoordPerChStimCh];
                anatRegionsStimChPerState{iState} = [anatRegionsStimChPerState{iState}, stState.channInfoRespCh{iStim}.anatRegionsStimCh];
                RASCoordPerChStimChPerState{iState} = [RASCoordPerChStimChPerState{iState}; stState.channInfoRespCh{iStim}.RASCoordPerChStimCh];
                chNamesPName = strcat(stState.channInfoRespCh{iStim}.lstResponsiveChannel,'_',stState.channInfo.pName);
                chNamesRespPerState{iState} = [chNamesRespPerState{iState}, {chNamesPName}];
                chNamesPName = strcat(stState.channInfoRespCh{iStim}.chNamesSelected,'_',stState.channInfo.pName);
                chNamesPerState{iState} = [chNamesPerState{iState}, chNamesPName];
                
                stimPName = strcat({[stState.channInfoRespCh{indStimChData(iStim)}(1).stimSiteNames{:}]},'_',stState.channInfo.pName);
                stimSitesPerState{iState} = [stimSitesPerState{iState}, stimPName];
            end
        end
    end
end