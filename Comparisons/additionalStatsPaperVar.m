
function additionalStatsPaperVar(dirGralResults, regionName, whichVariability)

varTimePeriods = {'CCEP', 'Baseline'};% 
%whichVariability= 'STD';%'TRIALMAD'; %'MAD'; %'2575RANGE'; % 'VARERR'; 
anatRegionType = 'OnlyRespCh';
%considerChInElectrodeShaft = 
useParam = 2; %permutation test
%regionName = {'anterior', 'posterior', 'temporal','frontal'};
nPatients= 20;
considerChInElectrodeShaft=0;
posFixDir = '_Neuron2023'; %'_LP_CCEP'; %'_noSTIM'; %'_LP_CCEP2'; %'_raw'; %'_ALPHA';

dirImages = [dirGralResults, filesep, 'plotsLOCpaper',posFixDir,filesep,'images',whichVariability];

% PCIFileName = [dirGralResults, filesep, 'PCIResults', filesep, 'PERTRIAL_Clean20nonSOZt0-600',posFixDir,filesep,'PCIStimCh',filesep,'PCIPerRegion_PCI StimCh',num2str(nPatients),'pat.mat'];
%  
% respChFileName = [dirGralResults, filesep, 'ConnectivityResults', filesep, 't0-600',posFixDir,filesep,'PERTRIALnonSOZ_Clean20',filesep,'nResp min5NoSOZStimCh',filesep,'nRespChPerRegion_nResp min5NoSOZ_StimCh',num2str(nPatients),'pat.mat'];
 
varGralDirName = [dirGralResults, filesep, 'VariabilityRespAnyState', posFixDir, filesep,'poolRespEEG0MEAN',whichVariability];
variabilityFileName1 = [varGralDirName,varTimePeriods{1},filesep,whichVariability,anatRegionType,filesep,'VariabilityPerRegion_VarEEG0MEAN ',whichVariability,' ',varTimePeriods{1},' ',anatRegionType,num2str(nPatients),'pat.mat'];
variabilityFileName2 = [varGralDirName,varTimePeriods{1},filesep,whichVariability,anatRegionType,filesep,'VariabilityPerRegion_VarEEG0MEAN ',whichVariability,' ',varTimePeriods{2},' ',anatRegionType,num2str(nPatients),'pat.mat'];
 
if ~isdir(dirImages), mkdir(dirImages);end


%% Load Variability
stVariability1 = load(variabilityFileName1);
regionNamesVar = stVariability1.regionNames;
allStates = stVariability1.cfgStats.allStates;
nStates = numel(allStates);
indRegion = strcmpi(regionName, regionNamesVar);

stimSitesPerState = stVariability1.stimSitesPerStatePerRegion(:,indRegion);
varPerState1 = stVariability1.variabilityPerStatePerRegion(:,indRegion);
recChannelsPerState = stVariability1.chNamesPNamesPerState;
anatRegionsPerState = stVariability1.anatRegionsPerChPerState;
relVariability1 = stVariability1.relativeVariability(:,indRegion);
cfgStats = stVariability1.cfgStats;

%% Load Variability time 2
stVariability2 = load(variabilityFileName2);
regionNamesVar = stVariability2.regionNames;
allStates = stVariability2.cfgStats.allStates;
indRegion = strcmpi(regionName, regionNamesVar);

stimSitesPerStatePerRegion2 = stVariability2.stimSitesPerStatePerRegion(:,indRegion);
varPerState2 = stVariability2.variabilityPerStatePerRegion(:,indRegion);
relVariability2 = stVariability2.relativeVariability(:,indRegion);

