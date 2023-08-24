function OrganizeDataForLMERelativeVariability(variabilityFileName, thisRegion, indRelComp)

%if ~exist('regionNames','var'), regionNames={'all'}; end
if ~exist('thisRegion','var'), thisRegion='all'; end
if ~exist('indRelComp','var'), indRelComp= [2,3]; end % default relative Sleep vs Anesthesia (ignore wake/wake)

gralRegionNames = {'frontal','posterior','temporal'};

%%
stVar = load(variabilityFileName);
indThisRegion =find(strcmpi(stVar.regionNames,thisRegion)); % this is to ONLY consider the FIRST region 
%indRegionAll =find(strcmpi(stVar.regionNames,'all'));
pNames= stVar.cfgStats.pNames;
stateNames=stVar.cfgStats.stateNames;

%% Relative Variability
%indRelComp=[1,2]; %compare relative sleep nd relative anesthesia (ignore wake)
disp(['*************** RELATIVE VARIABILITY *********************'])
stateCompNames= strcat(stateNames(stVar.pairComps(indRelComp,1)), stateNames(stVar.pairComps(indRelComp,2)));
nStatesToCompare = length(stateCompNames);
relVarAll = stVar.relativeVariability(indRelComp,indThisRegion);
allRecChStimChPNames = stVar.commonChPerCompRegion(indRelComp,indThisRegion); %"recRECORDINGch stimSTIMch_pName"

% We can get the anat/trial info from the "abs" organization part -  since this is Variability the SAME channels are included in abs and relative var - it will not geenralize to other measures
for iComp=1:nStatesToCompare
    gralRegionRecCh{iComp}(1:length(relVarAll{iComp})) = {'other'};
    gralRegionStimCh{iComp}(1:length(relVarAll{iComp})) = {'other'};
    indAbsComp = [stVar.pairComps(indRelComp(iComp),:)];
    indIn1=[];indIn2=[];
    for iCh=1:length(allRecChStimChPNames{iComp})
        indIn1 = [indIn1, find(strcmpi(stVar.chNamesPNamesPerStatePerRegion{indAbsComp(1), indThisRegion}, allRecChStimChPNames{iComp}{iCh}))];
        indIn2 = [indIn2, find(strcmpi(stVar.chNamesPNamesPerStatePerRegion{indAbsComp(2), indThisRegion}, allRecChStimChPNames{iComp}{iCh}))];
    end
    anatRegionRecCh{iComp} = stVar.anatRegionsPerChPerState{indAbsComp(1)}(indIn1); % since this is Variability the SAME channels are included in abs and relative var - it will not geenralize to other measures
    nTrialsAbs1 = stVar.nTrialPerChPerStatePerRegion{indAbsComp(1), indThisRegion}; % since this is Variability the SAME channels are included in abs and relative var - it will not geenralize to other measures
    nTrialsAbs2 = stVar.nTrialPerChPerStatePerRegion{indAbsComp(2), indThisRegion}; % since this is Variability the SAME channels are included in abs and relative var - it will not geenralize to other measures
    nTrialsPerState{iComp}(1,1:length(relVarAll{iComp})) = nTrialsAbs1(indIn1)';
    nTrialsPerState{iComp}(2,1:length(relVarAll{iComp})) = nTrialsAbs2(indIn2)';
    nTrialsDiffPerState{iComp} = nTrialsAbs2(indIn2)-nTrialsAbs1(indIn1);
   
    [indRecPerRegion] = findChannelsWithinRegion(stVar.gralRegionsPerChPerState{indAbsComp(1)}, gralRegionNames);
    [indStimPerRegion] = findChannelsWithinRegion(stVar.gralRegionsStimChPerState{indAbsComp(1)}, gralRegionNames);
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
allRecCh=cell(1,nStatesToCompare);allStimCh=cell(1,nStatesToCompare);
allPNames=cell(1,nStatesToCompare);allStatesComp=cell(1,nStatesToCompare);
allStatesCompNumber=cell(1,nStatesToCompare);

