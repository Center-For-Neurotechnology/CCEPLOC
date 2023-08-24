function [fileNameCentralityAllStatesAllPat,fileNamesCentralityPerPat] = computeCentralityMeas(fileNameRespChAllPatAllStates, dirResults, cfgStats) %, whichRecChannels)

featureName = 'dataMaxMinAmp' ;
mkdir(dirResults)

% Get connections / features
%% Get Features of Responsive channels for all states and stim channels
[mFeaturesPerStatePerPat, mRespChPerStatePerPat, stimSitesPerStatePerPat, reChNamesPerStatePerPat, anatRegionsChPerStatePerPat, anatRegionsStimChPerStatePerPat, pNamesPerState, nTrialPerStatePerPat] = ...
    getFeatureMatrixAllChannelsAllStim(fileNameRespChAllPatAllStates, featureName, cfgStats.stimChPerPat);

allStates = cfgStats.allStates;

%% run brain connectivity toolbox measures
nStates=size(mFeaturesPerStatePerPat,1);
nPatients=size(mFeaturesPerStatePerPat,2);
matMeasuresAllStateAllPat = cell(nStates,nPatients);
matMeasuresOutdegree = cell(nStates,nPatients);
densityPerStatePerPat = zeros(nStates,nPatients);
for iP=1:nPatients
    for iState=1:nStates
         mIndRespCh = mRespChPerStatePerPat{iState, iP};
         
         mFeature.(featureName) = mFeaturesPerStatePerPat{iState, iP};
         matCentralityMeasures.stimSiteNames = stimSitesPerStatePerPat{iState, iP};
         matCentralityMeasures.recChNames = reChNamesPerStatePerPat{iState, iP};
         matCentralityMeasures.anatRegionRecCh =  anatRegionsChPerStatePerPat{iState, iP};
         matCentralityMeasures.anatRegionStimCh =  anatRegionsStimChPerStatePerPat{iState, iP};
         matCentralityMeasures.nTrials =  nTrialPerStatePerPat{iState, iP};
        
         
        %% Generate SQUARE matrix
        sizeMat = size(mIndRespCh);
        mRespIndSquare = zeros(max(sizeMat));
        mRespIndSquare(1:sizeMat(1), 1:sizeMat(2)) = mIndRespCh;

        %% run toolbox
        [indegree, outdegree, degree] = degrees_dir(mRespIndSquare'); % degrees require a square matrix
 %       flow=id-od;
        [kdensity,N,K] = density_dir(mIndRespCh'); % density does not require a square matrix
        disp([featureName, ' ', cfgStats.allStates{iState}, ' ', cfgStats.pNames{iP},' density= ',num2str(kdensity)]);
        %% Organize per state and patient
        densityPerStatePerPat(iState,iP)= kdensity;
        matCentralityMeasures.kdensity=kdensity;
        matCentralityMeasures.kdensityVerticesN=N;
        matCentralityMeasures.kdensityEdgesK=K;
        matCentralityMeasures.indegree=indegree;
        matCentralityMeasures.outdegree=outdegree;
        matCentralityMeasures.degree=degree;
        matCentralityMeasures.mIndRespCh = mIndRespCh;
        matCentralityMeasures.mRespIndSquare = mRespIndSquare;

        matMeasuresAllStateAllPat{iState,iP} = matCentralityMeasures;
        matMeasuresOutdegree{iState,iP}=outdegree;

        % Save per rep file
        fileNameOrig = fileNameRespChAllPatAllStates{iP, iState};
        fileNameNew = [fileNameOrig(1:end-4),'_wCentrality.mat'];
        copyfile(fileNameOrig,fileNameNew,'f') 
        save(fileNameNew,'matCentralityMeasures','mIndRespCh','mFeature','-append');
        clear matCentralityMeasures;
    end
end

%% Compute ONLY for pairs of comparisons - to consider the same stim channels
disp('Paired centrality measures (only those stim channels in 2 states')
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
nComps = size(pairComps,1);
matMeasuresPairedAllStateAllPat = cell(nComps,nPatients);
matMeasuresPairedOutdegree = cell(nComps,nPatients);
densityPairedPerStatePerPat = zeros(nComps,2,nPatients);
fileNamesCentralityPerPat = cell(nPatients,nComps);
for iP=1:nPatients
    pName = cfgStats.pNames{iP};
    channInfo = cfgStats.channInfoAllPat{iP};
    respChAnyState = cfgStats.respChAnyStaChPerPat{iP};
    stimChAnyState = cfgStats.stimChPerPat{iP};
    for iComp=1:nComps
        statesInComp = [allStates{pairComps(iComp,:)}];
        matPairedCentralityMeasures=[];mPairedIndRespCh=[];mPairedFeature=[];
        [indIn1, indIn2, stimSiteNames] = strmatchAll(stimSitesPerStatePerPat{pairComps(iComp,1), iP}, stimSitesPerStatePerPat{pairComps(iComp,2), iP});
        if ~isempty(stimSiteNames)
            indStimIn{1}=indIn1;indStimIn{2}=indIn2;
            matPairedCentralityMeasures.stimSiteNames = stimSitesPerStatePerPat{pairComps(iComp,1), iP}(indIn1); % SHOULD be the same
            matPairedCentralityMeasures.anatRegionStimCh =  anatRegionsStimChPerStatePerPat{pairComps(iComp,1), iP}(indIn1);
            [indIn1, indIn2, commonRecNames] = strmatchAll(reChNamesPerStatePerPat{pairComps(iComp,1), iP},reChNamesPerStatePerPat{pairComps(iComp,2), iP});
            indRecIn{1}=indIn1;indRecIn{2}=indIn2; % should be the same, but sometimes they are not!
            matPairedCentralityMeasures.recChNames = reChNamesPerStatePerPat{pairComps(iComp,1), iP}(indRecIn{1});
            matPairedCentralityMeasures.anatRegionRecCh =  anatRegionsChPerStatePerPat{pairComps(iComp,1), iP}(indRecIn{1});
            matPairedCentralityMeasures.pairs = pairComps(iComp,:);
            for iPair=1:2
                mPairedIndRespCh = mRespChPerStatePerPat{pairComps(iComp,iPair), iP}(indStimIn{iPair},indRecIn{iPair});
                mPairedFeature.(allStates{pairComps(iComp,iPair)}).(featureName) = mFeaturesPerStatePerPat{pairComps(iComp,iPair), iP}(indStimIn{iPair},:);
                
                %% Generate SQUARE matrix
                sizeMat = size(mPairedIndRespCh);
                mRespIndSquare = zeros(max(sizeMat));
                mRespIndSquare(1:sizeMat(1), 1:sizeMat(2)) = mPairedIndRespCh;
                
                %% run toolbox
                [indegree, outdegree, degree] = degrees_dir(mRespIndSquare'); % degrees require a square matrix
                %       flow=id-od;
                [kdensity,N,K] = density_dir(mPairedIndRespCh'); % density does not require a square matrix
                disp([featureName, ' ', allStates{pairComps(iComp,iPair)}, ' ', pName,' density= ',num2str(kdensity)]);
                %% Organize per state and patient
                densityPairedPerStatePerPat(iComp,iPair,iP)= kdensity;
                matPairedCentralityMeasures.kdensity(iPair,:)=kdensity;
                matPairedCentralityMeasures.kdensityVerticesN(iPair,:)=N;
                matPairedCentralityMeasures.kdensityEdgesK(iPair,:)=K;
                matPairedCentralityMeasures.indegree(iPair,:)=indegree;
                matPairedCentralityMeasures.outdegree(iPair,:)=outdegree;
                matPairedCentralityMeasures.degree(iPair,:)=degree;
                matPairedCentralityMeasures.mIndRespCh{iPair} = mPairedIndRespCh;
                matPairedCentralityMeasures.mRespIndSquare{iPair} = mRespIndSquare;
                matPairedCentralityMeasures.nTrials(iPair,:) =  nTrialPerStatePerPat{pairComps(iComp,iPair), iP}(indRecIn{iPair});
                
            end
            matMeasuresPairedAllStateAllPat{iComp,iP} = matPairedCentralityMeasures;
            matMeasuresPairedOutdegree{iComp,iP}=matPairedCentralityMeasures.outdegree;
        end
        % Save in NEW file per patient and comparison of states
        fileNamesCentralityPerPat{iP,iComp} = [dirResults,filesep,'CentralityMeasures_',statesInComp,'_',pName,'.mat'];
        save(fileNamesCentralityPerPat{iP,iComp},'matPairedCentralityMeasures','mPairedFeature','stimSiteNames','pName','channInfo','respChAnyState','stimChAnyState',...
            'allStates','pairComps','iComp','statesInComp');
    end
end



%% save results all together
fileNameCentralityAllStatesAllPat = [dirResults,filesep,'CentralityMeasures_AllStates_p',num2str(nPatients),date,'.mat'];
save(fileNameCentralityAllStatesAllPat, 'matMeasuresOutdegree','matMeasuresAllStateAllPat','densityPerStatePerPat','cfgStats',...
    'matMeasuresPairedOutdegree','matMeasuresPairedAllStateAllPat','densityPairedPerStatePerPat',...
    'mRespChPerStatePerPat','mFeaturesPerStatePerPat','featureName','stimSitesPerStatePerPat', 'reChNamesPerStatePerPat', 'anatRegionsChPerStatePerPat', 'anatRegionsStimChPerStatePerPat', 'pNamesPerState');
