function [dirDataXls] = preparePerRegionDataForCircroPlots(lstResponsiveChannelMATfiles, dirDataXls, titNameForFile,  maxValues, commonStimChPName)
% save Responsive data in tables to then generate circro plots for ALL
% PATIENTS ina selected region
% Also useful to get pooled information (e.g. total number of recording or stim channels)

%% Config
if ~exist('dirDataXls','var'), dirDataXls=fileparts(lstResponsiveChannelMATfiles{1}); end
if ~exist('titNameForFile','var'), titNameForFile=[]; end
if ~exist('commonStimChPName','var'), commonStimChPName=[]; end
IPSIonLEFT =1; % REVERSE RIGHT STIM TO HAVE ALL ON LEFT - Not Implemented!

nPrimes = primes(100); % 25 prime numbers

if ~exist('maxValues','var')
    maxValues.maxP2PAmp = 10; % assign to STIM channel - to enforce same scale in all plots 
    maxValues.maxLatency = 0.2; % assign to STIM channel - to enforce same scale in all plots
end

% The order of this cell indicates the order of the plot
regionNames = {'dlPFC','dmPFC','vlPFC','OF','ACC','central','insula','MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};
gralRegionNames = {'frontal','ACC','central','insula','temporal','posterior','subcortical','thalCaud','WM'};
%gralRegionNames = {'anterior','frontal','central','insula','temporal','posterior','subcortical','thalCaud','WM'};

indRegionInGralRegion = [1,1,1,1,2,3,4,5,5,6,6,6,7,8,9];
%indRegionInGralRegion = [1,1,1,2,3,4,4,5,5,5,6,7,8];

%% DIrectories and Files
% dirCircroPlotsXlsPerPatient = [dirDataXls, filesep, pName];
if ~isfolder(dirDataXls), mkdir(dirDataXls); end
xlsFileNameGral = [dirDataXls, filesep, titNameForFile, '_'];

% Save also MAT files with data
dirDataMATs = [dirDataXls,filesep,'MATfiles'];
if ~isfolder(dirDataMATs), mkdir(dirDataMATs); end
MATFileNameGral = [dirDataMATs, filesep, titNameForFile, '_'];

%% load ALL Data
chInfoRepAll=[];
pNamesAll=[];
chNamesPNames=[];
for iFile = 1:numel(lstResponsiveChannelMATfiles)
    stRespData = load(lstResponsiveChannelMATfiles{iFile});
    pName = stRespData.channInfo.pName;
    thisState = stRespData.thisState;
    
    % Organize data
   % chInfoRep = stRespData.channInfoRespCh_AveragePerTrial;
    chInfoRep = [stRespData.channInfoRespCh{:}];
    if ~isempty(chInfoRep)
        chInfoRepAll = [chInfoRepAll, chInfoRep];
        pNamesAll = [pNamesAll, repmat({pName},1,length(chInfoRep))];
        chNamesPNames = [chNamesPNames, strcat([chInfoRep(:).chNamesSelected],'_',pName)];
    end
end
if isempty(chInfoRepAll)
    disp(['No data for ',pName,' ',thisState]);
    return;
end

%% Add patient name to channel name
stimSiteNames = [chInfoRepAll.stimSiteNames];
if isempty(strfind(stimSiteNames{1,1},'-'))
    stimSiteNames = strcat(stimSiteNames(2,:),'-',stimSiteNames(1,:));
end
stimSitePatNames = strcat(stimSiteNames,'_',pNamesAll);

% remove those that are not in the comparison - if specified
if ~isempty(commonStimChPName)
    indKeep = strmatchAll(stimSitePatNames, commonStimChPName);
    stimSiteNames = stimSiteNames(indKeep);
    pNamesAll = pNamesAll(indKeep);
    stimSitePatNames = stimSitePatNames(indKeep);
    chInfoRepAll = chInfoRepAll(indKeep);
end

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
indAnatRegionPerCh = cell(1,nStim);
indStimPerStim = cell(1,nStim);
indStimOnlyRespPerStim = cell(1,nStim);
for iStimCh=1:nStim
    anatRegionPerStimCh = [anatRegionsStimCh(iStimCh), chInfoRepAll(iStimCh).anatRegionsPerCh];
    anatRegions{iStimCh} = anatRegionPerStimCh(indPerStimCh{iStimCh});
    isChRespTemp = [1, chInfoRepAll(iStimCh).isChResponsive];  % 1 is added to account for stim channel
    isChResp{iStimCh} = isChRespTemp(indPerStimCh{iStimCh});
    ampRespChTemp = [maxValues.maxP2PAmp, chInfoRepAll(iStimCh).infoAmpPerCh.peakToPeakAmp];  %maxP2PAmp is added to account for stim channel / alternative: dataMaxMinAmp
    ampRespCh{iStimCh} = ampRespChTemp(indPerStimCh{iStimCh});
    ampOnlyRespCh{iStimCh} = ampRespCh{iStimCh} .* isChResp{iStimCh}; % only keep amplitude for responsive channels
    latencyTemp =  zeros(1,nRecChannels(iStimCh)); 
    latencyTemp(find(isChRespTemp)) = [maxValues.maxLatency, cellfun(@double, chInfoRepAll(iStimCh).locMaxPeakRespCh)];  % maxLatency is added to account for stim channel
    latencyOnlyRespCh{iStimCh} = latencyTemp(indPerStimCh{iStimCh});
    % REMOVED UNIQUE - it changes ORDER
     %uRegionLabels = unique(chInfoRepAll(iStimCh).cfgInfoPlot.targetLabels);
     regionLabels = chInfoRepAll(iStimCh).cfgInfoPlot.targetLabels;
     for iCh=1:length(anatRegions{iStimCh})
        indAnatRegionPerCh{iStimCh}(iCh) = find(strcmpi(anatRegions{iStimCh}{iCh},regionLabels)); 
     end
    % Distance to Stim
    RASCoordStimCh = chInfoRepAll(iStimCh).RASCoordPerChStimCh;
    RASCoordPerCh = [RASCoordStimCh; chInfoRepAll(iStimCh).RASCoordPerCh];
    distRecToStimChTemp = RASdistanceToStim(RASCoordPerCh, RASCoordStimCh);
    distRecToStimCh{iStimCh} = distRecToStimChTemp(indPerStimCh{iStimCh});
    % Keep index of stim channel
    indStimPerStim{iStimCh} = repmat(iStimCh,1,numel(anatRegionPerStimCh));
    indStimOnlyRespPerStim{iStimCh} = indStimPerStim{iStimCh} .* isChResp{iStimCh}; % only keep amplitude for responsive channels
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
%indStimLobes = find(strmatchAll(regionNames,unique(lobeStimRegions))); % UNIQUE changes order and we need order of gralRegions/regionNames
unStimLobeRegions = regionNames; %(indStimLobes); % ONLY save those with STIM - RIZ: changed to use ALL at most they will be empty
nStimLobes = length(unStimLobeRegions);
%indStimGralRegions = find(strmatchAll(gralRegionNames,unique(gralStimRegions))); % UNIQUE changes order and we need order of gralRegions/regionNames
unStimGralRegions = gralRegionNames;%(indStimGralRegions); % ONLY save those with STIM
nStimGralRegions = length(unStimGralRegions);

%% Put together the channels and order alphabetical and per LOBE region
indOrderedLeftInOriginal = cell(1,4);
indOrderedRightInOriginal = cell(1,4);
nRowsPerStim = cell(1,4);
nRecChPerRegion = zeros(1,length(regionNames));
nRecChPerGralRegion = zeros(1,length(gralRegionNames));
for iStimCh=1:nStim
%    [sortedAnatRegions, indRowRegion] = sortAnatPerGralRegions(anatRegions{iStimCh}, regionLabels);
    % Separate Left and Right as 2 columns - Assumes we can separate by L R in first letter of name
    indLeftCh = find(strncmp(chNamesPerStim{iStimCh},'L',1));
    indRightCh = find(strncmp(chNamesPerStim{iStimCh},'R',1));
    % Then Order by region - with orer as in targetRegions
   [sortedAnatRegions, indRowRegion, nChPerRegionL] = sortAnatPerGralRegions(lobeRegions{iStimCh}(indLeftCh), regionNames);
    indOrderedLeftInOriginal{iStimCh} = indLeftCh(indRowRegion);
   [sortedAnatRegions, indRowRegion, nChPerRegionR] = sortAnatPerGralRegions(lobeRegions{iStimCh}(indRightCh), regionNames);
    indOrderedRightInOriginal{iStimCh} = indRightCh(indRowRegion);
    nRowsPerStim{iStimCh} = max(length(indLeftCh),length(indRightCh));
    nRecChPerRegion =max([nRecChPerRegion; nChPerRegionL; nChPerRegionR],[],1);    % Get MAX numbers per region
   % nRecChPerRegionR =max([nRecChPerRegionR; nChPerRegionR],[],1);    % Get MAX numbers per region
end
for iGralRegion=1:length(nRecChPerGralRegion)
    nRecChPerGralRegion(iGralRegion) =sum(nRecChPerRegion(indRegionInGralRegion==iGralRegion));    % Get MAX numbers per region
end

%% Create xls tables per Stim in xls - PER LOBE STIM region
% First column is Left channels / second column is Right channels 
% Plot Pooled per region data
posFixXLS = '_perLobeStimCh.xlsx';
posFixMAT = '_perLobeStimCh.mat';
varNames = {'gralRegions','lobeRegions', 'anatRegions','chNamesPerStim', ...
            'indAnatRegionPerCh','indLobeRegionPerCh','indGralRegionPerCh',...
            'isChResp', 'ampRespCh','ampOnlyRespCh', 'distRecToStimCh','latencyOnlyRespCh','indStimPerStim','indStimOnlyRespPerStim'};
varNamesForMatrix = {'isChResp', 'ampRespCh','ampOnlyRespCh', 'distRecToStimCh','latencyOnlyRespCh','indStimPerStim','indStimOnlyRespPerStim',...
                     'indAnatRegionPerCh','indLobeRegionPerCh','indGralRegionPerCh'};
% Save 2 column (LEFT/RIGHT) excels first for STR data
nCols=2;
nRows = sum(nRecChPerRegion); %max(lLeft,lRight);
% First sheet contains all the names of the recording regions /lobes (PFC 45 times ,
for iRegion=1:nStimLobes
    ind1=1;
    for iRecRegion=1:length(regionNames)
        ind2 = ind1+nRecChPerRegion(iRecRegion)-1;
        m4SaveRegion(ind1:ind2,1:2) = regionNames(iRecRegion);
        m4SaveIndRegion(ind1:ind2,1:2) = iRecRegion;
        m4SaveGralRegion(ind1:ind2,1:2) = gralRegionNames(indRegionInGralRegion(iRecRegion));
        m4SaveIndGralRegion(ind1:ind2,1:2) = indRegionInGralRegion(iRecRegion);
        ind1 = ind2+1;
    end
    xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', 'lobeRegions', posFixXLS], m4SaveRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', 'indLobeRegionPerCh', posFixXLS], m4SaveIndRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', 'gralRegions', posFixXLS], m4SaveGralRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', 'indGralRegionPerCh', posFixXLS], m4SaveIndGralRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    clear m4SaveRegion; clear m4SaveIndRegion; clear m4SaveGralRegion; clear m4SaveIndGralRegion;
