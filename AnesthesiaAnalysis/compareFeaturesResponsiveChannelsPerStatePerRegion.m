function compareFeaturesResponsiveChannelsPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStats, whichRecChannels)
% need to specify channels and only AmpMaxMin, peak2peak and AUC can be computed

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);
stateColors = {'b','r','g','m'};
    
if ~isfield(cfgStats,'allStatesTitName'), cfgStats.allStatesTitName= cfgStats.allStates; end  % allStatesTitName is used to remove from titName (in order to match channels)
if ~isfield(cfgStats,'anatRegionFor'), cfgStats.anatRegionFor= 'stimCh'; end  % options: 'stimCh or respCh'
if ~exist('whichRecChannels','var'), whichRecChannels= 'RESPCH'; end  % options: 'RESPCH'=resp channels in all states / 'ANYSTATE'=resp channels in all states / 'ALLCH'=All recording channels

regionNames = cfgStats.regionsToCompare;

featureNames = cfgStats.featureNames;
if ~iscell(featureNames), featureNames={featureNames}; end
nFeatures = length(featureNames);

% Start Diary
if ~exist(dirResults,'dir'),mkdir(dirResults); end
diary([dirResults,filesep,'log','CompareFeatRespChannelsPerRegion',cfgStats.anatRegionFor,'.log'])

%% Get Features of Responsive channels for all states and stim channels
switch upper(whichRecChannels)
    case 'RESPCH'
        [featRespChPerState, chNamesPerState, stimSitesFeatPerState, anatRegionsFeatChPerState, anatRegionsFeatStimChPerState, pNamesPerState, meanValRespPerState, valPerStatePerPat, stimSitesPerStatePerPat, nTrialPerChPerState]...
            = getFeatureRespChannels(fileNameRespChAllPatAllStates, featureNames, cfgStats.stimChPerPat);
    case 'ANYSTATE'
        [featRespChPerState, chNamesPerState, stimSitesFeatPerState, anatRegionsFeatChPerState, anatRegionsFeatStimChPerState, pNamesPerState, meanValRespPerState, valPerStatePerPat, stimSitesPerStatePerPat, indRespChPerState, nTrialPerChPerState]...
            = getFeatureAllChannels(fileNameRespChAllPatAllStates, featureNames, cfgStats.stimChPerPat, cfgStats.respChAnyStaChPerPat); % if no respChAnyStaChPerPat it will return ALL chan
    case 'ALLCH'
        [featRespChPerState, chNamesPerState, stimSitesFeatPerState, anatRegionsFeatChPerState, anatRegionsFeatStimChPerState, pNamesPerState, meanValRespPerState, valPerStatePerPat, stimSitesPerStatePerPat, indRespChPerState, nTrialPerChPerState]...
            = getFeatureAllChannels(fileNameRespChAllPatAllStates, featureNames, cfgStats.stimChPerPat); % if no respChAnyStaChPerPat it will return ALL chan
    otherwise % default only respomsivce in that states 
        [featRespChPerState, chNamesPerState, stimSitesFeatPerState, anatRegionsFeatChPerState, anatRegionsFeatStimChPerState, pNamesPerState, meanValRespPerState, valPerStatePerPat, stimSitesPerStatePerPat]...
            = getFeatureRespChannels(fileNameRespChAllPatAllStates, featureNames, cfgStats.stimChPerPat);
end
%% Get anatomical information nRespChannels for all states and stim channels
% [anatRegionsRespChPerState, anatRegionsStimChPerState, anatRegionsPerChPerState, gralRegionsRespChPerState, gralRegionsStimChPerState, gralRegionsPerChPerState, chNamesRespPerState, chNamesPerState, stimSitesPerState, pNamesPerState, anatLabels, labelPerRegion] ...
%     = getRegionRespChannels(fileNameRespChAllPatAllStates, cfgStats.stimChPerPat);

