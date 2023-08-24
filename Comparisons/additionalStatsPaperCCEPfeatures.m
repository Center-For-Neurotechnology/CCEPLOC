function additionalStatsPaperCCEPfeatures(dirGralResults, featNames, regionName, whichRecChannels)

%featNames = {'ptpResponsiveCh', 'locFirstPeakRespCh','ampResponsiveCh','locMaxPeakRespCh'};%    {'ampResponsiveCh'}    {'ptpResponsiveCh'}    {'locFirstPeakRespCh'}    {'locMaxPeakRespCh'}    {'prominencePerCh'}    {'peakMaxMinAmpPe…'}    {'areaP2PPerCh'}

anatRegionType = 'OnlyRespCh';
%considerChInElectrodeShaft = 
useParam = 2; %permutation test
%regionName = {'anterior', 'posterior', 'temporal','frontal'};
nPatients= 20;
%considerChInElectrodeShaft=0;
posFixDir = '_Neuron2023'; %'_LP_CCEP'; %'_noSTIM'; %'_LP_CCEP2'; %'_raw'; %'_ALPHA';

dirImages = [dirGralResults, filesep, 'plotsLOCpaper',posFixDir,filesep,'images','CCEPfeat'];

%PCIFileName = [dirGralResults, filesep, 'PCIResults', filesep, 'PERTRIAL_Clean20nonSOZt0-600',posFixDir,filesep,'PCIStimCh',filesep,'PCIPerRegion_PCI StimCh',num2str(nPatients),'pat.mat'];
%respChFileName = [dirGralResults, filesep, 'ConnectivityResults', filesep, posFixDir,filesep,'PERTRIALnonSOZ_Clean20',filesep,'nResp min5NoSOZStimCh',filesep,'nRespChPerRegion_nResp min5NoSOZ_StimCh',num2str(nPatients),'pat.mat'];
 
dirRespFeatChPooled = [dirGralResults,filesep,'Feat',whichRecChannels,anatRegionType];
respFeatChFileName = [dirRespFeatChPooled,filesep,'FeatRespChPerRegion_','Feat',whichRecChannels,'_',anatRegionType,'_',num2str(nPatients),'pat','.mat'];
 
if ~isdir(dirImages), mkdir(dirImages);end


%% Load Features
stFeat = load(respFeatChFileName);
regionNames = stFeat.regionNames;
cfgStats = stFeat.cfgStats;
allStates = cfgStats.allStates;
nStates = numel(allStates);
indRegion = find(strcmpi(regionName, regionNames));
stimSitesPerState = stFeat.stimSitesFeatPerState(:,indRegion);

featureNames = stFeat.featureNames;
for iFeat=1:length(featNames)
    indFeat = strcmpi(featNames{iFeat}, featureNames);
    featPerStateRegion{iFeat} = squeeze(stFeat.valFeatPerStatePerRegion(indFeat,:,indRegion));
    relFeat{iFeat}{1} = stFeat.statsResults.FeaturesRespPerRegion.(regionName).WakeORWakeEMU.(featNames{iFeat}).relativeNResp; % We might want to add the relative value directly!
    relFeat{iFeat}{2} = stFeat.statsResults.FeaturesRespPerRegion.(regionName).SleepWakeEMU.(featNames{iFeat}).relativeNResp; 
    relFeat{iFeat}{3} = stFeat.statsResults.FeaturesRespPerRegion.(regionName).AnesthesiaWakeOR.(featNames{iFeat}).relativeNResp;
end
recChannelsPerState = stFeat.respChFeatsPerStatePerRegion(:,indRegion);%chNamesPNamesPerState;
anatRegionsPerState = stFeat.anatRegionsFeatChPerState;
anatRegionsStimPerState = stFeat.anatRegionsFeatStimChPerState;
%     relCommonRecCh{1} = stFeat.statsResults.FeaturesRespPerRegion.(regionName).WakeORWakeEMU.(featNames{1}).commonCh; % We might want to add the relative value directly!
%     relCommonRecCh{2} = stFeat.statsResults.FeaturesRespPerRegion.(regionName).SleepWakeEMU.(featNames{1}).commonCh; 
%     relCommonRecCh{3} = stFeat.statsResults.FeaturesRespPerRegion.(regionName).AnesthesiaWakeOR.(featNames{1}).commonCh;

relCommonRecCh = stFeat.stimChPerCompRegion(:,indRegion);

