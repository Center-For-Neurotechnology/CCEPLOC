function [nRespPerState, perRespChPerState, stimSitesPerState, pNamesPerState, meanNRespPerState, nRespPerStatePerPat, stimSitesPerStatePerPat] = getNRespChannels(fileNameRespChAllPatAllStates, stimChWithRespPerPat)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

if ~exist('stimChWithRespPerPat','var'), stimChWithRespPerPat = [];end 


nRespPerStatePerPat = cell(nStates, nPatients);
stimSitesPerStatePerPat = cell(nStates, nPatients);
nRespPerState = cell(nStates, 1);
stimSitesPerState = cell(nStates, 1);
perRespChPerState = cell(nStates, 1);
pNamesPerState  = cell(nStates, 1);
for iState=1:nStates
    nRespPerState{iState}=[];
    for iP=1:nPatients
        fileNameToLoad = fileNameRespChAllPatAllStates{iP, iState};
        stState = load(fileNameToLoad);
        if any(stState.nRespCh>0) 
            indStimChData = find(~cellfun(@isempty, stState.stimSiteNames));
            nRespPerStatePerPat{iState, iP} = stState.nRespCh; % all the nResp
            stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames; % all the stim channels
            for iStim=1:length(indStimChData)
                bipStimCh = strcat(stState.channInfoRespCh{indStimChData(iStim)}(1).stimSiteNames{2},'-',stState.channInfoRespCh{indStimChData(iStim)}(1).stimSiteNames{1});
                if isempty(stimChWithRespPerPat) || any(strcmpi(bipStimCh, stimChWithRespPerPat{iP})) % this channel is one of the responsive in any state
                    nRespPerState{iState} = [nRespPerState{iState},stState.nRespCh(indStimChData(iStim))'];
                    perRespCh = sum([stState.channInfoRespCh{indStimChData(iStim)}.isChResponsive])/length([stState.channInfoRespCh{indStimChData(iStim)}.isChResponsive]);
                    perRespChPerState{iState} = [perRespChPerState{iState}, perRespCh];
                    stimPName = strcat(bipStimCh,'_',stState.channInfo.pName);
                    stimSitesPerState{iState} = [stimSitesPerState{iState}, {stimPName}]; % only channels with enough response in any state (or whatever is spoecified on stimChWithRespPerPat)
                    pNamesPerState{iState} = [pNamesPerState{iState},{stState.channInfo.pName}];              
                end
            end
       end
    end
    meanNRespPerState(iState) = mean(nRespPerState{iState}); %IMPROVE: ONLY CONSIDER THOSE WITH CORRESPONDING!
end