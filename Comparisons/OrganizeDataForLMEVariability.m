function OrganizeDataForLMEVariability(variabilityFileName, regionName, indAbsComp)

if ~exist('regionName','var'), regionName='all'; end
if ~exist('indAbsComp','var'), indAbsComp= [3, 4]; end % default WakeOR vs Anesthesia

gralRegionNames = {'frontal','posterior','temporal'};

%%
stVar = load(variabilityFileName);
indRegionAll =find(strcmpi(stVar.regionNames,regionName));
pNames= stVar.cfgStats.pNames;
stateNames=stVar.cfgStats.stateNames;


%% Variability (absolute values)
%indAbsComp = [1,3];
disp(['*************** ABSOULTE VARIABILITY *********************'])
varAll = stVar.variabilityPerStatePerRegion(indAbsComp,indRegionAll);
allRecChStimChPNames = stVar.chNamesPNamesPerStatePerRegion(indAbsComp,indRegionAll);
stateCompNames = stateNames(indAbsComp);
allRecCh=cell(1,length(indAbsComp));allStimCh=cell(1,length(indAbsComp));
allPNames=cell(1,length(indAbsComp));allStatesComp=cell(1,length(indAbsComp));
allStatesCompNumber=cell(1,length(indAbsComp));
nTrialsPerState = stVar.nTrialPerChPerStatePerRegion(indAbsComp,indRegionAll);
anatRegionRecCh = stVar.anatRegionsPerChPerState{indAbsComp};


for iComp=1:length(indAbsComp)
    splitRecStimPName = split(allRecChStimChPNames{iComp},{' '});
    allRecCh{iComp}  = regexprep(squeeze(splitRecStimPName(:,:,1)),{'rec','_'},''); % remove also the _
    [splitStimPName, marker] = split(squeeze(splitRecStimPName(:,:,2)),{'p','sub'});  % SPECIFIC to participant ID
    allStimCh{iComp} = regexprep(squeeze(splitStimPName(:,:,1)),{'st','_'},'');
    allPNames{iComp} = strcat(marker, squeeze(splitStimPName(:,:,2)));

%     cAllRecChStimChPNames = split(allRecChStimChPNames{iComp}, {' ','_'});
%     allRecCh{iComp} = squeeze(cAllRecChStimChPNames(1,:,1));
%     allStimCh{iComp} = squeeze(cAllRecChStimChPNames(1,:,2));
%     allPNames{iComp} = squeeze(cAllRecChStimChPNames(1,:,3));
    allStatesComp{iComp} = repmat(stateCompNames(iComp),1,length(allPNames{iComp}));
    allStatesCompNumber{iComp} = repmat(iComp-1,1,length(allPNames{iComp}));
    
    [indRecPerRegion] = findChannelsWithinRegion(stVar.gralRegionsPerChPerState{indAbsComp(iComp)}, gralRegionNames);
    [indStimPerRegion] = findChannelsWithinRegion(stVar.gralRegionsStimChPerState{indAbsComp(iComp)}, gralRegionNames);
    indGralRegionRecCh{iComp}=zeros(1,length(varAll{iComp}));
    indGralRegionStimCh{iComp}=zeros(1,length(varAll{iComp}));
    for iRegion=1:length(gralRegionNames)
        gralRegionRecCh{iComp}(indRecPerRegion{iRegion}) = gralRegionNames(iRegion);
        indGralRegionRecCh{iComp}(indRecPerRegion{iRegion}) = iRegion;
        gralRegionStimCh{iComp}(indStimPerRegion{iRegion}) = gralRegionNames(iRegion);
        indGralRegionStimCh{iComp}(indStimPerRegion{iRegion}) = iRegion;
    end
end

% Put togather all the states
Variability = log([varAll{:}]);
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

% Check for normality 
%figure;
%qqplot(relVarAllStates);
[hNorm pValNorm, kstat, cStat] = lillietest(Variability);
disp(['Normality Test (lillietest): for  Var ',stateCompNames{:}])
disp([' h=',num2str(hNorm),' pVal= ',num2str(pValNorm),' kStats= ',num2str(kstat),' criticalVal= ',num2str(cStat)])

% Construct LMM model
y = Variability';
X = [ones(size(y)), allStatesCompNumAllData', nTrialsAll',gralRegionRecChAllStates',gralRegionStimChAllStates'];
Z = {ones(size(y)), nTrialsAll', gralRegionRecChAllStates',gralRegionStimChAllStates'};
G = {pNumberAllStates',pNumberAllStates',pNumberAllStates',pNumberAllStates'};

% run LME
lmeVAr = fitlmematrix(X,y,Z,G,'FixedEffectPredictors',{'Intercept',['State',[stateCompNames{:}]],'nTrials','RecRegion','StimRegion'},...
    'RandomEffectPredictors',{'Intercept','nTrials','RecRegion','StimRegion'},'RandomEffectGroups',{'Participant','Participant','Participant','Participant'});% ,'FitMethod','REML');,'recRegion'
% Display LMM results
disp(['***********  Linear Mixed-effect Model Relative Variability ',[strcat(stateCompNames,' - ')],' *******************'])
lmeVAr.disp

disp(['***********  SIMPLER Linear Mixed-effect Model Relative Variability ',[strcat(stateCompNames,' - ')],' *******************'])
simplerLMEVar = fitlmematrix(X,y,Z(:,1),G(:,1),'FixedEffectPredictors',{'Intercept',['State',[stateCompNames{:}]],'nTrials','RecRegion','StimRegion'},...
    'RandomEffectPredictor',{'Intercept'},'RandomEffectGroups',{'Participant'});% ,'FitMethod','REML');
simplerLMEVar.disp

% Compare likeihood of models
compare(simplerLMEVar,lmeVAr,'CheckNesting',true)