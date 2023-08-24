function [dirCircroPlotsXlsPerPatient] = prepareRespChDataForCircroPlots(lstResponsiveChannelMATfile, dirDataXls, titNameForFile,  maxValues)
% save Responsive data in tables to then generate circro plots

%% Config
if ~exist('dirDataXls','var'), dirDataXls=fileparts(lstResponsiveChannelMATfile); end
if ~exist('titNameForFile','var'), titNameForFile=[]; end

nPrimes = primes(100); % 25 prime numbers

if ~exist('maxValues','var')
    maxValues.maxP2PAmp = 20; % assign to STIM channel - to enforce same scale in all plots 
    maxValues.maxLatency = 0.35; % assign to STIM channel - to enforce same scale in all plots
end

% The order of this cell indicates the order of the plot 
%regionNames = {'PFC','OF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};
regionNames = {'dlPFC','vlPFC','dmPFC','lOF','mOF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'}; %'PFC','OF',
gralRegionNames = {'frontal','ACC','central','tempoinsula','posterior','subcortical','thalCaud','WM'};

%% load Data
stRespData = load(lstResponsiveChannelMATfile);

pName = stRespData.channInfo.pName;
thisState = stRespData.thisState;

%% DIrectories and Files
dirCircroPlotsXlsPerPatient = [dirDataXls, filesep, pName];
if ~isdir(dirCircroPlotsXlsPerPatient), mkdir(dirCircroPlotsXlsPerPatient); end
xlsFileNameGral = [dirCircroPlotsXlsPerPatient, filesep, titNameForFile, pName,'_',thisState,'_'];

dirCircroPlotsMATPerPatient = [dirDataXls, filesep,'MATFiles', filesep, pName];
if ~isdir(dirCircroPlotsMATPerPatient), mkdir(dirCircroPlotsMATPerPatient); end
matFileNameGral = [dirCircroPlotsMATPerPatient,filesep,titNameForFile, pName,'_',thisState,'_'];

%% Organize data
% chInfoRep = stRespData.channInfoRespCh_AveragePerTrial;
chInfoRep = [stRespData.channInfoRespCh{:}];
if isempty(chInfoRep)
    disp(['No data in',lstResponsiveChannelMATfile]);
    return;
end

stimSiteNames = [chInfoRep.stimSiteNames];
if isempty(strfind(stimSiteNames{1,1},'-'))
    stimSiteNames = strcat(stimSiteNames(2,:),'-',stimSiteNames(1,:));
end
anatRegionsStimCh = [chInfoRep.anatRegionsStimCh];
nStim = length(stimSiteNames);

allChNames = unique([stimSiteNames,chInfoRep(:).chNamesSelected]);
nAllCh =length(allChNames);

% Find for each channel where in each stimCh it is
nRecChannels=zeros(1,nStim);
indInAll=cell(1,nStim);
indPerStimCh=cell(1,nStim);
chNamesPerStim=cell(1,nStim);
for iStimCh=1:nStim
    chNamesWithStim = [stimSiteNames(iStimCh), chInfoRep(iStimCh).chNamesSelected];
    [indInAll{iStimCh}, indPerStimCh{iStimCh}, chNamesPerStim{iStimCh}] = strmatchAll(allChNames, chNamesWithStim);  % Assumes all the same
%    anatRegionPerStimCh = [anatRegionsStimCh(iStimCh), chInfoRep(iStimCh).anatRegionsPerCh]; % this is only the TARGTE regions
    %anatRegions{iStimCh} = anatRegionPerStimCh(indPerStimCh{iStimCh});
    nRecChannels(iStimCh) = length(chNamesPerStim{iStimCh});
end
% Add Stim channels if they are not in the file


%% Get N resp
%[nRespPerState, perRespChPerState, stimSitesPerState, pNamesPerState, meanNRespPerState, nRespPerStatePerPat, stimSitesPerStatePerPat] = getNRespChannels({lstResponsiveChannelMATfile});

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
chClinicType = cell(1,nStim); % is SOZ / lesion etc
for iStimCh=1:nStim
    anatRegionPerStimCh = [anatRegionsStimCh(iStimCh), chInfoRep(iStimCh).anatRegionsPerCh];
    anatRegions{iStimCh} = anatRegionPerStimCh(indPerStimCh{iStimCh});
    isChRespTemp = [1, chInfoRep(iStimCh).isChResponsive];  % 1 is added to account for stim channel
    isChResp{iStimCh} = isChRespTemp(indPerStimCh{iStimCh});
    ampRespChTemp = [maxValues.maxP2PAmp, chInfoRep(iStimCh).infoAmpPerCh.dataMaxMinAmp];  %avPeakToPeakAmpPerCh - maxP2PAmp is added to account for stim channel
    ampRespCh{iStimCh} = ampRespChTemp(indPerStimCh{iStimCh});
    ampOnlyRespCh{iStimCh} = ampRespCh{iStimCh} .* isChResp{iStimCh}; % only keep amplitude for responsive channels
    latencyTemp =  zeros(1,nRecChannels(iStimCh)); 
    latencyTemp(find(isChRespTemp)) = [maxValues.maxLatency, cellfun(@double, chInfoRep(iStimCh).locMaxPeakRespCh)];  % locResponsiveCh maxLatency is added to account for stim channel
    latencyOnlyRespCh{iStimCh} = latencyTemp(indPerStimCh{iStimCh});
    % REMOVED UNIQUE - it changes ORDER
     %uRegionLabels = unique(chInfoRep(iStimCh).cfgInfoPlot.targetLabels);
     regionLabels = chInfoRep(iStimCh).cfgInfoPlot.targetLabels;
     for iCh=1:length(anatRegions{iStimCh})
        indRegionPerCh{iStimCh}(iCh) = find(strcmpi(anatRegions{iStimCh}{iCh},regionLabels)); 
     end
    % Distance to Stim
    RASCoordStimCh = chInfoRep(iStimCh).RASCoordPerChStimCh;
    RASCoordPerCh = [RASCoordStimCh; chInfoRep(iStimCh).RASCoordPerCh];
    distRecToStimChTemp = RASdistanceToStim(RASCoordStimCh, RASCoordPerCh); % Stim first then rec channels
    distRecToStimCh{iStimCh} = distRecToStimChTemp(indPerStimCh{iStimCh});
    
    % Add also info regarding SOZ
 %   chTypeTemp = [chInfoRep(iStimCh).stimChClinicType, chInfoRep(iStimCh).chClinicType];
 %   chClinicType{iStimCh} = chTypeTemp(indPerStimCh{iStimCh});
end

%% Get also Lobular and General region
lobeRegions = cell(1,nStim);
gralRegions = cell(1,nStim);
indLobeRegionPerCh = cell(1,nStim);
indGralRegionPerCh = cell(1,nStim);
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
    for iCh=1:length(lobeRegions{iStimCh})
        indLobeRegionPerCh{iStimCh}(iCh) = find(strcmpi(lobeRegions{iStimCh}{iCh},regionNames));
    end
    %repeat for general regions
    for iRegion=1:length(gralRegionNames)
        [indChWithinStimRegion] = findChannelsWithinRegion(stChannelPerRegion, gralRegionNames{iRegion});
        indChWithinStimRegion = indChWithinStimRegion{1};
        gralRegions{iStimCh}(indChWithinStimRegion) = gralRegionNames(iRegion);
    end   
    for iCh=1:length(gralRegions{iStimCh})
        indGralRegionPerCh{iStimCh}(iCh) = find(strcmpi(gralRegions{iStimCh}{iCh},gralRegionNames));
    end
end


%% Put together the channels and order alphabetical and per LOBE region
indOrderedLeftInOriginal = cell(1,4);
indOrderedRightInOriginal = cell(1,4);
nRowsPerStim = cell(1,4);
for iStimCh=1:nStim
    % Then Order by region - with orer as in targetRegions
%    [sortedAnatRegions, indRowRegion] = sortAnatPerGralRegions(anatRegions{iStimCh}, regionLabels);
    [sortedAnatRegions, indRowRegion] = sortAnatPerGralRegions(lobeRegions{iStimCh}, regionNames);
    %[anatRegionsSorted, indRowRegion] = sort(anatRegions{iStimCh});
    % Separate Left and Right as 2 columns - Assumes we can separate by L R in first letter of name
    indLeftCh = find(strncmp(chNamesPerStim{iStimCh}(indRowRegion),'L',1));
    indRightCh = find(strncmp(chNamesPerStim{iStimCh}(indRowRegion),'R',1));
    indOrderedLeftInOriginal{iStimCh} = indRowRegion(indLeftCh);
    indOrderedRightInOriginal{iStimCh} = indRowRegion(indRightCh);
    nRowsPerStim{iStimCh} = max(length(indLeftCh),length(indRightCh));
end

%% Find colors that correspond to each region


%% Create xls tables per Stim in xls 
% First column is Left channels / second column is Right channels 
posFix = '_perStimCh.xlsx';
varNames = {'chNamesPerStim', 'gralRegions','lobeRegions', 'anatRegions', 'isChResp', 'ampRespCh','ampOnlyRespCh', 'distRecToStimCh',...
            'indRegionPerCh','latencyOnlyRespCh','indLobeRegionPerCh','indGralRegionPerCh'}; %,'chClinicType'};

