function [valRespChPerState, respSitesPerState, stimSitesPerState, anatRegionsChPerState, anatRegionsStimChPerState, pNamesPerState, meanValRespPerState, valPerStatePerPat, stimSitesPerStatePerPat, indRespChPerState, nTrialPerChPerState] = ...
    getFeatureAllChannels(fileNameRespChAllPatAllStates, featureNames, stimChWithRespPerPat,respChAnyStaChPerPat)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);


if ~exist('featureNames','var') ||isempty(featureNames), featureNames = {'ptpResponsiveCh', 'relP2PPerCh'}; end
if ~exist('stimChWithRespPerPat','var'), stimChWithRespPerPat = [];end % specify STIM channels to keep - it is used to keep chanels with enough resp channels in any state
if ~exist('respChAnyStaChPerPat','var'), respChAnyStaChPerPat= []; end % specify RECORDING channels to keep - it is used to keep chanels with enough resp channels in any state

nFeatures = length(featureNames);

valPerStatePerPat = cell(nStates, nPatients);
stimSitesPerStatePerPat = cell(nStates, nPatients);
valRespChPerState = cell(nStates, nFeatures);
respSitesPerState = cell(nStates, 1);
indRespChPerState =  cell(nStates, 1);
stimSitesPerState = cell(nStates, 1);
pNamesPerState  = cell(nStates, 1);
anatRegionsChPerState  = cell(nStates, 1);
anatRegionsStimChPerState  = cell(nStates, 1);
meanValRespPerState = zeros(nFeatures, nStates);
nTrialPerChPerState  = cell(nStates, 1);
for iState=1:nStates
    valRespChPerState{iState}=[];
    for iP=1:nPatients
        fileNameToLoad = fileNameRespChAllPatAllStates{iP, iState};
        stState = load(fileNameToLoad);
        %stateName{iState} = stState.thisState;
        if any(stState.nRespCh>0)
            indStimChData = find(~cellfun(@isempty, stState.stimSiteNames));
            for iStim=1:length(indStimChData)
                chInfoRespPerStim = stState.channInfoRespCh{indStimChData(iStim)}(1); % if more than one stim on the same chhannels - assume they are equivalent and use the first one
                bipStimCh = strcat(chInfoRespPerStim.stimSiteNames{2},'-',chInfoRespPerStim.stimSiteNames{1});
                if isempty(stimChWithRespPerPat) || any(strcmpi(bipStimCh, stimChWithRespPerPat{iP})) % this channel is one of the responsive in any state
                    indStim=find(strcmpi(bipStimCh, stimChWithRespPerPat{iP}));
                    % Keep recording channels with response in ANY state
                    if ~isempty(respChAnyStaChPerPat)
                        [commonChNames indRecCh] = intersect(chInfoRespPerStim.chNamesSelected, respChAnyStaChPerPat{iP}{indStim});
                    else
                        indRecCh = 1:length(chInfoRespPerStim.chNamesSelected);
                    end
                    
                    % feature values
                    for iFeat=1:nFeatures
                       % valFeatRespCh = cell2mat(chInfoRespPerStim.(featureNames{iFeat}));
                        valFeatRespCh = chInfoRespPerStim.infoAmpPerCh.(featureNames{iFeat})(indRecCh); % in infoAmpPerCh we store the amp info for all recording channels - not only the responsive ones.
                        valFeatRespCh(find((valFeatRespCh==0)))=NaN; % convert zeros to NaN
                        valRespChPerState{iState,iFeat} = [valRespChPerState{iState,iFeat},valFeatRespCh];
                        valPerStatePerPat{iState, iP}{iStim}{iFeat} = valFeatRespCh;
                    end
                    stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames;
                    pNamesPerState{iState} = [pNamesPerState{iState},repmat({stState.channInfo.pName},1,length(valFeatRespCh))];
                    stimPName = strcat({[chInfoRespPerStim.stimSiteNames{:}]},'_',stState.channInfo.pName);
                    stimSitesPerState{iState} = [stimSitesPerState{iState},  repmat(stimPName,1,length(valFeatRespCh))];
                   % respSitesPerState{iState} = [respSitesPerState{iState}, strcat(chInfoRespPerStim.lstResponsiveChannel, '_', stimPName)];
                    respSitesPerState{iState} = [respSitesPerState{iState}, strcat(chInfoRespPerStim.chNamesSelected(indRecCh), '_', stimPName)];
                    indRespChPerState{iState} = [indRespChPerState{iState}, find(chInfoRespPerStim.isChResponsive(indRecCh))];
                    anatRegionsChPerState{iState} = [anatRegionsChPerState{iState}, chInfoRespPerStim.anatRegionsPerCh(indRecCh)];
                    anatRegionsStimChPerState{iState} = [anatRegionsStimChPerState{iState}, repmat(chInfoRespPerStim.anatRegionsStimCh,1,length(valFeatRespCh))];
                    nTrialPerChPerState{iState} = [nTrialPerChPerState{iState}, chInfoRespPerStim.infoAmpPerChPerTrial.nTrials(indRecCh)];
                end
            end
        end
    end
    for iFeat=1:nFeatures
        valFeatNoInf = valRespChPerState{iState,iFeat};
        valFeatNoInf(find(isinf(valRespChPerState{iState,iFeat})))=[];
        meanValRespPerState(iFeat, iState) = nanmean(valFeatNoInf);
    end
end