end

for iVar=1:length(varNames)
    varName = varNames{iVar};
    dataToSaveAllStim = eval(varName);
    for iRegion=1:nStimLobes
        stimSitePatNamesPerRegion=[];
        indStimChPerRegion=[];
        for iStimCh=1:nStim     % Pool all stim per region together
            if strcmp(lobeStimRegions{iStimCh}, unStimLobeRegions{iRegion})
                dataToSave = dataToSaveAllStim{iStimCh};
                lobesToSave = lobeRegions{iStimCh};
                stimSitePatNamesPerRegion = [stimSitePatNamesPerRegion;stimSitePatNames(iStimCh)];
                indStimChPerRegion = [indStimChPerRegion; iStimCh];
                dataL = dataToSave(indOrderedLeftInOriginal{iStimCh});
                dataR = dataToSave(indOrderedRightInOriginal{iStimCh});
                lobesL = lobesToSave(indOrderedLeftInOriginal{iStimCh});
                lobesR = lobesToSave(indOrderedRightInOriginal{iStimCh});
                % Save data as 2 col xls
                if iscell(dataL), m4Save=cell(nRows, nCols); m4Save{1,1}=' '; m4Save{1,2}=' '; % BAD hack to prevent Cicro from crashing for patients with unilateral data
                else, m4Save=zeros(nRows, nCols); end
                % Save left right separately
                ind1=1;
                for iRecRegion=1:length(regionNames)
                    indDataL =  find(strcmp(lobesL,regionNames{iRecRegion}));
                    m4Save(ind1:ind1+length(indDataL)-1,1) = dataL(indDataL);
                    indDataR =  find(strcmp(lobesR,regionNames{iRecRegion}));
                    m4Save(ind1:ind1+length(indDataR)-1,2) = dataR(indDataR);
                    ind1 = ind1+nRecChPerRegion(iRecRegion);
                end                
                xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', varName, posFixXLS], m4Save, stimSitePatNames{iStimCh}); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            end
        end
        if ~isempty(stimSitePatNamesPerRegion)
            xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', varName, posFixXLS], stimSitePatNamesPerRegion, 'stimChannels'); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            save([MATFileNameGral, unStimLobeRegions{iRegion},'_',varName, posFixMAT],'indOrderedRightInOriginal','indOrderedLeftInOriginal','regionNames','indStimChPerRegion',...
                'varName','stimSitePatNamesPerRegion','stimSitePatNames','nRecChPerRegion','lobeStimRegions','anatRegionsStimCh','unStimLobeRegions','dataToSaveAllStim');
        end
    end
