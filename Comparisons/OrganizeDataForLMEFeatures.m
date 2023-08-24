function OrganizeDataForLMEFeatures(featuresMatFile, thisRegion, indAbsComp, thisFeature)

if ~exist('thisRegion','var'), thisRegion='all'; end
if ~exist('indAbsComp','var'), indAbsComp= [2,3]; end % default relative Sleep vs Anesthesia (ignore wake/wake)
if ~exist('thisFeature','var'), thisFeature='ptpResponsiveCh'; end %default peak-to-peak amplitude

gralRegionNames = {'frontal','posterior','temporal'};

%% Load Data
stFeat = load(featuresMatFile);
indThisRegion =find(strcmpi(stFeat.regionNames,thisRegion));
pNames= stFeat.cfgStats.pNames;
stateNames= stFeat.cfgStats.allStates;
featureNames = stFeat.featureNames;
indFeature = find(strcmpi(featureNames, thisFeature));

%% Feature (absolute values)
%indAbsComp = [1,3];
featAll = squeeze(stFeat.valFeatPerStatePerRegion(indFeature,indAbsComp,indThisRegion));
allRecChStimChPNames = stFeat.respChFeatsPerStatePerRegion(indAbsComp,indThisRegion);
stateNamesToCompare = stateNames(indAbsComp);
nTrialsPerState = stFeat.nTrialPerChPerState(indAbsComp);

for iComp=1:length(indAbsComp)
    [splitRecStimPName, marker] = split(allRecChStimChPNames{iComp},{'p','sub'}); % SPECIFIC to participant ID
    allPNames{iComp} = strcat(marker, squeeze(splitRecStimPName(:,:,2)));

%     cAllRecChStimChPNames = split(allRecChStimChPNames{iComp}, {'_'});
%     allRecCh{iComp} = squeeze(cAllRecChStimChPNames(1,:,1));
%     allStimCh{iComp} = squeeze(cAllRecChStimChPNames(1,:,2));
%     allPNames{iComp} = squeeze(cAllRecChStimChPNames(1,:,3));
    allStatesComp{iComp} = repmat(stateNames(iComp),1,length(allPNames{iComp}));
    allStatesCompNumber{iComp} = repmat(iComp-1,1,length(allPNames{iComp}));
    
    [indRecPerRegion] = findChannelsWithinRegion(stFeat.gralRegionsPerChPerState{indAbsComp(iComp)}, gralRegionNames);
    [indStimPerRegion] = findChannelsWithinRegion(stFeat.gralRegionsStimChPerState{indAbsComp(iComp)}, gralRegionNames);
    indGralRegionRecCh{iComp}=zeros(1,length(featAll{iComp}));
    indGralRegionStimCh{iComp}=zeros(1,length(featAll{iComp}));
    for iRegion=1:length(gralRegionNames)
        gralRegionRecCh{iComp}(indRecPerRegion{iRegion}) = gralRegionNames(iRegion);
        indGralRegionRecCh{iComp}(indRecPerRegion{iRegion}) = iRegion;
        gralRegionStimCh{iComp}(indStimPerRegion{iRegion}) = gralRegionNames(iRegion);
        indGralRegionStimCh{iComp}(indStimPerRegion{iRegion}) = iRegion;
    end
end

% Put togather all the states
featAllStates = log([featAll{:}]);
nTrialsAll = [nTrialsPerState{:}];
pNamesAllStates = [allPNames{:}];
allStatesAllData= [allStatesComp{:}];
allStatesCompNumAllData= [allStatesCompNumber{:}];
pNumberAllStates=zeros(size(pNamesAllStates));
for iP=1:length(pNames)
    pNumberAllStates(find(strcmp(pNamesAllStates,pNames{iP}))) = iP;
end
gralRegionRecChAllStates= [indGralRegionRecCh{:}];
gralRegionStimChAllStates= [indGralRegionStimCh{:}];

% remove inf/nan values
indToExclude = unique([find(isinf(featAllStates)),find(isnan(featAllStates))]);
featAllStates(indToExclude)=[];
nTrialsAll(indToExclude)=[];
pNamesAllStates(indToExclude)=[];
allStatesAllData(indToExclude)=[];
allStatesCompNumAllData(indToExclude)=[];
pNumberAllStates(indToExclude)=[];
gralRegionRecChAllStates(indToExclude)=[];
gralRegionStimChAllStates(indToExclude)=[];


% Check for normality 
%figure;
%qqplot(featAllStates);
[hNorm pValNorm, kstat, cStat] = lillietest(featAllStates);
disp(['Normality Test (lillietest): for  Var ',stateNamesToCompare{:}])
disp([' h=',num2str(hNorm),' pVal= ',num2str(pValNorm),' kStats= ',num2str(kstat),' criticalVal= ',num2str(cStat)])

% Construct LMM model
y = featAllStates';
X = [ones(size(y)), allStatesCompNumAllData', nTrialsAll',gralRegionRecChAllStates',gralRegionStimChAllStates'];
Z = {ones(size(y)), nTrialsAll', gralRegionRecChAllStates',gralRegionStimChAllStates'};
G = {pNumberAllStates',pNumberAllStates',pNumberAllStates',pNumberAllStates'};

% run LME
lmeFeat = fitlmematrix(X,y,Z,G,'FixedEffectPredictors',{'Intercept',['State',[stateNamesToCompare{:}]],'nTrials','RecRegion','StimRegion'},...
    'RandomEffectPredictors',{'Intercept','nTrials','RecRegion','StimRegion'},'RandomEffectGroups',{'Participant','Participant','Participant','Participant'});% ,'FitMethod','REML');,'recRegion'
% Display LMM results
disp(['***********  Linear Mixed-effect Model Relative Variability ',[strcat(stateNamesToCompare,' - ')],' *******************'])
lmeFeat.disp

disp(['***********  SIMPLER Linear Mixed-effect Model Relative FEATURE: ',thisFeature,' ',[strcat(stateNamesToCompare,' - ')],' *******************'])
simplerLMEFeat = fitlmematrix(X,y,Z(:,1),G(:,1),'FixedEffectPredictors',{'Intercept',['State',[stateNamesToCompare{:}]],'nTrials','RecRegion','StimRegion'},...
    'RandomEffectPredictor',{'Intercept'},'RandomEffectGroups',{'Participant'});% ,'FitMethod','REML');
simplerLMEFeat.disp

% Compare likeihood of models
compare(simplerLMEFeat,lmeFeat,'CheckNesting',true)