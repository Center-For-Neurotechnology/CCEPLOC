function [dirCircroPlotsXlsPerPatient] = preparePooledRespChDataForCircroPlots(lstResponsiveChannelMATfiles, dirDataXls, titNameForFile,  maxValues)
% save Responsive data in tables to then generate circro plots for ALL
% PATIENTS ina selected region
% Also useful to get polled information (e.g. total number of
% recording or stim channels)

%% Config
if ~exist('dirDataXls','var'), dirDataXls=fileparts(lstResponsiveChannelMATfiles{1}); end
if ~exist('titNameForFile','var'), titNameForFile=[]; end
IPSIonLEFT =1; % REVERSE RIGHT STIM TO HAVE ALL ON LEFT - Not Implemented!

nPrimes = primes(100); % 25 prime numbers

if ~exist('maxValues','var')
    maxValues.maxP2PAmp = 10; % assign to STIM channel - to enforce same scale in all plots 
    maxValues.maxLatency = 0.2; % assign to STIM channel - to enforce same scale in all plots
end

% The order of this cell indicates the order of the plot
regionNames = {'PFC','OF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};
gralRegionNames = {'frontal','ACC','central','tempoinsula','posterior','subcortical','thalCaud','WM'};

%% DIrectories and Files
% dirCircroPlotsXlsPerPatient = [dirDataXls, filesep, pName];
if ~isfolder(dirDataXls), mkdir(dirDataXls); end
xlsFileNameGral = [dirDataXls, filesep, titNameForFile, '_'];
    

%% load ALL Data
chInfoRepAll=[];
pNamesAll=[];
chNamesPNames=[];
for iFile = 1:numel(lstResponsiveChannelMATfiles)
    stRespData = load(lstResponsiveChannelMATfiles{iFile});
    pName = stRespData.channInfo.pName;
    thisState = stRespData.thisState;
    
    %% Organize data
   % chInfoRep = stRespData.channInfoRespCh_AveragePerTrial;
    chInfoRep = [stRespData.channInfoRespCh{:}];
    if ~isempty(chInfoRep)
        chInfoRepAll = [chInfoRepAll, chInfoRep];
        pNamesAll = [pNamesAll, repmat({pName},1,length(chInfoRep))];
        chNamesPNames = [chNamesPNames, strcat([chInfoRep(:).chNamesSelected],'_',pName)];
    else
        disp(['No data for ',pName,' ',thisState]);
        % return;
    end
end

% Add patient name to channel name
stimSiteNames = [chInfoRepAll.stimSiteNames];
if isempty(strfind(stimSiteNames{1,1},'-'))
    stimSiteNames = strcat(stimSiteNames(2,:),'-',stimSiteNames(1,:));
end
stimSitePatNames = strcat(stimSiteNames,'_',pNamesAll);

anatRegionsStimCh = [chInfoRepAll.anatRegionsStimCh];
nStim = length(stimSitePatNames);

allChPatNames = unique([stimSitePatNames, chNamesPNames]);
nAllCh =length(allChPatNames);

% Find for each channel where in each stimCh it is
nRecChannels=zeros(1,nStim);
indInAll=cell(1,nStim);
indPerStimCh=cell(1,nStim);
chNamesPerStim=cell(1,nStim);
for iStimCh=1:nStim
    chNamesWithStim = [stimSitePatNames(iStimCh), strcat(chInfoRepAll(iStimCh).chNamesSelected,'_',pNamesAll{iStimCh})];
    [indInAll{iStimCh}, indPerStimCh{iStimCh}, chNamesPerStim{iStimCh}] = strmatchAll(allChPatNames, chNamesWithStim);  % Assumes all the same
   % anatRegionPerStimCh = [anatRegionsStimCh(iStimCh), chInfoRepAll(iStimCh).anatRegionsPerCh]; % this is only the TARGTE regions
    nRecChannels(iStimCh) = length(chNamesPerStim{iStimCh});
end
% Add Stim channels if they are not in the file



%% Get info per Stim Channel
% Add stim channels to list of channels (as first channel)
% organize with previous order
isChResp = cell(1,nStim); %each:zeros(nRecChannels +1, nStim); % +1 to add stim channel
ampRespCh = cell(1,nStim); %zeros(nRecChannels +1, nStim);
ampOnlyRespCh = cell(1,nStim); %zeros(nRecChannels +1, nStim);
latencyOnlyRespCh = cell(1,nStim); %zeros(nRecChannels +1, nStim);
distRecToStimCh = cell(1,nStim); %zeros(nRecChannels +1, nStim);
anatRegions = cell(1,nStim);
indRegionPerCh = cell(1,nStim);
for iStimCh=1:nStim
    anatRegionPerStimCh = [anatRegionsStimCh(iStimCh), chInfoRepAll(iStimCh).anatRegionsPerCh];
    anatRegions{iStimCh} = anatRegionPerStimCh(indPerStimCh{iStimCh});
    isChRespTemp = [1, chInfoRepAll(iStimCh).isChResponsive];  % 1 is added to account for stim channel
    isChResp{iStimCh} = isChRespTemp(indPerStimCh{iStimCh});
    ampRespChTemp = [maxValues.maxP2PAmp, chInfoRepAll(iStimCh).avPeakToPeakAmpPerCh];  %maxP2PAmp is added to account for stim channel
    ampRespCh{iStimCh} = ampRespChTemp(indPerStimCh{iStimCh});
    ampOnlyRespCh{iStimCh} = ampRespCh{iStimCh} .* isChResp{iStimCh}; % only keep amplitude for responsive channels
    latencyTemp =  zeros(1,nRecChannels(iStimCh)); 
    latencyTemp(find(isChRespTemp)) = [maxValues.maxLatency, cellfun(@double, chInfoRepAll(iStimCh).locResponsiveCh)];  % maxLatency is added to account for stim channel
    latencyOnlyRespCh{iStimCh} = latencyTemp(indPerStimCh{iStimCh});
    % REMOVED UNIQUE - it changes ORDER
     %uRegionLabels = unique(chInfoRepAll(iStimCh).cfgInfoPlot.targetLabels);
     regionLabels = chInfoRepAll(iStimCh).cfgInfoPlot.targetLabels;
     for iCh=1:length(anatRegions{iStimCh})
        indRegionPerCh{iStimCh}(iCh) = find(strcmpi(anatRegions{iStimCh}{iCh},regionLabels)); 
     end
    % Distance to Stim
    RASCoordStimCh = chInfoRepAll(iStimCh).RASCoordPerChStimCh;
    RASCoordPerCh = [RASCoordStimCh; chInfoRepAll(iStimCh).RASCoordPerCh];
    distRecToStimChTemp = RASdistanceToStim(RASCoordPerCh, RASCoordStimCh);
    distRecToStimCh{iStimCh} = distRecToStimChTemp(indPerStimCh{iStimCh});
end

%% Get also Lobular and General region
lobeRegions = cell(1,nStim);
gralRegions = cell(1,nStim);
for iStimCh=1:nStim
    [gralRegionPerCh, stChannelPerRegion, labelPerRegion] = getGralRegionPerChannel(anatRegions{iStimCh});
    lobeRegions{iStimCh} = cell(1,length(gralRegionPerCh));
    gralRegions{iStimCh} = cell(1,length(gralRegionPerCh));
    % Lobular division
    for iRegion=1:length(regionNames)
        [indChWithinStimRegion] = findChannelsWithinRegion(stChannelPerRegion, regionNames{iRegion});
        indChWithinStimRegion = indChWithinStimRegion{1};
        lobeRegions{iStimCh}(indChWithinStimRegion) = regionNames(iRegion);
    end
    %repeat for general regions
    for iRegion=1:length(gralRegionNames)
        [indChWithinStimRegion] = findChannelsWithinRegion(stChannelPerRegion, gralRegionNames{iRegion});
        indChWithinStimRegion = indChWithinStimRegion{1};
        gralRegions{iStimCh}(indChWithinStimRegion) = gralRegionNames(iRegion);
    end    
end

%% Get Also lobular regions for stim channels
[gralSTIMRegionPerCh, stSTIMChannelPerRegion, labelPerRegion] = getGralRegionPerChannel(anatRegionsStimCh);
lobeStimRegions = cell(1,length(gralSTIMRegionPerCh));
gralStimRegions = cell(1,length(gralSTIMRegionPerCh));
% Lobular division
for iRegion=1:length(regionNames)
    [indChWithinStimRegion] = findChannelsWithinRegion(stSTIMChannelPerRegion, regionNames{iRegion});
    indChWithinStimRegion = indChWithinStimRegion{1};
    lobeStimRegions(indChWithinStimRegion) = regionNames(iRegion);
end
%repeat for general regions
for iRegion=1:length(gralRegionNames)
    [indChWithinStimRegion] = findChannelsWithinRegion(stSTIMChannelPerRegion, gralRegionNames{iRegion});
    indChWithinStimRegion = indChWithinStimRegion{1};
    gralStimRegions(indChWithinStimRegion) = gralRegionNames(iRegion);
end
unStimLobeRegions = unique(lobeStimRegions);
nStimLobes = length(unStimLobeRegions);

%% Put together the channels and order alphabetical and per LOBE region
indOrderedLeftInOriginal = cell(1,nStimLobes);
indOrderedRightInOriginal = cell(1,nStimLobes);
nRowsPerStimRegion = cell(1,nStimLobes);
for iRegion=1:nStimLobes
    pooledLobeRegions=[];
    chNamesPerStimRegion=[];
    for iStimCh=1:nStim
        % Pool all stim per region together
        if strcmp(lobeStimRegions{iStimCh}, unStimLobeRegions{iRegion})
            pooledLobeRegions = [pooledLobeRegions, lobeRegions{iStimCh}];
            chNamesPerStimRegion = [chNamesPerStimRegion,chNamesPerStim{iStimCh}];
        end
    end
    % Then Order by region within rec - with orer as in targetRegions
    %    [sortedAnatRegions, indRowRegion] = sortAnatPerGralRegions(anatRegions{iStimCh}, regionLabels);
    [sortedAnatRegions, indRowRegion] = sortAnatPerGralRegions(pooledLobeRegions, regionNames);

    % Separate Left and Right as 2 columns - Assumes we can separate by L R in first letter of name
    indLeftCh = find(strncmp(chNamesPerStimRegion(indRowRegion),'L',1));
    indRightCh = find(strncmp(chNamesPerStimRegion(indRowRegion),'R',1));
    indOrderedLeftInOriginal{iRegion} = indRowRegion(indLeftCh);
    indOrderedRightInOriginal{iRegion} = indRowRegion(indRightCh);
    nRowsPerStimRegion{iRegion} = max(length(indLeftCh),length(indRightCh));
end

%% Find colors that correspond to each region


%% Create xls tables per Stim in xls - PER LOBE STIM region
% First column is Left channels / second column is Right channels 
% Plot Pooled per region data
posFix = '_perLobeStimCh.xlsx';
varNames = {'chNamesPerStim', 'gralRegions','lobeRegions', 'anatRegions', 'isChResp', 'ampRespCh','ampOnlyRespCh', 'distRecToStimCh','indRegionPerCh','latencyOnlyRespCh','indStimCh'};

% Save 2 column (LEFT/RIGHT) excels 
for iVar=1:length(varNames)
    dataToSaveAllStim = eval(varNames{iVar});
    for iRegion=1:nStimLobes
        dataToSave=[];
        indStimChPerRegion=[];
        indDiffStimCh=[];
        for iStimCh=1:nStim     % Pool all stim per region together
            if strcmp(lobeStimRegions{iStimCh}, unStimLobeRegions{iRegion})
                dataToSave = [dataToSave,dataToSaveAllStim{iStimCh}];
                indStimChPerRegion = [indStimChPerRegion, find(strcmp(chNamesPerStim{iStimCh}, stimSitePatNames{iStimCh}))];
                indDiffStimCh = [indDiffStimCh,length(dataToSaveAllStim{iStimCh})];
            end
        end
        indDiffStimCh = [1 cumsum(indDiffStimCh)];
        dataL = dataToSave(indOrderedLeftInOriginal{iRegion});
        dataR = dataToSave(indOrderedRightInOriginal{iRegion});
        lLeft = length(dataL);
        lRight = length(dataR);
        nCols=2;
        nRows = max(lLeft,lRight);
        % Save data as 2 col xls
        if iscell(dataToSave)
            m4Save=cell(nRows, nCols);
            m4Save{1,1}=' '; m4Save{1,2}=' '; % BAD hack to prevent Cicro from crashing for patients with unilateral data
        else
            m4Save=zeros(nRows, nCols);
        end
        m4Save(1:lLeft,1) = dataL;
        m4Save(1:lRight,2) = dataR;
        xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', varNames{iVar}, posFix], m4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        clear m4Save;
        
        % RIZ: FALTA!!!!!!
        % Create matrices for edges and save
        if isnumeric(dataToSaveAllStim{1})
            indOrderLR = [indOrderedLeftInOriginal{iRegion}, indOrderedRightInOriginal{iRegion}]; % order as Left and then Right to keep order of the tables
            mEdges4Save = nan(length(indOrderLR),length(indOrderLR)); %zeros(nCols*nRows, nCols*nRows);
            for iCh=1:length(indDiffStimCh)-1
                indPerCh = [indDiffStimCh(iCh):indDiffStimCh(iCh+1)];
                mEdges4Save(indPerCh,indStimChPerRegion(iCh)) = dataToSave(indOrderLR(indPerCh)); % ASSUMES that stim channel is always the FIRST one 
                mEdges4Save(indStimChPerRegion(iCh),indPerCh) = dataToSave(indOrderLR(indPerCh));
            end
            %remove lower triangle and save
             mEdges4Save = triu(mEdges4Save);
            xlswrite([xlsFileNameGral, 'mEdges_',unStimLobeRegions{iRegion},'_', varNames{iVar}, posFix], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            % max out everything above maxVal
            if any(mEdges4Save(:)>maxValues.maxP2PAmp)
                mEdges4Save(mEdges4Save>maxValues.maxP2PAmp)=maxValues.maxP2PAmp;
                xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_','mEdges_', varNames{iVar},'_Max',num2str(maxValues.maxP2PAmp),'_', posFix], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            end
        end
    end
end





