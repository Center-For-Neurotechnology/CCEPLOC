function [mFeaturesPerStatePerPat, mRespChPerStatePerPat, stimSitesPerStatePerPat, reChNamesPerStatePerPat, anatRegionsChPerStatePerPat, anatRegionsStimChPerStatePerPat, pNamesPerState, nTrialPerStatePerPat] = ...
    getFeatureMatrixAllChannelsAllStim(fileNameRespChAllPatAllStates, featureName, stimChWithRespPerPat)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);


if ~exist('stimChWithRespPerPat','var'), stimChWithRespPerPat = [];end % specify STIM channels to keep - it is used to keep chanels with enough resp channels in any state


stimSitesPerStatePerPat = cell(nStates, nPatients);
pNamesPerState  = cell(nStates, 1);
anatRegionsChPerStatePerPat = cell(nStates, nPatients);
anatRegionsStimChPerStatePerPat  = cell(nStates, nPatients);
reChNamesPerStatePerPat = cell(nStates, nPatients);
mFeaturesPerStatePerPat =  cell(nStates, nPatients);
mRespChPerStatePerPat =  cell(nStates, nPatients);
nTrialPerStatePerPat =  cell(nStates, nPatients);

for iState=1:nStates
    for iP=1:nPatients
        fileNameToLoad = fileNameRespChAllPatAllStates{iP, iState};
        stState = load(fileNameToLoad);
        %stateName{iState} = stState.thisState;
        if any(stState.nRespCh>0)
            indStimChData = find(~cellfun(@isempty, stState.stimSiteNames));
            allChNames=cell(0,0);
            for iStim=1:length(indStimChData)
              allChNames = unique([allChNames, stState.channInfoRespCh{iStim}.chNamesSelected]);
            end
            mFeatures = zeros(length(indStimChData),length(allChNames)); % matrix of features of the responses
            mRespCh  = zeros(length(indStimChData),length(allChNames)); % matrix of responsive channels 0/1
            nTrialsPerStim  = nan(length(indStimChData),length(allChNames)); % matrix of nTrials per channels 
            pNamesPerState{iState} = [pNamesPerState{iState},{stState.channInfo.pName}];
            stimSitesPerStatePerPat{iState,iP} = stState.stimSiteNames;
            reChNamesPerStatePerPat{iState, iP} = allChNames;
            anatRegionsChPerStatePerPat{iState, iP} = cell(1,length(allChNames)); % anat region
            anatRegionsStimChPerStatePerPat{iState, iP} = cell(1,length( stState.stimSiteNames));
            for iStim=1:length(indStimChData)
                chInfoRespPerStim = stState.channInfoRespCh{indStimChData(iStim)}(1); % if more than one stim on the same chhannels - assume they are equivalent and use the first one
                bipStimCh = strcat(chInfoRespPerStim.stimSiteNames{2},'-',chInfoRespPerStim.stimSiteNames{1});
                if isempty(stimChWithRespPerPat) || any(strcmpi(bipStimCh, stimChWithRespPerPat{iP})) % this channel is one of the responsive in any state
                    %  indStim=find(strcmpi(bipStimCh, stimChWithRespPerPat{iP}));
                    % Keep all recording channel
                    [indRecChInAll, indRecInFile] = strmatchAll(allChNames,chInfoRespPerStim.chNamesSelected);
                    
                    % feature values
                    valFeatRespCh = chInfoRespPerStim.infoAmpPerCh.(featureName); % in infoAmpPerCh we store the amp info for all recording channels - not only the responsive ones.
                    
                    % generate matrix for all stim per patient
                    mFeatures(iStim, indRecChInAll) = valFeatRespCh(indRecInFile)';
                    % matrix of responsive channels
                    mRespCh(iStim, indRecChInAll) = chInfoRespPerStim.isChResponsive(indRecInFile)';
                    
                    % channel info
                    anatRegionsChPerStatePerPat{iState, iP}(indRecChInAll) = chInfoRespPerStim.anatRegionsPerCh(indRecInFile);
                    anatRegionsStimChPerStatePerPat{iState, iP}{iStim} =  chInfoRespPerStim.anatRegionsStimCh;
                    
                    % nTrials - will calculate average across detections
                    nTrialsPerStim(iStim,indRecChInAll) = chInfoRespPerStim.infoAmpPerChPerTrial.nTrials(indRecInFile);                   
                end
            end
            mFeaturesPerStatePerPat{iState,iP} = mFeatures;
            mRespChPerStatePerPat{iState,iP} = mRespCh;
            nTrialPerStatePerPat{iState, iP} = nanmean(nTrialsPerStim,1);
        end
    end

end