end

% For NUMERIC data Create matrices for edges and save       
for iVar=1:length(varNamesForMatrix)
    varName = varNamesForMatrix{iVar};
    dataToSaveAllStim = eval(varName);
    for iRegion=1:nStimLobes
        indStimChPerRegion=[];
        stimSitePatNamesPerRegion=[];
        mEdges4Save= zeros(nCols*nRows, nCols*nRows); %zeros
        indStimInRegion= sum(nRecChPerRegion(1:iRegion))-nRecChPerRegion(iRegion);
        for iStimCh=1:nStim     % Pool all stim per region together
            if strcmp(lobeStimRegions{iStimCh}, unStimLobeRegions{iRegion})
                indStimInRegion = indStimInRegion+1;
                dataToSave = dataToSaveAllStim{iStimCh};
                lobesToSave = lobeRegions{iStimCh};
                stimSitePatNamesPerRegion = [stimSitePatNamesPerRegion;stimSitePatNames(iStimCh)];
                indStimChPerRegion = [indStimChPerRegion; iStimCh];
                dataL = dataToSave(indOrderedLeftInOriginal{iStimCh});
                dataR = dataToSave(indOrderedRightInOriginal{iStimCh});
                lobesL = lobesToSave(indOrderedLeftInOriginal{iStimCh});
                lobesR = lobesToSave(indOrderedRightInOriginal{iStimCh});

                ind1=1;
                for iRecRegion=1:length(regionNames)
                    indDataL =  find(strcmp(lobesL,regionNames{iRecRegion}));
                    mEdges4Save(ind1:ind1+length(indDataL)-1, indStimInRegion) = dataL(indDataL);
                    mEdges4Save(indStimInRegion, ind1:ind1+length(indDataL)-1) = dataL(indDataL);
                   
                    indDataR =  find(strcmp(lobesR,regionNames{iRecRegion}));
                    mEdges4Save(ind1+nRows:ind1+length(indDataR)-1+nRows, indStimInRegion+nRows) = dataR(indDataR);
                    mEdges4Save(indStimInRegion+nRows, ind1+nRows:ind1+length(indDataR)-1+nRows) = dataR(indDataR);
                    ind1 = ind1+nRecChPerRegion(iRecRegion);
                end
            end
        end
        %remove lower triangle and save
        %  mEdges4Save = triu(mEdges4Save);
        xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_', 'mEdges_',varName, posFixXLS], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        save([MATFileNameGral, unStimLobeRegions{iRegion},'_', 'mEdges_',varName, posFixMAT],'mEdges4Save','indOrderedRightInOriginal','indOrderedLeftInOriginal','regionNames','indStimChPerRegion','varName',...
            'stimSitePatNamesPerRegion','stimSitePatNames','nRecChPerRegion','lobeStimRegions','anatRegionsStimCh','unStimLobeRegions','dataToSaveAllStim'); 
        % max out everything above maxVal
        if  contains(varName,'amp') %any(mEdges4Save(:)>maxValues.maxP2PAmp)
            mEdges4Save(mEdges4Save>maxValues.maxP2PAmp)=maxValues.maxP2PAmp;
            xlswrite([xlsFileNameGral, unStimLobeRegions{iRegion},'_','mEdges_', varName,'_Max',num2str(maxValues.maxP2PAmp),'_', posFixXLS], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        end
    end
end

%% Repeat at the gral region level
posFixXLS = '_perGralRegionStimCh.xlsx';
posFixMAT = '_perGralRegionStimCh.mat';
% Same for general regions as before for lobes
% First sheet contains all the names of the recording regions /lobes (PFC 45 times ,
for iRegion=1:nStimGralRegions
    ind1=1;
    for iRecRegion=1:length(regionNames)
        ind2 = ind1+nRecChPerRegion(iRecRegion)-1;
        m4SaveRegion(ind1:ind2,1:2) = regionNames(iRecRegion);
        m4SaveIndRegion(ind1:ind2,1:2) = iRecRegion;
        m4SaveGralRegion(ind1:ind2,1:2) = gralRegionNames(indRegionInGralRegion(iRecRegion));
        m4SaveIndGralRegion(ind1:ind2,1:2) = indRegionInGralRegion(iRecRegion);
        ind1 = ind2+1;
    end
    xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', 'lobeRegions', posFixXLS], m4SaveRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', 'indLobeRegionPerCh', posFixXLS], m4SaveIndRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', 'gralRegions', posFixXLS], m4SaveGralRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', 'indGralRegionPerCh', posFixXLS], m4SaveIndGralRegion); % only save as xls if we are in WINDOWS! it saves as csv in MAC
    clear m4SaveRegion; clear m4SaveIndRegion; clear m4SaveGralRegion; clear m4SaveIndGralRegion;