%% Find which STIM channels are in the regions we want to compare
valFeatPerStatePerRegion = cell(nFeatures, nStates, length(regionNames));
respChFeatsPerStatePerRegion = cell(nStates,length(regionNames));
gralRegionsPerChPerState=cell(1,nStates);
gralRegionsStimChPerState=cell(1,nStates);
for iState=1:nStates
    % get general region (e.g. anterior or PFC) per STIM anatomical region
        [gralRegionPerStimCh, stStimChannelPerRegion, labelPerRegion] = getGralRegionPerChannel(anatRegionsFeatStimChPerState{iState});
        [gralRegionPerRecCh, stRecChannelPerRegion, labelPerRegion] = getGralRegionPerChannel(anatRegionsFeatChPerState{iState});
        gralRegionsPerChPerState{iState} = stRecChannelPerRegion;
        gralRegionsStimChPerState{iState} = stStimChannelPerRegion;
        % feature value Resp per STIM region
        for iFeat = 1:length(featureNames)
            [indChWithinStimRegion, valFeatureWithinStimRegion, respChNamesFeatsPerStimRegion] = findChannelsWithinRegion(stStimChannelPerRegion, regionNames, featRespChPerState{iState, iFeat}, chNamesPerState{iState});
            [indChWithinRecRegion, valFeatureWithinRecRegion, respChNamesFeatsPerRecRegion] = findChannelsWithinRegion(stRecChannelPerRegion, regionNames, featRespChPerState{iState, iFeat}, chNamesPerState{iState});
            for iRegion=1:length(regionNames)
                if strcmpi(cfgStats.anatRegionFor,'stimCh')
                    valFeatPerStatePerRegion{iFeat,iState,iRegion} = nan(1,length(valFeatureWithinStimRegion{iRegion}));
                    valFeatPerStatePerRegion{iFeat,iState,iRegion}(indChWithinStimRegion{iRegion}) = valFeatureWithinStimRegion{iRegion}(indChWithinStimRegion{iRegion});
                    respChFeatsPerStatePerRegion{iState,iRegion}  = respChNamesFeatsPerStimRegion{iRegion};
                elseif strcmpi(cfgStats.anatRegionFor,'onlyrespCh')
                    valFeatPerStatePerRegion{iFeat,iState,iRegion} = nan(1,length(valFeatureWithinRecRegion{iRegion}));
                    valFeatPerStatePerRegion{iFeat,iState,iRegion}(indChWithinRecRegion{iRegion}) =  valFeatureWithinRecRegion{iRegion}(indChWithinRecRegion{iRegion});
                    respChFeatsPerStatePerRegion{iState,iRegion}  = respChNamesFeatsPerRecRegion{iRegion};
                elseif strcmpi(cfgStats.anatRegionFor,'stimrespCh') %  both stim and recording resp Ch (within the same region)
                    valFeatPerStatePerRegion{iFeat,iState,iRegion} = nan(1,length(valFeatureWithinRecRegion{iRegion}));
                    indChWithinRegion = intersect(indChWithinStimRegion{iRegion},indChWithinRecRegion{iRegion});
                    valFeatPerStatePerRegion{iFeat,iState,iRegion}(1,indChWithinRegion) = valFeatureWithinRecRegion{iRegion}(indChWithinRegion);
                    respChFeatsPerStatePerRegion{iState,iRegion} = cell(1,length(respChNamesFeatsPerRecRegion{iRegion}));
                    respChFeatsPerStatePerRegion{iState,iRegion}(1,indChWithinRegion) = respChNamesFeatsPerRecRegion{iRegion}(indChWithinRegion);
                else % All Regions - The original - it repeats the same info for each region
                    valFeatPerStatePerRegion{iFeat,iState,iRegion} = featRespChPerState{iState, iFeat};
                    respChFeatsPerStatePerRegion{iState,iRegion}  = chNamesPerState{iState};                    
                end
            end
        end
    % Resp channels per STIM region
  %  [indRecChWithinRegions{iState}] = findChannelsWithinRegion(gralRegionsPerChPerState{iState}, regionNames);
end

