function script_createTableWithStimInfoAnesthesia(dirGralResults, pNames, posFixDir,whatToUseRespCh)
% Look for information in resp, PCI and variability files
% and create a large XLS table with all the info.
% dateStr = date;

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
regionForPercWithin = {'anterior','posterior','temporal'}; % MUST be exclusive  - 'thalCaud','unknown'look for percentage of responsive within region (at the resolution indicated here)

anatRegionType = 'StimCh'; %'nResp_StimCh';

%posFixDir = '_noSTIM'; %'_CCEPLOC'; 
titNameGRal = ['t0-600',posFixDir];
%whatToUseRespCh = 'PERTRIALnonSOZMEAN'; 
whatToUsePCI = 'PERTRIALnonSOZ'; 
varTimePeriod ='CCEP'; %'Baseline';% 
whichVariability= 'STD'; %'MAD'; %'2575RANGE'; 


%% Organize files
nPatients = numel(pNames);
%dirPooledResults = [dirGral, filesep, 'AnesthesiaAnalysis', filesep,num2str(nPatients),'pat_',strDate];

% Resp Channels
dirRespChPooled = [dirGralResults,filesep,'ConnectivityResults',filesep,titNameGRal,filesep,whatToUseRespCh,filesep,'nResp',anatRegionType];
respChFileName = [dirRespChPooled,filesep,'nRespChPerRegion_','nResp_',anatRegionType,num2str(nPatients),'pat','.mat'];

% PCI
dirPCIPooled = [dirGralResults,filesep,'PCIResults',filesep,whatToUsePCI,titNameGRal,filesep,'PCI',anatRegionType];
PCIFileName = [dirPCIPooled,filesep,'PCIPerRegion_','PCI ',anatRegionType,num2str(nPatients),'pat','.mat']; %PCIPerRegion_PCI StimCh20pat

% Variability
dirVariabilityPooled = [dirGralResults,filesep,'VariabilityRespAnyState',posFixDir,filesep,'poolRespEEG0MEAN',whichVariability,varTimePeriod,filesep,whichVariability,anatRegionType];
variabilityFileName = [dirVariabilityPooled,filesep,'VariabilityPerRegion_VarEEG0MEAN ',whichVariability,' ',varTimePeriod,' ',anatRegionType,num2str(nPatients),'pat','.mat'];

% Output
fileNameSummary = [dirGralResults,filesep,'summaryDetailsRelStimInfo_',anatRegionType,'_',num2str(nPatients),'pat_',date];

%% Load nResp Channels
stRespCh = load(respChFileName);
regionNamesResp = stRespCh.regionNames;
indRegion = find(strcmpi(regionNamesResp, 'all')); % Get info from ALL regions - then subdivideL
nRespPerState = stRespCh.nRespPerStatePerRegion(:,indRegion);
percRespPerState = stRespCh.percPerStatePerRegion(:,indRegion); 
stimSitesPerStateResp = stRespCh.stimSitesPerState;
anatStimRegionsResp = stRespCh.anatRegionsStimChPerState;
gralStimRegionsResp = stRespCh.gralRegionsStimChPerState; % it is a struct with the region that each channel belows to - not sure how to use it
percRespPerStateWithinRegion = stRespCh.percPerStateWithinRegion(:,indRegion); % To initialize size
percRespPerStateTotalRegion = stRespCh.percTOTPerStatePerRegion(:,indRegion); % To initialize size
relRespThisRegion = stRespCh.relativeNResp(:,indRegion); %

% add regional info
for iState=1:length(allStates)
    for iRegion=1:numel(regionNamesResp)
        isInRegionResp{iState}(iRegion,:) = cell2mat([gralStimRegionsResp{iState}.(regionNamesResp{iRegion})]);
        indInRegion = find(isInRegionResp{iState}(iRegion,:));
        % Perc Within and TOTAL should be from a exclusive region
        if any(strcmpi(regionForPercWithin, regionNamesResp{iRegion})) % is one of the regions to get within info from
            percRespPerStateWithinRegion{iState}(indInRegion) = stRespCh.percPerStateWithinRegion{iState,iRegion}(indInRegion);
            percRespPerStateTotalRegion{iState}(indInRegion) = stRespCh.percTOTPerStatePerRegion{iState,iRegion}(indInRegion);
        end
    end
end

%% Load PCI values
stPCI = load(PCIFileName);
regionNamesPCI = stPCI.regionNames;
indRegion = find(strcmpi(regionNamesPCI, 'all')); % Get info from ALL regions - then subdivideL
PCIPerStateThisRegion = stPCI.PCIPerStatePerRegion(:,indRegion);
stimSitesPerStatePCITemp = stPCI.stimSitesPerState;
anatStimRegionsPCI = stPCI.anatRegionsStimChPerState;
relPCIThisRegion = stPCI.relativePCI(:,indRegion);