%% remove channels in shaft
% for iState=1:nStates
%     if strcmpi(anatRegionType, 'StimCh') % stim in region recordings everywhere - look for region of  stim channel
%         indChInRegion = find([stVariability1.gralRegionsStimChPerState{iState}.(regionName){:}]); % STIM in region / to change to Rec in region use gralRegionsPerChPerState
%     else % recording in region - look for region of recording channels
%         indChInRegion = find([stVariability1.gralRegionsPerChPerState{iState}.(regionName){:}]); % STIM in region / to change to Rec in region use gralRegionsPerChPerState
%     end
%     RASCoordStimChPerState{iState} = stVariability1.RASCoordStimChPerState{iState}(indChInRegion,:);
%     RASCoordRecChPerState{iState} = stVariability1.RASCoordPerChPerState{iState}(indChInRegion,:);
%     % consider channels in stim shaft electrode?
%     if ~considerChInElectrodeShaft
%         %remove channels in electrode shaft from this analysis
%         isRecChInStimShaft = find(stVariability1.rechInStimShaftPerState{iState}(indChInRegion));
%         stimSitesPerState{iState}(isRecChInStimShaft)=[];
%         varPerState1{iState}(isRecChInStimShaft)=[];
%         varPerState2{iState}(isRecChInStimShaft)=[];
%         RASCoordStimChPerState{iState}(isRecChInStimShaft,:)=[];
%         RASCoordRecChPerState{iState}(isRecChInStimShaft,:)=[];
%     end
% end

%% Compare CCEP and Baseline Variability
xlsFileName = [dirGralResults, filesep, 'ComparisonCCEPBaselineVarMAD_',regionName,'.xlsx'];
for iState=1:nStates
    tit =['CCEPBaseVar ',regionName,' ',allStates{iState}];
    legLabel = varTimePeriods;
    sheetName = tit;
    
    [pairedTest, medianVal1, medianVal2, testName] = computePairedTtestSaveInXls(varPerState1{iState}, varPerState2{iState}, tit,legLabel,xlsFileName,sheetName,dirImages,useParam);
    disp([regionName,' ',testName,': ', sheetName, ' ',allStates{iState},' between ',[legLabel{:}], ' ',  ' - pVal= ', num2str(pairedTest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),...
        ' N= ',num2str(length(varPerState1{iState}))])

end

%% Save recording channels with value, name and region
xlsFileName = [dirGralResults, filesep, 'ChannelNamesVariability_',regionName,'.xlsx'];
colHeaders = {'RecChannnel', 'StimChannel','pName', 'AnatRegion','CCEPVariability','BaselineeVariability'};
nCols = length(colHeaders);

for iState=1:nStates
    tit =['CCEPVar ',regionName,' ',allStates{iState}];
    legLabel = varTimePeriods;
    % divide in rec - stim -pName
%    splitRecStimPName = split(recChannelsPerState{iState},{' ','_'});
%    recChannels = regexprep(squeeze(splitRecStimPName(:,:,1)),'rec','');
 %   stimChannels = regexprep(squeeze(splitRecStimPName(:,:,2)),'st','');
 %   pNames = squeeze(splitRecStimPName(:,:,3));
    splitRecStimPName = split(recChannelsPerState{iState},{' '}); % separate rec from stim_pName
    recChannels = regexprep(squeeze(splitRecStimPName(:,:,1)),{'rec','_'},''); % remove also the _
     
    [splitStimPName, marker] = split(stimSitesPerState{iState},{'p','sub'});  % SPECIFIC to participant ID
    stimChannels{iState} = regexprep(squeeze(splitStimPName(:,:,1)),{'st','_'},'');
    pNames{iState} = strcat(marker, squeeze(splitStimPName(:,:,2)));
    
    sheetName = tit;
    m4Save{1,1} = cfgStats.anatRegionFor;
    m4Save{1,2} = tit;
    m4Save{2,1} = variabilityFileName1;

    m4Save(3,1:nCols) = colHeaders;
    m4Save(4:length(varPerState1{iState})+3, 1) = recChannels;
    m4Save(4:length(varPerState1{iState})+3, 2) = stimChannels{iState};
    m4Save(4:length(varPerState1{iState})+3, 3) = pNames{iState};
    m4Save(4:length(varPerState1{iState})+3, 4) = anatRegionsPerState{iState};
    m4Save(4:length(varPerState1{iState})+3, 5) = num2cell(varPerState1{iState});
    m4Save(4:length(varPerState1{iState})+3, 6) = num2cell(varPerState2{iState});