for iComp=1:nStatesToCompare
    splitRecStimPName = split(allRecChStimChPNames{iComp},{' '});
     allRecCh{iComp}  = regexprep(squeeze(splitRecStimPName(:,:,1)),{'rec','_'},''); % remove also the _
    [splitStimPName, marker] = split(squeeze(splitRecStimPName(:,:,2)),{'p','sub'});  % SPECIFIC to participant ID
    allStimCh{iComp} = regexprep(squeeze(splitStimPName(:,:,1)),{'st','_'},'');
    allPNames{iComp} = strcat(marker, squeeze(splitStimPName(:,:,2)));

%    cAllRecChStimChPNames = split(allRecChStimChPNames{iCompState}, {' ','_'});
%    allRecCh{iCompState} = squeeze(cAllRecChStimChPNames(1,:,1));
%     allStimCh{iCompState} = squeeze(cAllRecChStimChPNames(1,:,2));
%     allPNames{iCompState} = squeeze(cAllRecChStimChPNames(1,:,3));
    allStatesComp{iComp} = repmat(stateCompNames(iComp),1,length(allPNames{iComp}));
    allStatesCompNumber{iComp} = repmat(iComp-1,1,length(allPNames{iComp}));
end
% Put togather all the states
Variability = [relVarAll{:}];
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

% recAnatRegionAll = reshape([recChWithinRegion{:}], length(regionNames),length(Variability));
% stimAnatRegionAll = reshape([stimChWithinRegion{:}], length(regionNames),length(Variability));

% Check for normality 
%figure;
%qqplot(Variability);
[hNorm pValNorm, kstat, cStat] = lillietest(Variability,'Alpha',0.01);
disp(['Normality Test (lillietest): for Rel Var ',stateCompNames{:}])
disp([' h=',num2str(hNorm),' pVal= ',num2str(pValNorm),' kStats= ',num2str(kstat),' criticalVal= ',num2str(cStat)])

% Construct LMM model
y = Variability';
X = [ones(size(y)), allStatesCompNumAllData', nTrialsAll',gralRegionRecChAllStates',gralRegionStimChAllStates'];
%X = [ones(size(y)), allStatesCompNumAllData',,sum(recAnatRegionAll,1)'];
Z = {ones(size(y)),  nTrialsAll', gralRegionRecChAllStates',gralRegionStimChAllStates'};%, ,sum(recAnatRegionAll,1)'
G = {pNumberAllStates',pNumberAllStates',pNumberAllStates',pNumberAllStates'};

% run LME
lmeRelVAr = fitlmematrix(X,y,Z,G,'FixedEffectPredictors',{'Intercept',['State',[stateCompNames{:}]],'nTrialsDiff','RecRegion','StimRegion'},...
    'RandomEffectPredictors',{'Intercept','nTrialsDiff','RecRegion','StimRegion'},'RandomEffectGroups',{'Participant','Participant','Participant','Participant'});% ,'FitMethod','REML');,'recRegion'
% Display LMM results
disp(['***********  Linear Mixed-effect Model Relative Variability ',[strcat(stateCompNames,' - ')],' *******************'])
lmeRelVAr.disp

disp(['***********  SIMPLER Linear Mixed-effect Model Relative Variability ',[strcat(stateCompNames,' - ')],' *******************'])
simplerLMERelVar = fitlmematrix(X,y,Z(:,1),G(:,1),'FixedEffectPredictors',{'Intercept',['State',[stateCompNames{:}]],'nTrialsDiff','RecRegion','StimRegion'},...
    'RandomEffectPredictor',{'Intercept'},'RandomEffectGroups',{'Participant'});% ,'FitMethod','REML');
simplerLMERelVar.disp

% Compare likeihood of models
compare(simplerLMERelVar,lmeRelVAr,'CheckNesting',true)