%% Plot all regions together
% Plot only those with corresponding stim channels
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
dirImagesPerRegion = [dirResults,filesep,'images'];
cfgStats.dirImages = dirImagesPerRegion;
cfgStats.legLabel = cfgStats.allStates;
% Repeat for FEATURE value of responsive channels
cfgStats.bipolarChannels = chNamesPerState;
for iFeat = 1:length(featureNames)
    cfgStats.ylabel = [featureNames{iFeat}, ' RespCh '] ;
    titName = [cfgStats.titName,' ',featureNames{iFeat}];
    plotWakeVsAnesthesiaPerCh([], featRespChPerState(:, iFeat), titName, cfgStats, pairComps);
    % plot also histogram of features 
    figure; hold on;
    tempFeatVals = [featRespChPerState{:, iFeat}];
    tempFeatVals(isinf(tempFeatVals))=[];
  %  histEdges = 0:max(tempFeatVals)/25:max(tempFeatVals);
    for iState=1:nStates
        subplot(nStates,1,iState)
        featValsToPlot = featRespChPerState{iState, iFeat};
        featValsToPlot(featValsToPlot==0)=[]; % rempove zero values
        histogram(featValsToPlot,'Normalization','probability','FaceAlpha',0.3,'FaceColor',stateColors{iState})
        ylabel(cfgStats.allStates{iState})
        xlim([0 max(tempFeatVals)])
    end
    xlabel(featureNames{iFeat})
    %Save figure
    titNameForFile = ['Hist_',regexprep(titName,'\W','_')];
    saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.png']);
    saveas(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.svg']);
    savefig(gcf,[cfgStats.dirImages, filesep,titNameForFile,'.fig'],'compact');
end
close all;

%% Stats All Stim regions together - Features per Resp channels
cfgStats.bipolarChannels = chNamesPerState;
for iComp=1:size(pairComps,1)
    [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
    legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(indIn1)),')']);
    % Feature Value Resp Ch
    for iFeat = 1:length(featureNames)
        titName = [cfgStats.titName,' ',featureNames{iFeat},' ',num2str([pairComps(iComp,:)])];
        cfgStats.sheetName = [featureNames{iFeat}];
        featValToCompare = featRespChPerState(:, iFeat);
        [pairedTtest] = computePairedTtestSaveInXls(featValToCompare{pairComps(iComp,1)}(indIn1),featValToCompare{pairComps(iComp,2)}(indIn2),[titName],legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
        disp([cfgStats.sheetName,' between ',[legLabel{:}], ' ',' - pVal= ', num2str(pairedTtest)])
    end
end
% statsResults.WithStimChAllRegions.indWithRepCh = indWithRepCh;
% statsResults.WithStimChAllRegions.indWithRespPerComp = indWithRespPerComp;
% statsResults.WithStimChInRegion.stimSitesPerComparison = stimSitesPerComparison;
statsResults.cfgStats = cfgStats;


%% PLot within stim region 
    % Plot only those with corresponding stim channels
pairComps = [3,1;2,1;4,3]; % 1. WakeORvs.WakeEMU / 2.Sleepvs.WakeEMU / 3.AnesthesiavsWakeOR
for iRegion=1:length(regionNames)
    titNamePerRegion = [cfgStats.titName,' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion}] ;
    cfgStats.legLabel = cfgStats.allStates;
    % Repeat for FEATURE value of responsive channels
    cfgStats.bipolarChannels = respChFeatsPerStatePerRegion(:,iRegion);
    for iFeat = 1:length(featureNames)
        titName = [titNamePerRegion,' ',featureNames{iFeat}];
        cfgStats.ylabel = [featureNames{iFeat}, ' RespCh ', regionNames{iRegion}] ;
        plotWakeVsAnesthesiaPerCh([], squeeze(valFeatPerStatePerRegion(iFeat,:,iRegion)), titName, cfgStats, pairComps);
   end
   % plot also histogram of features
   tempFeatVals = [valFeatPerStatePerRegion{iFeat,:,iRegion}];
   tempFeatVals(isinf(tempFeatVals))=[];
%   histEdges = 0:max(tempFeatVals)/25:max(tempFeatVals);
   figure; hold on;
   for iState=1:nStates
       subplot(nStates,1,iState)
       featValsToPlot = valFeatPerStatePerRegion{iFeat,iState,iRegion};
       featValsToPlot(featValsToPlot==0)=[]; % rempove zero values
       histogram(featValsToPlot,'Normalization','probability','FaceAlpha',0.3,'FaceColor',stateColors{iState})
       ylabel(cfgStats.allStates{iState})
        xlim([0 max(tempFeatVals)])
    end
    xlabel(featureNames{iFeat})
    %Save figure
    titNameForFile = ['Hist_',regexprep(titName,'\W','_')];
    dirImagesPerRegion = [cfgStats.dirImages,filesep, regionNames{iRegion}];
    if ~exist(dirImagesPerRegion,'dir'), mkdir(dirImagesPerRegion); end
    saveas(gcf,[dirImagesPerRegion, filesep,titNameForFile,'.png']);
    saveas(gcf,[dirImagesPerRegion, filesep,titNameForFile,'.svg']);
    savefig(gcf,[dirImagesPerRegion, filesep,titNameForFile,'.fig'],'compact');
end
close all;

%% Stats within Stim region - Features per Resp channels (paired comparison of ONLY those channels with response in BOTH states)
for iRegion=1:length(regionNames)
    cfgStats.bipolarChannels = respChFeatsPerStatePerRegion(:,iRegion);
    titNamePerRegion = [cfgStats.titName, ' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion}] ;
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileNamePerRegion = [filepath,filesep,name,'_',regionNames{iRegion},ext] ;
    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).pairComps = pairComps;
    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).legLabel = cfgStats.legLabel;
    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).bipolarChannels = cfgStats.bipolarChannels;
    statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).nTrialsPerState = nTrialPerChPerState;

    dirImagesPerRegion = [cfgStats.dirImages, filesep, regionNames{iRegion}];

    for iComp=1:size(pairComps,1)
        [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
        if length(commonCh)>1
            legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(indIn1)),')']);
            % Feature Value Resp Ch
            for iFeat = 1:length(featureNames)
                titName = [titNamePerRegion,' ',featureNames{iFeat},' ',num2str([pairComps(iComp,:)])];
                cfgStats.sheetName = ['Pair',featureNames{iFeat}(1:min(6,end)),'_',regionNames{iRegion}]; % 1:6 to ensure sheet name is within 31 chars
                featValToCompare = squeeze(valFeatPerStatePerRegion(iFeat,:,iRegion));
                featVals1 = featValToCompare{pairComps(iComp,1)}(indIn1);
                featVals2 = featValToCompare{pairComps(iComp,2)}(indIn2);
                [pairedTtest, medianVal1, medianVal2, testName] = computePairedTtestSaveInXls(featVals1,featVals2,titName,legLabel,xlsFileNamePerRegion,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],dirImagesPerRegion,cfgStats.useParam);
                disp([testName, ': ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
                relativeFeat = (featVals1 - featVals2) ./(featVals1 + featVals2);
                stRelativeFeatPerRegion{iComp,iRegion}.(featureNames{iFeat}) = relativeFeat;
                
                %save stats
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).pVal = pairedTtest;
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).median1 = medianVal1;
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).median2 = medianVal2;
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).relativeNResp = relativeFeat;
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).q025075Feat1 = [quantile(featVals1, 0.25) quantile(featVals1, 0.75)];
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).q025075Feat2 = [quantile(featVals2, 0.25) quantile(featVals2, 0.75)];
                statsResults.FeaturesRespPerRegion.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).commonCh =commonCh;
            end
        else
            for iFeat = 1:length(featureNames), stRelativeFeatPerRegion{iComp,iRegion}.(featureNames{iFeat}) = NaN;end
        end
        stimChPerCompRegion{iComp,iRegion} = commonCh;
    end