%     [pairedTest, medianVal1, medianVal2, testName] = computePairedTtestSaveInXls(varPerState1{iState}, varPerState2{iState}, tit,legLabel,xlsFileName,sheetName,dirImages,useParam);
%     disp([regionName,' ',testName,': ', sheetName, ' ',allStates{iState},' between ',[legLabel{:}], ' ',  ' - pVal= ', num2str(pairedTest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2),...
%         ' N= ',num2str(length(varPerState1{iState}))])
    xlswrite([xlsFileName], m4Save, sheetName);
    clear m4Save;
end


%% Save also ONLY common pairs
pairComps = stVariability1.pairComps;% [1,3;1,2;3,4];

xlsHeader = {'RecChName','STIMChName','pName','AnatRegion','RelCCEPVar','RelBaselineVar',...
                                                'CCEPVar1','BaselineVar1','CCEPVar2','BaselineVar2'};
xlsHeader = [xlsHeader,'STIMChCommon',' ',regionNamesVar]; % add region info

for iComp=1:size(pairComps,1)
    tit =['RelCCEPVar ',allStates{pairComps(iComp,:)}]; %regionName,' ',
    splitRecStimPName = split(stVariability1.commonChPerCompRegion{iComp},{' '});
%    splitRecStimPName = split(recChannelsPerState{iState},{' '}); % separate rec from stim_pName
    recChannels = regexprep(squeeze(splitRecStimPName(:,:,1)),{'rec','_'},''); % remove also the _
     
    [indRelInVar1, indRelInVarState, commonRelChVar] = strmatchAll(stVariability1.commonChPerCompRegion{iComp}, recChannelsPerState{pairComps(iComp,1)});
    [indInVar1, indInVar2, commonChVar] = strmatchAll( recChannelsPerState{pairComps(iComp,1)}, recChannelsPerState{pairComps(iComp,2)});

    sheetName = tit;
    
    m4Save{1,1} = cfgStats.anatRegionFor;
    m4Save{1,2} = tit;
    m4Save{2,1} = variabilityFileName1;

    m4Save{2,7} = allStates{pairComps(iComp,1)};      m4Save{2,9} = allStates{pairComps(iComp,2)};
    m4Save(3,1:length(xlsHeader)) = xlsHeader;

    indRow = 4;
    for iCh=1:numel(recChannels)
            m4Save{indRow,1}  = recChannels{iCh}; %R ch
            m4Save{indRow,2}  = stimChannels{pairComps(iComp,1)}{indRelInVarState(iCh)}; %STIm ch
            m4Save{indRow,3}  = pNames{pairComps(iComp,1)}{indRelInVarState(iCh)}; %pNames ch
            m4Save{indRow,4}  = anatRegionsPerState{pairComps(iComp,1)}{indRelInVarState(iCh)}; % Anat region
            indCol=5; 
 % Relative values State 1-2
            m4Save{indRow,indCol}  = relVariability1{iComp}(iCh); % Relative Variability CCEP
            m4Save{indRow,indCol+1}  = relVariability2{iComp}(iCh); % Relative Variability Baseline
          
 % State 1
             indCol=7;
             indStateInComp=1;
             m4Save{indRow,indCol}  = varPerState1{pairComps(iComp,indStateInComp)}(indInVar1(iCh)); % Variability CCEP
             m4Save{indRow,indCol+1}  = varPerState2{pairComps(iComp,indStateInComp)}(indInVar1(iCh)); % Variability Baseline
 % State 2
            indCol=9;
            indStateInComp=2;
             m4Save{indRow,indCol}  = varPerState1{pairComps(iComp,indStateInComp)}(indInVar2(iCh)); % Variability CCEP
             m4Save{indRow,indCol+1}  = varPerState2{pairComps(iComp,indStateInComp)}(indInVar2(iCh)); % Variability Baseline

      %      m4Save{indRow,indCol+7}  = stRespCh.stimChPerCompRegion{iComp,indRegion}{iCh};   % To double check that same channel

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