end
for iVar=1:length(varNames)
    varName = varNames{iVar};
    dataToSaveAllStim = eval(varName);
    for iRegion=1:nStimGralRegions
        stimSitePatNamesPerRegion=[];
        indStimChPerRegion=[];
        for iStimCh=1:nStim     % Pool all stim per region together
            if strcmp(gralStimRegions{iStimCh}, unStimGralRegions{iRegion})
                dataToSave = dataToSaveAllStim{iStimCh};
                gralRegionToSave = gralRegions{iStimCh};
                stimSitePatNamesPerRegion = [stimSitePatNamesPerRegion;stimSitePatNames(iStimCh)];
                indStimChPerRegion = [indStimChPerRegion; iStimCh];
                dataL = dataToSave(indOrderedLeftInOriginal{iStimCh});
                dataR = dataToSave(indOrderedRightInOriginal{iStimCh});
                gralRegionL = gralRegionToSave(indOrderedLeftInOriginal{iStimCh});
                gralRegionR = gralRegionToSave(indOrderedRightInOriginal{iStimCh});
                % Save data as 2 col xls
                if iscell(dataL), m4Save=cell(nRows, nCols); m4Save{1,1}=' '; m4Save{1,2}=' '; % BAD hack to prevent Cicro from crashing for patients with unilateral data
                else, m4Save=zeros(nRows, nCols); end
                % Save left right separately
                ind1=1;
                for iRecRegion=1:length(gralRegionNames)
                    indDataL =  find(strcmp(gralRegionL,gralRegionNames{iRecRegion}));
                    m4Save(ind1:ind1+length(indDataL)-1,1) = dataL(indDataL);
                    indDataR =  find(strcmp(gralRegionR,gralRegionNames{iRecRegion}));
                    m4Save(ind1:ind1+length(indDataR)-1,2) = dataR(indDataR);
                    ind1 = ind1+nRecChPerGralRegion(iRecRegion);
                end                
                xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', varName, posFixXLS], m4Save, stimSitePatNames{iStimCh}); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            end
        end
        if ~isempty(stimSitePatNamesPerRegion)
            xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', varName, posFixXLS], stimSitePatNamesPerRegion, 'stimChannels'); % only save as xls if we are in WINDOWS! it saves as csv in MAC
            save([MATFileNameGral, unStimGralRegions{iRegion},'_',varName, posFixMAT],'indOrderedRightInOriginal','indOrderedLeftInOriginal','regionNames','indStimChPerRegion',...
                'varName','stimSitePatNamesPerRegion','stimSitePatNames','nRecChPerRegion','lobeStimRegions','anatRegionsStimCh','unStimLobeRegions','dataToSaveAllStim');
        end
    end