%% Save recording channels with value, name and region
xlsFileName = [dirGralResults, filesep, 'ChannelNamesCCEPFeatures_',whichRecChannels,'_',regionName,'.xlsx'];
colHeaders = {'RecChannnel', 'StimChannel','pName', 'AnatRegion', 'StimAnatRegion'};
colHeaders =[colHeaders, featNames];
nCols = length(colHeaders);

for iState=1:nStates
    tit =['Feat ',regionName,' ',allStates{iState}];
    % divide in rec - stim -pName
%     splitRecStimPName = split(recChannelsPerState{iState},{' ','_'});
%     recChannels = regexprep(squeeze(splitRecStimPName(:,:,1)),'rec','');
%     stimChannels = regexprep(squeeze(splitRecStimPName(:,:,2)),'st','');
%     pNames = squeeze(splitRecStimPName(:,:,3));

    [splitStimPName, marker] = split(stimSitesPerState{iState},{'p','sub'}); % SPECIFIC to participants ID
    stimChannels{iState} = regexprep(squeeze(splitStimPName(:,:,1)),{'st','_'},'');
    pNames{iState} = strcat(marker, squeeze(splitStimPName(:,:,2)));
 
    indSplit = cell2mat(regexp(recChannelsPerState{iState},{'_(\D)'},'once')); %stimSitesPerState{iState},''); % separate rec from stim_pName
    recChannels=cell(0,0);
    for iCh=1:length(indSplit), recChannels{iCh} = recChannelsPerState{iState}{iCh}(1:indSplit-1); end
  
    sheetName = tit;
    m4Save{1,1} = cfgStats.anatRegionFor;
    m4Save{1,2} = tit;
    m4Save{2,1} = respFeatChFileName;

    m4Save(3,1:nCols) = colHeaders;
    m4Save(4:length(recChannels)+3, 1) = recChannels;
    m4Save(4:length(recChannels)+3, 2) = stimChannels{iState};
    m4Save(4:length(recChannels)+3, 3) = pNames{iState};
    m4Save(4:length(recChannels)+3, 4) = anatRegionsPerState{iState};
    m4Save(4:length(recChannels)+3, 5) = anatRegionsStimPerState{iState};
    
    for iFeat=1:length(featNames)
        m4Save(4:length(featPerStateRegion{iFeat}{iState})+3, 5+iFeat) = num2cell(featPerStateRegion{iFeat}{iState});
    end

    xlswrite([xlsFileName], m4Save, sheetName);
    clear m4Save;
end


%% Save also ONLY common pairs
pairComps = stFeat.pairComps;% [1,3;1,2;3,4];

colHeaders = {'RecChName','STIMChName','pName','AnatRegion','StimAnatRegion'};
colHeaders = [colHeaders,strcat('Rel',featNames)];
colHeaders = [colHeaders,strcat(featNames,'1'),strcat(featNames,'2')];
colHeaders = [colHeaders,'STIMChCommon',' ',regionNames]; % add region info

for iComp=1:size(pairComps,1)
    tit =['RelFeat ',allStates{pairComps(iComp,:)}]; %regionName,' ',