% Remove duplicated stimchannels & invert channels
for iState=1:length(allStates)
    [stimSitesPerStatePCI{iState}, indUniqueStimCh] = unique(stimSitesPerStatePCITemp{iState},'stable');
    anatStimRegionsPCI{iState} = anatStimRegionsPCI{iState}(indUniqueStimCh);
    PCIPerStateThisRegion{iState} = PCIPerStateThisRegion{iState}(indUniqueStimCh);
end

%% Load Variability - Variability is per responsive channel - use mean/std per STIM ch  instead of each value
stVariability = load(variabilityFileName);
regionNamesVar = stVariability.regionNames;
indRegion = find(strcmpi(regionNamesVar, 'all')); % Get info from ALL regions - then subdivideL
pairComps = stVariability.pairComps;

%mean Variability per STIM channel
for iState=1:length(allStates)
    % [stimSitesPerStateVar{iState}, indStimSitesInFull, indStimSites] = unique(regexprep(stVariability.stimSitesPerState{iState},'-',''),'stable');
    [stimSitesPerStateVar{iState}, indStimSitesInFull, indStimSites] = unique(stVariability.stimSitesPerState{iState},'stable');
    anatRegionsVar{iState} = stVariability.anatRegionsStimChPerState{iState}(indStimSitesInFull);
    for iStimCh=1:length(stimSitesPerStateVar{iState})
        indStimCh = find(strcmpi(stimSitesPerStateVar{iState}{iStimCh}, stVariability.stimSitesPerStatePerRegion{iState,indRegion}));
        if ~isempty(indStimCh)
            [meanVal, q25, q75, stdVal, stdErrorVal,medianVal,coeffVar]= meanQuantiles(stVariability.variabilityPerStatePerRegion{iState,indRegion}(indStimCh), 2,0);
            meanVariabilityPerState{iState,1}(iStimCh) = meanVal;
            stdVariabilityPerState{iState,1}(iStimCh) = stdVal;
        end
    end
end

meanRelVariabilityPerState = meanVariabilityPerState;
stdRelVariabilityPerState=stdVariabilityPerState;

%% Save 1 excel sheet per state
xlsHeader = {'STIMChName','AnatRegion','nRecCh','PCI','nResp','%Resp','%RespWithin','%RespTOTAL','meanVar','stdVar'};
xlsHeader = [xlsHeader,' ',regionNamesResp]; % add region info