for iVar=1:length(varNames)
    dataToSaveAllStim = eval(varNames{iVar});
    for iStimCh=1:nStim
        dataToSave = dataToSaveAllStim{iStimCh};
        nCols=2;
        lLeft = length(indOrderedLeftInOriginal{iStimCh});
        lRight = length(indOrderedRightInOriginal{iStimCh});
        nRows = max(lLeft,lRight);
        % Save data as 2 col xls
        if iscell(dataToSave)
            m4Save=cell(nRows, nCols);
            m4Save{1,1}=' '; m4Save{1,2}=' '; % BAD hack to prevent Cicro from crashing for patients with unilateral data
        else
            m4Save=zeros(nRows, nCols);
        end
        dataL = dataToSave(indOrderedLeftInOriginal{iStimCh});
        dataR = dataToSave(indOrderedRightInOriginal{iStimCh});
        m4Save(1:lLeft,1) = dataL;
        m4Save(1:lRight,2) = dataR;
        xlswrite([xlsFileNameGral, stimSiteNames{iStimCh},'_', varNames{iVar}, posFix], m4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        clear m4Save;
        % Create matrices for edges and save
        if isnumeric(dataToSave)
            mEdges4Save = zeros(nCols*nRows, nCols*nRows);
            indOrderLR = [indOrderedLeftInOriginal{iStimCh}, indOrderedRightInOriginal{iStimCh}]; % order as Left and then Right to keep order of the tables
            indStimCh = find(strcmp(chNamesPerStim{iStimCh}(indOrderLR), stimSiteNames{iStimCh}));
            indRowsLR =[1:lLeft,nRows+1:nRows+lRight];
            mEdges4Save(indRowsLR(indStimCh),indRowsLR) = dataToSave(indOrderLR);
            mEdges4Save(indRowsLR,indRowsLR(indStimCh)) = dataToSave(indOrderLR);    
            %remove lower triangle and save
           % mEdges4Save = triu(mEdges4Save);
            xlswrite([xlsFileNameGral, 'mEdges_',stimSiteNames{iStimCh},'_', varNames{iVar}, posFix], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            save([matFileNameGral, 'mEdges_',stimSiteNames{iStimCh},'_', varNames{iVar}, posFix],'mEdges4Save'); 
            % max out everything above maxVal
            mEdges4Save(mEdges4Save>maxValues.maxP2PAmp)=maxValues.maxP2PAmp;
            xlswrite([xlsFileNameGral, 'mEdges_',stimSiteNames{iStimCh},'_', varNames{iVar},'_Max',num2str(maxValues.maxP2PAmp),'_', posFix], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            save([matFileNameGral, 'mEdges_',stimSiteNames{iStimCh},'_', varNames{iVar},'_Max',num2str(maxValues.maxP2PAmp),'_', posFix],'mEdges4Save'); 
       end
    end
end





