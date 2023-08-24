function [valPerState, recChannsPerState, stimSitesPerState, anatRegionsRecChPerState, anatRegionsStimChPerState, pNamesPerState, densityPerState, valPerStatePerPat, stimSitesPerStatePerPat, nTrialPerChPerState] = ...
    getCentralityMeasRespChannels(fileNameRespChAllPatAllComp, stimChWithRespPerPat, respChAnyStaChPerPat)

nPatients = size(fileNameRespChAllPatAllComp,1);
nComp = size(fileNameRespChAllPatAllComp,2);
if ~exist('respChAnyStaChPerPat','var'), respChAnyStaChPerPat= []; end % specify RECORDING channels to keep - it is used to keep chanels with enough resp channels in any state

valPerStatePerPat = cell(nComp, nPatients);
stimSitesPerStatePerPat = cell(nComp, nPatients);
valPerState = cell(nComp,1);
recChannsPerState = cell(nComp, 1);
stimSitesPerState = cell(nComp, 1);
pNamesPerState  = cell(nComp, 1);
anatRegionsRecChPerState  = cell(nComp, 1);
anatRegionsStimChPerState  = cell(nComp, 1);
nTrialPerChPerState = cell(nComp, 1);
densityPerState = cell(nComp,1);
for iComp=1:nComp
    valPerState{iComp}=[];
    densityPerState{iComp}=NaN(2,nPatients);
    for iP=1:nPatients
        fileNameToLoad = fileNameRespChAllPatAllComp{iP, iComp};
        stState = load(fileNameToLoad);
        if ~isempty(stState.matPairedCentralityMeasures)
        %stateName{iState} = stState.thisState;
            matCentralityMeasures = stState.matPairedCentralityMeasures;
            % stim channel
            indStimChData=find(contains(stState.stimSiteNames, stimChWithRespPerPat{iP}));
            stimSitesPerStatePerPat{iComp,iP} = matCentralityMeasures.stimSiteNames(indStimChData);

           % indStimChData = find(~cellfun(@isempty, stState.stimSiteNames));
            % Keep recording channels with response in ANY state
            if ~isempty(respChAnyStaChPerPat)
                [commonChNames, indRecCh] = intersect(matCentralityMeasures.recChNames, unique([respChAnyStaChPerPat{iP}{:}]));
            else
                indRecCh = 1:length(matCentralityMeasures.recChNames);
            end
            recChNames = matCentralityMeasures.recChNames(indRecCh);
            % centrality measure is the feature
            valFeatRespCh = matCentralityMeasures.outdegree(:,indRecCh) / length(indStimChData);
            
            valPerState{iComp} = [valPerState{iComp},valFeatRespCh];
            valPerStatePerPat{iComp, iP} = valFeatRespCh;
            
            densityPerState{iComp}(1:2,iP) = matCentralityMeasures.kdensity;

            
            pNamesPerState{iComp} = [pNamesPerState{iComp},repmat({stState.pName},1,length(recChNames))];
            stimPName = strcat(stimSitesPerStatePerPat{iComp,iP},'_',stState.pName);
            recPName = strcat(recChNames,'_',stState.pName);
            stimSitesPerState{iComp} = [stimSitesPerState{iComp};  stimPName];
            recChannsPerState{iComp} = [recChannsPerState{iComp}, recPName];
            anatRegionsRecChPerState{iComp} = [anatRegionsRecChPerState{iComp}, matCentralityMeasures.anatRegionRecCh(indRecCh)];
            anatRegionsStimChPerState{iComp} = [anatRegionsStimChPerState{iComp},matCentralityMeasures.anatRegionStimCh{indStimChData}];
            nTrialPerChPerState{iComp} = [nTrialPerChPerState{iComp}, matCentralityMeasures.nTrials(:,indRecCh)];
        end
    end
end