end
%statsResults.FeaturesRespPerRegion.indWithRepCh = indWithRepCh;
%statsResults.FeaturesRespPerRegion.indWithRespPerComp = indWithRespPerComp;
statsResults.FeaturesRespPerRegion.stimChPerCompRegion = stimChPerCompRegion;
statsResults.FeaturesRespPerRegion.pairComps = pairComps;
statsResults.cfgStats = cfgStats;

%% Relative comparison: Anesthesia-WakeOR vs Sleep-WakeEMU
%relativeRespTypes = struct('nResp', relativeNResp,'perResp', relativePercResp, 'perTOTAL',relativePercTOTResp,'perWITHIN',relativePercWithinResp);

%Plot
for iRegion=1:length(regionNames)
    for iFeat = 1:length(featureNames)
        figure; hold on;
        for iComp=1:size(pairComps,1)
            stRelativeFeat = stRelativeFeatPerRegion{iComp,iRegion};
            if isfield(stRelativeFeat,featureNames{iFeat})
                relativeFeat = stRelativeFeat.(featureNames{iFeat});
                subplot(1,2*size(pairComps,1),iComp*2-1)
                plot(relativeFeat,'.','MarkerSize',20);
                line([1 length(relativeFeat)],[0 0],'Color', 'k','LineWidth',3)
                line([1 length(relativeFeat)],[median(relativeFeat) median(relativeFeat)],'Color', 'r','LineWidth',3)
                ylim([-1 1])
                xlim([0 length(relativeFeat)+1])
                grid on;
                legLabel= strcat(cfgStats.legLabel(pairComps(iComp,:)),[' (', num2str(length(relativeFeat)),')']);
                xticklabels({})
                
                title([legLabel{:}]);
                % boxplot of same data
                subplot(1,2*size(pairComps,1),iComp*2)
                boxplot(relativeFeat)
                ylim([-1 1])
                yticklabels({})
                xticklabels([regionNames{iRegion}, ' ', num2str([pairComps(iComp,:)])])
            end
        end
        suptitle(['Rel ',featureNames{iFeat},' Ch ', regionNames{iRegion}])
        %Save figure
        titNameForFile = ['Rel_',regexprep([cfgStats.titName, featureNames{iFeat}, regionNames{iRegion}],'\W','_')];
        if ~exist([cfgStats.dirImages, filesep, featureNames{iFeat}],'dir'), mkdir([cfgStats.dirImages, filesep, featureNames{iFeat}]);end
        saveas(gcf,[cfgStats.dirImages, filesep, featureNames{iFeat},filesep, titNameForFile,'.png']);
        saveas(gcf,[cfgStats.dirImages, filesep,featureNames{iFeat},filesep, titNameForFile,'.svg']);
        savefig(gcf,[cfgStats.dirImages, filesep,featureNames{iFeat},filesep, titNameForFile,'.fig'],'compact');
    end