for iState=1:length(allStates)
    m4Save{1,1} = allStates{iState};
    m4Save{1,2} = regionForPercWithin;
    m4Save{1,3} = anatRegionType;
    m4Save{1,4} = nPatients;
    m4Save{2,1} = respChFileName;
    m4Save{2,3} = PCIFileName;
    m4Save(4,1:length(xlsHeader)) = xlsHeader;
    stimChResp = stimSitesPerStateResp{iState}; % e.g. name is LP_4
    stimChPCI = stimSitesPerStatePCI{iState}; % e.g. name is LP_4
    stimChVar = stimSitesPerStateVar{iState}; % e.g. name is LP_4
    % use Resp order 
    indRow = 5;
    for iCh=1:numel(stimChResp)
        indChPCI = find(strcmpi(stimChPCI,stimChResp{iCh}));
        indChVar = find(strcmpi(stimChVar,stimChResp{iCh}));
        if ~isempty(indChPCI)
            m4Save{indRow,1}  = stimChPCI{indChPCI}; %STIm ch
            m4Save{indRow,2}  = anatStimRegionsPCI{iState}{indChPCI}; % Anat region
            m4Save{indRow,3}  = nRespPerState{iState}(iCh)/ percRespPerState{iState}(iCh); % # Recording channels
            m4Save{indRow,4}  = PCIPerStateThisRegion{iState}(indChPCI); % PCI
        end
        m4Save{indRow,5}  = nRespPerState{iState}(iCh); % nResp
        m4Save{indRow,6}  = percRespPerState{iState}(iCh); % perResp
        m4Save{indRow,7}  = percRespPerStateWithinRegion{iState}(iCh); % per WITHIN region
        m4Save{indRow,8}  = percRespPerStateTotalRegion{iState}(iCh);   % per TOTAL region
        if ~isempty(indChVar)
            m4Save{indRow,9}  = meanVariabilityPerState{iState}(indChVar); % mean Var per STIM channel
            m4Save{indRow,10}  = stdVariabilityPerState{iState}(indChVar);   %  std of Var per STIM channel
        end
        % Add region info - leave 1 col empty
        m4Save(indRow,12:11+numel(regionNamesResp))  = num2cell(isInRegionResp{iState}(:,iCh)'); % whether is in each of the regions
        
        indRow = indRow+1;
    end
    % save in xls
    xlsSheet = allStates{iState};
    save([fileNameSummary,'.mat'], 'allStates','m4Save', 'regionForPercWithin','xlsSheet','xlsHeader',...
        'stimSitesPerStatePCI','anatStimRegionsPCI','PCIPerStateThisRegion',...
        'stimSitesPerStateResp','anatStimRegionsResp','gralStimRegionsResp','isInRegionResp','nRespPerState','percRespPerState','percRespPerStateWithinRegion','percRespPerStateTotalRegion',...
        'stimSitesPerStateVar','anatRegionsVar','meanVariabilityPerState','stdVariabilityPerState');
    if (ispc)
        xlswrite([fileNameSummary,'.xlsx'], m4Save, xlsSheet); % ONLY in Windows!
    end
    clear m4Save;
    
end

%% Save also ONLY common pairs
pairComps = stRespCh.pairComps;% [1,3;1,2;3,4];

xlsHeader = {'STIMChName','STIMChName','AnatRegion','nRecCh','relPCI','relNResp','rel%Resp','rel%RespWithin','rel%RespTOTAL','meanRelVar','stdRelVar',...
                                                'PCI1','nResp1','%Resp1','%RespWithin1','%RespTOTAL1','meanVar1','stdVar1',...
                                                'PCI2','nResp2','%Resp2','%RespWithin2','%RespTOTAL2','meanVar2','stdVar2',...
                                                };
xlsHeader = [xlsHeader,'STIMChCommon',' ',regionNamesResp]; % add region info

for iComp=1:size(pairComps,1)
    [indInResp1, indInResp2, commonChResp] = strmatchAll(stimSitesPerStateResp{pairComps(iComp,1)}, stimSitesPerStateResp{pairComps(iComp,2)});
    [indInPCI1, indInPCI2, commonChPCI] = strmatchAll(stimSitesPerStatePCI{pairComps(iComp,1)}, stimSitesPerStatePCI{pairComps(iComp,2)});
    [indInVar1, indInVar2, commonChVar] = strmatchAll(stimSitesPerStateVar{pairComps(iComp,1)}, stimSitesPerStateVar{pairComps(iComp,2)});

    m4Save{1,1} = strcat(allStates{pairComps(iComp,:)});
    m4Save{1,2} = regionForPercWithin;
    m4Save{1,3} = anatRegionType;
    m4Save{1,4} = nPatients;
    m4Save{2,1} = respChFileName;
    m4Save{2,3} = PCIFileName;
    m4Save{3,4} = allStates{pairComps(iComp,1)};      m4Save{3,9} = allStates{pairComps(iComp,2)};
    m4Save(4,1:length(xlsHeader)) = xlsHeader;
    stimChResp = commonChResp; % e.g. name is LP_4
    stimChPCI = commonChPCI; % e.g. name is LP_4
    stimChVar = commonChVar;% e.g. name is LP_4-> use this in XLS
    % use Resp order 
    indRow = 5;
    for iCh=1:numel(stimChResp)
        indChPCI = find(strcmpi(stimChPCI,stimChResp{iCh}));
        indChVar = find(strcmpi(stimChVar,stimChResp{iCh}));
        if ~isempty(indChPCI)
            m4Save{indRow,1}  = stimChPCI{indChPCI}; %STIm ch
            m4Save{indRow,2}  = stimChResp{iCh}; %STIm ch
            m4Save{indRow,3}  = anatStimRegionsPCI{pairComps(iComp,1)}{indInPCI1(indChPCI)}; % Anat region
            m4Save{indRow,4}  = nRespPerState{pairComps(iComp,1)}(indInResp1(iCh))/ percRespPerState{pairComps(iComp,1)}(indInResp1(iCh)); % # Recording channels
            indCol=5; 
 % Relative values State 1-2
            m4Save{indRow,indCol}  = stPCI.relativePCI{iComp,indRegion}(indChPCI); % PCI
            m4Save{indRow,indCol+1}  = stRespCh.relativeNResp{iComp,indRegion}(iCh); % nResp
            m4Save{indRow,indCol+2}  = stRespCh.relativePercResp{iComp,indRegion}(iCh); % perResp
        %    m4Save{indRow,indCol+3}  = stRespCh.relativePercWithinResp{iComp,indRegion}(iCh); % per WITHIN region
         %   m4Save{indRow,indCol+4}  = stRespCh.relativePercTOTResp{iComp,indRegion}(iCh);   % per TOTAL region
            if ~isempty(indChVar)
                m4Save{indRow,indCol+5}  = (meanVariabilityPerState{pairComps(iComp,1)}(indInVar1(indChVar)) - meanVariabilityPerState{pairComps(iComp,2)}(indInVar2(indChVar))) /...
                                           (meanVariabilityPerState{pairComps(iComp,1)}(indInVar1(indChVar)) + meanVariabilityPerState{pairComps(iComp,2)}(indInVar2(indChVar))) ; %  Relative mean Variability
                %m4Save{indRow,indCol+6}  = stdRelVariabilityPerState{pairComps(iComp,indStateInComp)}(indChVar);   % std of Variability
            end
            
 % State 1
             indCol=12;
             indStateInComp=1;
             m4Save{indRow,indCol}  = PCIPerStateThisRegion{pairComps(iComp,indStateInComp)}(indInPCI1(indChPCI)); % PCI
             m4Save{indRow,indCol+1}  = nRespPerState{pairComps(iComp,indStateInComp)}(indInResp1(iCh)); % nResp
             m4Save{indRow,indCol+2}  = percRespPerState{pairComps(iComp,indStateInComp)}(indInResp1(iCh)); % perResp
             m4Save{indRow,indCol+3}  = percRespPerStateWithinRegion{pairComps(iComp,indStateInComp)}(indInResp1(iCh)); % per WITHIN region
             m4Save{indRow,indCol+4}  = percRespPerStateTotalRegion{pairComps(iComp,indStateInComp)}(indInResp1(iCh));   % per TOTAL region
             if ~isempty(indChVar)
                 m4Save{indRow,indCol+5}  = meanVariabilityPerState{pairComps(iComp,indStateInComp)}(indInVar1(indChVar)); % per WITHIN region
                 m4Save{indRow,indCol+6}  = stdVariabilityPerState{pairComps(iComp,indStateInComp)}(indInVar1(indChVar));   % per TOTAL region
             end
% State 2
            indCol=19;
            indStateInComp=2;
            m4Save{indRow,indCol}  = PCIPerStateThisRegion{pairComps(iComp,indStateInComp)}(indInPCI2(indChPCI)); % PCI
            m4Save{indRow,indCol+1}  = nRespPerState{pairComps(iComp,indStateInComp)}(indInResp2(iCh)); % nResp
            m4Save{indRow,indCol+2}  = percRespPerState{pairComps(iComp,indStateInComp)}(indInResp2(iCh)); % perResp
            m4Save{indRow,indCol+3}  = percRespPerStateWithinRegion{pairComps(iComp,indStateInComp)}(indInResp2(iCh)); % per WITHIN region
            m4Save{indRow,indCol+4}  = percRespPerStateTotalRegion{pairComps(iComp,indStateInComp)}(indInResp2(iCh));   % per TOTAL region
        if ~isempty(indChVar)
            m4Save{indRow,indCol+5}  = meanVariabilityPerState{pairComps(iComp,indStateInComp)}(indInVar2(indChVar)); % mean Variability
            m4Save{indRow,indCol+6}  = stdVariabilityPerState{pairComps(iComp,indStateInComp)}(indInVar2(indChVar));   % std of Variability
        end

            m4Save{indRow,indCol+7}  = stRespCh.stimChPerCompRegion{iComp,indRegion}{iCh};   % To double check that same channel

            % Add region info - leave 1 col empty
            indCol = 27;
            m4Save(indRow,indCol+1:indCol+numel(regionNamesResp))  = num2cell(isInRegionResp{pairComps(iComp,1)}(:,indInResp1(iCh))'); % whether is in each of the regions

            indRow = indRow+1;
        end
    end
    % save in xls
    xlsSheet = strcat(allStates{pairComps(iComp,:)});
    save([fileNameSummary,'.mat'], 'allStates','m4Save','pairComps','iComp', 'regionForPercWithin','xlsSheet','xlsHeader',...
        'stimSitesPerStatePCI','anatStimRegionsPCI','PCIPerStateThisRegion',...
        'stimSitesPerStateResp','anatStimRegionsResp','gralStimRegionsResp','isInRegionResp','nRespPerState','percRespPerState','percRespPerStateWithinRegion','percRespPerStateTotalRegion',...
        'stimSitesPerStateVar','anatRegionsVar','meanRelVariabilityPerState','stdRelVariabilityPerState');
    if (ispc)
        xlswrite([fileNameSummary,'.xlsx'], m4Save, xlsSheet); % ONLY in Windows!
    end
    clear m4Save;
    
end
