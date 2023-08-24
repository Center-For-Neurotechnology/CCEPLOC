function OrganizeDataForLMERelativeFeatures(featuresMatFile, thisRegion, indRelComp,thisFeature)

if ~exist('thisRegion','var'), thisRegion='all'; end
if ~exist('indRelComp','var'), indRelComp= [2,3]; end % default relative Sleep vs Anesthesia (ignore wake/wake)
if ~exist('thisFeature','var'), thisFeature='ptpResponsiveCh'; end %default peak-to-peak amplitude

gralRegionNames = {'frontal','posterior','temporal'};

%% Load data
stFeat = load(featuresMatFile);
indThisRegion =find(strcmpi(stFeat.regionNames,thisRegion));
pNames= stFeat.cfgStats.pNames;
stateNames= stFeat.cfgStats.allStates;
featureNames = stFeat.featureNames;
indFeature = find(strcmpi(featureNames, thisFeature));

%% Relative Features
disp(['*************** RELATIVE FEATURES ', thisFeature,' *********************'])
stateCompNames= strcat(stateNames(stFeat.pairComps(indRelComp,1)), stateNames(stFeat.pairComps(indRelComp,2)));
nStatesToCompare = length(stateCompNames);
%allRecChStimChPNames = stFeat.commonChPerCompRegion(indRelComp,indRegionAll); %"recRECORDINGch stimSTIMch_pName"
featThisRegion = stFeat.statsResults.FeaturesRespPerRegion.(thisRegion);

for iComp=1:nStatesToCompare
    relFeatAll{iComp} = featThisRegion.(stateCompNames{iComp}).(thisFeature).relativeNResp;
    
    allRecChStimChPNames{iComp} = featThisRegion.(stateCompNames{iComp}).(thisFeature).commonCh;
    [splitRecStimPName, marker] = split(allRecChStimChPNames{iComp},{'p','sub'});  % SPECIFIC to participant ID
    allPNames{iComp} = strcat(marker, squeeze(splitRecStimPName(:,:,2)));

    %     cAllRecChStimChPNames = split(allRecChStimChPNames{iComp}, {' ','_'});
%     allRecCh{iComp} = squeeze(cAllRecChStimChPNames(1,:,1));
%     allStimCh{iComp} = squeeze(cAllRecChStimChPNames(1,:,2));
%     allPNames{iComp} = squeeze(cAllRecChStimChPNames(1,:,3));
    allStatesComp{iComp} = repmat(stateCompNames(iComp),1,length(allPNames{iComp}));
  %  allStatesCompNumber{iCompState} = repmat(pairCompsTogether(iCompState),1,length(allPNames{iCompState}));
    allStatesCompNumber{iComp} = repmat(iComp-1,1,length(allPNames{iComp}));
end
% We can get the anat/trial info from the "abs" organization part -  since this is Variability the SAME channels are included in abs and relative var - it will not geenralize to other measures
for iComp=1:nStatesToCompare
    gralRegionRecCh{iComp}(1:length(relFeatAll{iComp})) = {'other'};
    gralRegionStimCh{iComp}(1:length(relFeatAll{iComp})) = {'other'};
    indAbsComp = [stFeat.pairComps(indRelComp(iComp),:)];
    indIn1=[];indIn2=[];
    for iCh=1:length(allRecChStimChPNames{iComp})
        indIn1 = [indIn1, find(strcmpi(stFeat.chNamesPerState{indAbsComp(1), indThisRegion}, allRecChStimChPNames{iComp}{iCh}))];
        indIn2 = [indIn2, find(strcmpi(stFeat.chNamesPerState{indAbsComp(2), indThisRegion}, allRecChStimChPNames{iComp}{iCh}))];
    end
    anatRegionRecCh{iComp} = stFeat.anatRegionsFeatChPerState{indAbsComp(1)}(indIn1); % since this is Features comparison the SAME channels are included in abs and relative var - it will not geenralize to other measures
    nTrialsAbs1 = stFeat.nTrialPerChPerState{indAbsComp(1), indThisRegion}; % since this is Features comparison the SAME channels are included in abs and relative var - it will not geenralize to other measures
    nTrialsAbs2 = stFeat.nTrialPerChPerState{indAbsComp(2), indThisRegion}; % since this is Features comparison the SAME channels are included in abs and relative var - it will not geenralize to other measures
    nTrialsPerState{iComp}(1,1:length(relFeatAll{iComp})) = nTrialsAbs1(indIn1)';
    nTrialsPerState{iComp}(2,1:length(relFeatAll{iComp})) = nTrialsAbs2(indIn2)';
    nTrialsDiffPerState{iComp} = nTrialsAbs2(indIn2)-nTrialsAbs1(indIn1);
   
    [indRecPerRegion] = findChannelsWithinRegion(stFeat.gralRegionsPerChPerState{indAbsComp(1)}, gralRegionNames);
    [indStimPerRegion] = findChannelsWithinRegion(stFeat.gralRegionsStimChPerState{indAbsComp(1)}, gralRegionNames);
    indGralRegionRecCh{iComp}=zeros(1,length(indIn1));
    indGralRegionStimCh{iComp}=zeros(1,length(indIn1));
    for iRegion=1:length(gralRegionNames)
        [~,~,indSelRec] = intersect(indRecPerRegion{iRegion}, indIn1);
        gralRegionRecCh{iComp}(indSelRec) = gralRegionNames(iRegion);
        indGralRegionRecCh{iComp}(indSelRec) = iRegion;
        [~,~,indSelStim] = intersect(indStimPerRegion{iRegion}, indIn1);
        gralRegionStimCh{iComp}(indSelStim) = gralRegionNames(iRegion);
        indGralRegionStimCh{iComp}(indSelStim) = iRegion;
    end
    