end
close all;

%% compare Anesthesia-WakeOR vs Sleep-WakeEMU ONLY for those with all states
indCompSleepWakeEMU =2;
indCompAnesthesiaWakeOR =3;
legComp = {[cfgStats.legLabel{pairComps(indCompSleepWakeEMU,:)}],[cfgStats.legLabel{pairComps(indCompAnesthesiaWakeOR,:)}]};
for iRegion=1:length(regionNames)
    [indIn1, indIn2, commonCh] = strmatchAll(stimChPerCompRegion{indCompSleepWakeEMU,iRegion}, stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion});
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileNamePerRegion = [filepath,filesep,name,'_RelFeat_',regionNames{iRegion},ext] ;
    if ~isempty(commonCh)
        statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).commonCh =commonCh;
        for iFeat = 1:length(featureNames)
            stRelativeFeatSleep = stRelativeFeatPerRegion{indCompSleepWakeEMU,iRegion};
            relativeRespSleep = stRelativeFeatSleep.(featureNames{iFeat});
            stRelativeRespAnesthesia = stRelativeFeatPerRegion{indCompAnesthesiaWakeOR,iRegion};
            relativeRespAnesthesia = stRelativeRespAnesthesia.(featureNames{iFeat});

            if ~isempty(relativeRespSleep) && ~isempty(relativeRespAnesthesia) && ~all(isnan(relativeRespSleep(indIn1))) && ~all(isnan(relativeRespAnesthesia(indIn2)))
                % # Responsive channels - PAIRED STATS!
                legLabel= strcat('RelPAIRED',legComp,[' (', num2str(length(indIn1)),')']);
                cfgStats.sheetName = ['RelPAIR',regionNames{iRegion}(1:min(5,end)),'_',featureNames{iFeat}(1:min(6,end)),'SlAn'];
                titName = ['RelPAIRED ',regionNames{iRegion}, ' ',featureNames{iFeat},' Sleep-Anest'];%cfgStats.titName
                [pairedTtest, medianVal1, medianVal2, testName] = computePairedTtestSaveInXls(relativeRespSleep(indIn1),relativeRespAnesthesia(indIn2),titName,legLabel,xlsFileNamePerRegion,[cfgStats.sheetName],[cfgStats.dirImages,filesep,'RelativePairedStats'],cfgStats.useParam);
                disp([testName, ': ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N= ',num2str(length(indIn1))])
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).pVal = pairedTtest;
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).medianRelSleepWakeEMU = medianVal1;
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).medianRelAnesthWakeOR = medianVal2;
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).commonCh =commonCh;
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).relSleepWakeEMU = relativeRespSleep(indIn1);
                statsResults.RelFeatSleepAnesth.(regionNames{iRegion}).(featureNames{iFeat}).relAnesthesiaWakeOR = relativeRespAnesthesia(indIn2);
                % # Responsive channels NON-PAIR stats
                legLabel= strcat('RelNONPAIR',legComp,' (', {num2str(length(relativeRespSleep)),num2str(length(relativeRespAnesthesia))},')');
                cfgStats.sheetName = ['RelNONPAIR',regionNames{iRegion}(1:min(5,end)),featureNames{iFeat}(1:min(6,end)),'SlAn'];
                titName = ['RelNONPAIR ',cfgStats.titName,' ', featureNames{iFeat},' Sleep-Anest'];
                [nonpairedTtest, medianVal1, medianVal2, testName] = computeRankSumSaveInXls(relativeRespSleep,relativeRespAnesthesia,titName,legLabel,xlsFileNamePerRegion,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],[cfgStats.dirImages,filesep,'RelativeNonPairedStats'],cfgStats.useParam);
                disp([testName, ': ', cfgStats.sheetName,' between ','RelSleepWakeEMU vs RelAnesthWakeOR', ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relativeRespSleep)),' N2= ',num2str(length(relativeRespAnesthesia))])
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).pVal = nonpairedTtest;
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).medianRelSleepWakeEMU = medianVal1;
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).medianRelAnesthWakeOR = medianVal2;
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).chNamesEMU =stimChPerCompRegion{indCompSleepWakeEMU,iRegion};
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).chNamesOR =stimChPerCompRegion{indCompAnesthesiaWakeOR,iRegion};
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).relSleepWakeEMU = relativeRespSleep;
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).relAnesthesiaWakeOR = relativeRespAnesthesia;
                statsResults.RelFeatSleepAnesthNONPAIRED.(regionNames{iRegion}).(featureNames{iFeat}).testName = testName;
            end
        end
    end