%     splitRecStimPName = split(relCommonRecCh{iComp},{' ','_'});
%     recChannels = regexprep(squeeze(splitRecStimPName(:,:,1)),'rec','');
%     stimChannels = regexprep(squeeze(splitRecStimPName(:,:,2)),'st','');
%     pNames = squeeze(splitRecStimPName(:,:,3));
    
    [indRelInVar1, indRelInVarState, commonRelChVar] = strmatchAll(relCommonRecCh{iComp}, recChannelsPerState{pairComps(iComp,1)});
    [indInVar1, indInVar2, commonChVar] = strmatchAll( recChannelsPerState{pairComps(iComp,1)}, recChannelsPerState{pairComps(iComp,2)});

    sheetName = tit;
    
    m4Save{1,1} = cfgStats.anatRegionFor;
    m4Save{1,2} = tit;
    m4Save{2,1} = respFeatChFileName;

    m4Save{2,7} = allStates{pairComps(iComp,1)};      m4Save{2,9} = allStates{pairComps(iComp,2)};
    m4Save(3,1:length(colHeaders)) = colHeaders;
    
    indRow = 4;
   
    indSplit = regexp(relCommonRecCh{iComp},{'_(\D)'}); %stimSitesPerState{iState},''); % separate rec from stim_pName
    for iCh=1:numel(relCommonRecCh{iComp})
  %        splitRecStimPName = split(relCommonRecCh{iComp}{iCh},{' ','_'});
      
            m4Save{indRow,1}  = relCommonRecCh{iComp}{iCh}(1:indSplit{iCh}(1)-1); %R ch
            m4Save{indRow,2}  = relCommonRecCh{iComp}{iCh}(indSplit{iCh}(1)+1:indSplit{iCh}(2)-1); %STIm ch
            m4Save{indRow,3}  = relCommonRecCh{iComp}{iCh}(indSplit{iCh}(2)+1:end); %pNames ch is the last
            m4Save{indRow,4}  = anatRegionsPerState{pairComps(iComp,1)}{indRelInVarState(iCh)}; % Anat region
            m4Save{indRow,5}  = anatRegionsStimPerState{pairComps(iComp,1)}{indRelInVarState(iCh)}; % Anat region
            % Relative values State 1-2
            indCol=5;
            for iFeat=1:length(featNames)
                indCol = indCol+1;
                m4Save{indRow,indCol}  = relFeat{iFeat}{iComp}(iCh); % Relative Features
            end
 % State 1
             indStateInComp=1;
             for iFeat=1:length(featNames)
                indCol = indCol+1;
                 m4Save{indRow,indCol}  = featPerStateRegion{iFeat}{pairComps(iComp,indStateInComp)}(indInVar1(iCh)); % Features State 1
             end
 % State 2
             indStateInComp=2;
             for iFeat=1:length(featNames)
                indCol = indCol+1;
                 m4Save{indRow,indCol}  = featPerStateRegion{iFeat}{pairComps(iComp,indStateInComp)}(indInVar2(iCh)); % Features State 2
             end

%             % Add region info - leave 1 col empty
%             indCol = 12;
%             m4Save(indRow,indCol+1:indCol+numel(regionNamesVar))  = num2cell(isInRegionResp{pairComps(iComp,1)}(:,indInResp1(iCh))'); % whether is in each of the regions

            indRow = indRow+1;
    end
    % save in xls
    % sheetName; %strcat(allStates{pairComps(iComp,:)});
%      save([fileNameSummary,'.mat'], 'allStates','m4Save','pairComps','iComp','xlsSheet','xlsHeader',...
%         'stimSitesPerStateVar','anatRegionsVar','meanRelVariabilityPerState','stdRelVariabilityPerState');
    if (ispc)
        xlswrite([xlsFileName], m4Save, sheetName); % ONLY in Windows!
    end
    clear m4Save;
end

%% Save another Sheet with average per patient
for iComp=1:size(pairComps,1)
    colHeaders = {'pName','numel','mean','median','std','min','max'};
    tit =['AvPerPat ',allStates{pairComps(iComp,:)}]; %regionName,' ',
    sheetName = tit;
    
    [splitRecStimPName, marker] = split(relCommonRecCh{iComp},{'p','sub'}); % specific to participants ID
    pNames = strcat(marker, squeeze(splitRecStimPName(:,:,2)));
    
    m4Save{1,1} = cfgStats.anatRegionFor;
    m4Save{1,2} = tit;
    m4Save{2,1} = respFeatChFileName;

    m4Save{2,3} = allStates{pairComps(iComp,1)};      m4Save{2,4} = allStates{pairComps(iComp,2)};
    indRow = 5;
    indCol=1;
   for iFeat=1:length(featNames)
        m4Save{3,indCol} =strcat('Rel',featNames{iFeat});
        m4Save(4,indCol:length(colHeaders)+indCol-1) = colHeaders;
        [statsPerPat.pNames, statsPerPat.numel,statsPerPat.mean,statsPerPat.median,statsPerPat.std,statsPerPat.min,statsPerPat.max] = ...
            grpstats(relFeat{iFeat}{iComp}', pNames',{'gname','numel','nanmean','nanmedian','std','min','max'}); % Relative Features
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol)  =statsPerPat.pNames;
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol+1)  =num2cell(statsPerPat.numel);
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol+2)  =num2cell(statsPerPat.mean);
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol+3)  =num2cell(statsPerPat.median);
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol+4)  =num2cell(statsPerPat.std);
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol+5)  =num2cell(statsPerPat.min);
        m4Save(indRow:indRow+length(statsPerPat.pNames)-1,indCol+6)  =num2cell(statsPerPat.max);        
        indCol = size(m4Save,2)+2;
    end
    if (ispc)
        xlswrite([xlsFileName], m4Save, sheetName); % ONLY in Windows!
    end
    
    clear m4Save;
end