end

% Put togather all the states
relFeatAllStates = [relFeatAll{:}];
nTrialsAll = [nTrialsDiffPerState{:}];
pNamesAllStates = [allPNames{:}];
allStatesAllData= [allStatesComp{:}];
allStatesCompNumAllData= [allStatesCompNumber{:}];
pNumberAllStates=zeros(size(pNamesAllStates));
for iP=1:length(pNames)
    pNumberAllStates(find(strcmp(pNamesAllStates,pNames{iP}))) = iP;
end
gralRegionRecChAllStates= [indGralRegionRecCh{:}];
gralRegionStimChAllStates= [indGralRegionStimCh{:}];

% Check for normality 
%figure;
%qqplot(relFeatAllStates);
[hNorm pValNorm, kstat, cStat] = lillietest(relFeatAllStates);
disp(['Normality Test (lillietest): for Rel Var ',stateCompNames{:}])
disp([' h=',num2str(hNorm),' pVal= ',num2str(pValNorm),' kStats= ',num2str(kstat),' criticalVal= ',num2str(cStat)])

% Construct LMM model
y = relFeatAllStates';
% X = [ones(size(y)), allStatesCompNumAllData'];
% Z = ones(size(y));
% G = pNumberAllStates';
X = [ones(size(y)), allStatesCompNumAllData', nTrialsAll',gralRegionRecChAllStates',gralRegionStimChAllStates'];
Z = {ones(size(y)),  nTrialsAll', gralRegionRecChAllStates',gralRegionStimChAllStates'};%, ,sum(recAnatRegionAll,1)'
G = {pNumberAllStates',pNumberAllStates',pNumberAllStates',pNumberAllStates'};

% run LME
lmeRelFeat = fitlmematrix(X,y,Z,G,'FixedEffectPredictors',{'Intercept',['State',[stateCompNames{:}]],'nTrialsDiff','RecRegion','StimRegion'},...
    'RandomEffectPredictors',{'Intercept','nTrialsDiff','RecRegion','StimRegion'},'RandomEffectGroups',{'Participant','Participant','Participant','Participant'});% ,'FitMethod','REML');,'recRegion'
% Display LMM results
disp(['***********  Linear Mixed-effect Model Relative Feature ',thisFeature, ' ',[strcat(stateCompNames,' - ')],' *******************'])
lmeRelFeat.disp

disp(['***********  SIMPLER Linear Mixed-effect Model Relative Feature ',thisFeature, ' ',[strcat(stateCompNames,' - ')],' *******************'])
simplerLMERelFeat = fitlmematrix(X,y,Z(:,1),G(:,1),'FixedEffectPredictors',{'Intercept',['State',[stateCompNames{:}]],'nTrialsDiff','RecRegion','StimRegion'},...
    'RandomEffectPredictor',{'Intercept'},'RandomEffectGroups',{'Participant'});% ,'FitMethod','REML');
simplerLMERelFeat.disp

% Compare likeihood of models
compare(simplerLMERelFeat,lmeRelFeat,'CheckNesting',true)