end

% to have edges per general region
% For NUMERIC data Create matrices for edges and save       
for iVar=1:length(varNamesForMatrix)
    varName = varNamesForMatrix{iVar};
    dataToSaveAllStim = eval(varName);
    for iRegion=1:nStimGralRegions
        indStimChPerRegion=[];
        stimSitePatNamesPerRegion=[];
        mEdges4Save= zeros(nCols*nRows, nCols*nRows); %zeros
        indStimInRegion= sum(nRecChPerGralRegion(1:iRegion))-nRecChPerGralRegion(iRegion);
        for iStimCh=1:nStim     % Pool all stim per region together
            if strcmp(gralStimRegions{iStimCh}, unStimGralRegions{iRegion})
                indStimInRegion = indStimInRegion+1;
                dataToSave = dataToSaveAllStim{iStimCh};
                gralRegionToSave = gralRegions{iStimCh};
                stimSitePatNamesPerRegion = [stimSitePatNamesPerRegion;stimSitePatNames(iStimCh)];
                indStimChPerRegion = [indStimChPerRegion; iStimCh];
                dataL = dataToSave(indOrderedLeftInOriginal{iStimCh});
                dataR = dataToSave(indOrderedRightInOriginal{iStimCh});
                gralRegionL = gralRegionToSave(indOrderedLeftInOriginal{iStimCh});
                gralRegionR = gralRegionToSave(indOrderedRightInOriginal{iStimCh});

                ind1=1;
                for iRecRegion=1:length(gralRegionNames)
                    indDataL =  find(strcmp(gralRegionL,gralRegionNames{iRecRegion}));
                    mEdges4Save(ind1:ind1+length(indDataL)-1, indStimInRegion) = dataL(indDataL);
                    mEdges4Save(indStimInRegion, ind1:ind1+length(indDataL)-1) = dataL(indDataL);
                   
                    indDataR =  find(strcmp(gralRegionR,gralRegionNames{iRecRegion}));
                    mEdges4Save(ind1+nRows:ind1+length(indDataR)-1+nRows, indStimInRegion+nRows) = dataR(indDataR);
                    mEdges4Save(indStimInRegion+nRows, ind1+nRows:ind1+length(indDataR)-1+nRows) = dataR(indDataR);
                    ind1 = ind1+nRecChPerGralRegion(iRecRegion);
                end
            end
        end
        %remove lower triangle and save
        %  mEdges4Save = triu(mEdges4Save);
        xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_', 'mEdges_',varName, posFixXLS], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        save([MATFileNameGral, unStimGralRegions{iRegion},'_', 'mEdges_',varName, posFixMAT],'mEdges4Save','indOrderedRightInOriginal','indOrderedLeftInOriginal','regionNames','indStimChPerRegion','varName',...
            'stimSitePatNamesPerRegion','stimSitePatNames','nRecChPerRegion','lobeStimRegions','anatRegionsStimCh','unStimLobeRegions','dataToSaveAllStim','gralRegionNames'); 
        % max out everything above maxVal
        if  contains(varName,'amp') %any(mEdges4Save(:)>maxValues.maxP2PAmp)
            mEdges4Save(mEdges4Save>maxValues.maxP2PAmp)=maxValues.maxP2PAmp;
            xlswrite([xlsFileNameGral, unStimGralRegions{iRegion},'_','mEdges_', varName,'_Max',num2str(maxValues.maxP2PAmp),'_', posFixXLS], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        end
    end
end