end


%% Compare specific regions within same state
regionNamesToCompare= {'frontal', 'posterior','temporal'}; % frontal=PFC and OF / anterior
%regionNamesToCompare= {'anterior', 'posterior','temporal'}; % frontal=PFC and OF / anterior includes ACC
indRegionToCompare= strmatchAll(regionNames,regionNamesToCompare);
pairRegionsComp = [indRegionToCompare(1),indRegionToCompare(2);...
                   indRegionToCompare(1),indRegionToCompare(3);...
                   indRegionToCompare(2),indRegionToCompare(3)];
for iRelState=1:size(pairComps,1)
    thisRelState = [cfgStats.legLabel{pairComps(iRelState,1)}(1:2),cfgStats.legLabel{pairComps(iRelState,2)}(1:2)];
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileNamePerComp = [filepath,filesep,name,'_FrontalPosterior_',ext] ;
    for iCompRegion=1:size(pairRegionsComp,1)
        thisRegionsToCompare = [regionNames{pairRegionsComp(iCompRegion,:)}];
        for iFeat = 1:length(featureNames)
            stRelativeFeat = stRelativeFeatPerRegion{iRelState, pairRegionsComp(iCompRegion,1)};
            relativeRespRegion1 = stRelativeFeat.(featureNames{iFeat});
            stRelativeFeat = stRelativeFeatPerRegion{iRelState, pairRegionsComp(iCompRegion,2)};
            relativeRespRegion2 = stRelativeFeat.(featureNames{iFeat});
            
            if ~isempty(relativeRespRegion1) && ~isempty(relativeRespRegion2)
                % # Responsive channels NON-PAIR stats
                legLabel= strcat('Rel ',regionNames(pairRegionsComp(iCompRegion,:)),' (', {num2str(length(relativeRespRegion1)),num2str(length(relativeRespRegion2))},')');
                cfgStats.sheetName = ['Rel',featureNames{iFeat}(1:min(6,end)),thisRelState,thisRegionsToCompare];
                titName = ['Rel',cfgStats.titName, featureNames{iFeat},' ',thisRelState,' ',thisRegionsToCompare];
                [nonpairedTtest, medianVal1, medianVal2, testName] = computeRankSumSaveInXls(relativeRespRegion1,relativeRespRegion2,titName,legLabel,xlsFileNamePerComp,[cfgStats.sheetName,num2str([pairRegionsComp(iCompRegion,:)])],[cfgStats.dirImages,filesep,'RelativeCompareRegions'],cfgStats.useParam);
                disp([testName, ': ', cfgStats.sheetName,' between ',thisRegionsToCompare, ' ', cfgStats.anatRegionFor,' ', thisRelState,' ',featureNames{iFeat},' - pVal= ', num2str(nonpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),' N1= ',num2str(length(relativeRespRegion1)),' N2= ',num2str(length(relativeRespRegion2))])
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).pVal = nonpairedTtest;
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).(['median',regionNames{pairRegionsComp(iCompRegion,1)}]) = medianVal1;
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).(['median',regionNames{pairRegionsComp(iCompRegion,2)}]) = medianVal2;
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).chNamesRegion1 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,1)};
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).chNamesRegion2 =stimChPerCompRegion{iRelState,pairRegionsComp(iCompRegion,2)};
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).relativeRespRegion1 = relativeRespRegion1;
                statsResults.RelFeatRegionsNONPAIRED.(thisRelState).(thisRegionsToCompare).(featureNames{iFeat}).relativeRespRegion2 = relativeRespRegion2;
            end
        end
    end
