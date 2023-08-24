function [valRespChPerState, respSitesPerState, stimSitesPerState, anatRegionsRespChPerState, anatRegionsStimChPerState, pNamesPerState, meanValRespPerState, valPerStatePerPat, stimSitesPerStatePerPat, nTrialPerChPerState] = ...
    getFeatureRespChannels(fileNameRespChAllPatAllStates, featureNames, stimChWithRespPerPat)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

if ~exist('featureNames','var') ||isempty(featureNames), featureNames = {'ptpResponsiveCh', 'relP2PPerCh'}; end
if ~exist('stimChWithRespPerPat','var'), stimChWithRespPerPat = [];end % specify channels to keep - it is used to keep chanels with enough resp channels in any state

nFeatures = length(featureNames);

valPerStatePerPat = cell(nStates, nPatients);
stimSitesPerStatePerPat = cell(nStates, nPatients);
valRespChPerState = cell(nStates, nFeatures);
respSitesPerState = cell(nStates, 1);
stimSitesPerState = cell(nStates, 1);
pNamesPerState  = cell(nStates, 1);
anatRegionsRespChPerState  = cell(nStates, 1);
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
                    % feature values
                    for iFeat=1:nFeatures
                        valFeatRespCh = cell2mat(chInfoRespPerStim.(featureNames{iFeat}));
                        valRespChPerState{iState,iFeat} = [valRespChPerState{iState,iFeat},valFeatRespCh];
                        valPerStatePerPat{iState, iP}{iStim}{iFeat} = valFeatRespCh;
                    end
                    stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames;
                    pNamesPerState{iState} = [pNamesPerState{iState},repmat({stState.channInfo.pName},1,length(indStimChData))];
                    stimPName = strcat({[chInfoRespPerStim.stimSiteNames{:}]},'_',stState.channInfo.pName);
                    stimSitesPerState{iState} = [stimSitesPerState{iState},  repmat(stimPName,1,length(valFeatRespCh))];
                    respSitesPerState{iState} = [respSitesPerState{iState}, strcat(chInfoRespPerStim.lstResponsiveChannel, '_', stimPName)];
                    anatRegionsRespChPerState{iState} = [anatRegionsRespChPerState{iState}, chInfoRespPerStim.anatRegionsResp];
                    anatRegionsStimChPerState{iState} = [anatRegionsStimChPerState{iState}, repmat(chInfoRespPerStim.anatRegionsStimCh,1,length(valFeatRespCh))];
                    indRespCh = find(chInfoRespPerStim.isChResponsive);
                    if isfield(chInfoRespPerStim,'infoAmpPerChPerTrial')
                        nTrialPerChPerState{iState} = [nTrialPerChPerState{iState}, chInfoRespPerStim.infoAmpPerChPerTrial.nTrials(indRespCh)];
                    else
                        nTrialPerChPerState{iState} = zeros(1,length(indRespCh));
                    end
                end
            end
        end
    end
    for iFeat=1:nFeatures
        valFeatNoInf = valRespChPerState{iState,iFeat};
        valFeatNoInf(find(isinf(valRespChPerState{iState,iFeat})))=[];
        meanValRespPerState(iFeat, iState) = mean(valFeatNoInf);
    end
end