end


%% Stats of ALL responsive channels (RankSum/Permutation  = non paired test)
    % it is non paired but ONLY with same STIM-pNames
for iRegion=1:length(regionNames)
    cfgStats.bipolarChannels = respChFeatsPerStatePerRegion(:,iRegion);
    titNamePerRegion = [cfgStats.titName, ' ', cfgStats.anatRegionFor, ' ', regionNames{iRegion}] ;
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    xlsFileNamePerRegion = [filepath,filesep,name,'_RelFeatNonPaired_',regionNames{iRegion},ext] ;
    for iComp=1:size(pairComps,1)
        % Feature Value Resp Ch
        for iFeat = 1:length(featureNames)
            titName = [titNamePerRegion,' ',featureNames{iFeat},' ',num2str([pairComps(iComp,:)])];
            cfgStats.sheetName = ['NonPaired',featureNames{iFeat}(1:min(10,end)),'_',regionNames{iRegion}];
            featValToCompare = squeeze(valFeatPerStatePerRegion(iFeat,:,iRegion));
            lengthFeat1 = length(find(~isnan(featValToCompare{pairComps(iComp,1)})));
            lengthFeat2 = length(find(~isnan(featValToCompare{pairComps(iComp,2)})));
            legLabel(1)= strcat(cfgStats.legLabel(pairComps(iComp,1)),' (', num2str(lengthFeat1),')');
            legLabel(2)= strcat(cfgStats.legLabel(pairComps(iComp,2)),' (', num2str(lengthFeat2),')');
            [unpairedTtest, medianVal1, medianVal2, testName] = computeRankSumSaveInXls(featValToCompare{pairComps(iComp,1)},featValToCompare{pairComps(iComp,2)},titName,legLabel,xlsFileNamePerRegion,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
            disp([testName, ': ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', cfgStats.anatRegionFor,' ', regionNames{iRegion},' - pVal= ', num2str(unpairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
            %save stats
            statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).pVal = unpairedTtest;
            statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).median1 = medianVal1;
            statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).median2 = medianVal2;
            statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).nVals1 = lengthFeat1;
            statsResults.FeaturesRespPerRegionNONPAIRED.(regionNames{iRegion}).([cfgStats.legLabel{pairComps(iComp,:)}]).(featureNames{iFeat}).nVals2 = lengthFeat2;
        end
    end
end




%% Save info in MAT file
    [filepath,name,ext] = fileparts(cfgStats.xlsFileName);
    matFileNameResults = [filepath,filesep,'FeatRespChPerRegion_',name,'.mat'] ;

save([matFileNameResults], 'regionNames', 'featureNames', 'cfgStats', 'fileNameRespChAllPatAllStates',...
    'valFeatPerStatePerRegion','respChFeatsPerStatePerRegion', 'pairComps',...
    'featRespChPerState', 'chNamesPerState', 'stimSitesFeatPerState','pNamesPerState',...
    'statsResults','anatRegionsFeatChPerState', 'anatRegionsFeatStimChPerState', 'gralRegionsPerChPerState','gralRegionsStimChPerState',...
     'meanValRespPerState', 'valPerStatePerPat','stimSitesPerStatePerPat','labelPerRegion',...
    'stimChPerCompRegion','regionNamesToCompare','pairRegionsComp','nTrialPerChPerState');

diary off;

