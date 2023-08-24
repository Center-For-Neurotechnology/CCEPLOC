function [lstResponsiveChannel, channInfoRespCh] = findResponsiveChannelsKeller2011(EEGStimTrialMATfile, dirImages, whatToUse,useAverage, indTrialsToExclude, tLimitsSec, channInfo)

% Responsive channels are channels were mean N1 peak is at least 3 std above baseline
% Usually done for Wake data and then used during anesthesia
if ~exist('indTrialsToExclude','var'),indTrialsToExclude=[]; end
if ~exist('channInfo','var'),channInfo=[]; end

%Config
minNumberTrials = 5; % before 10 - at least 10 trials to find peaks!
nStdResponsive = 6;  %2.576=99% / 2.33=98% / 1.96~2=95%

% kept for consistency - but not really used
thQuantileBaseline = 0.95; 
nTimesAboveBaseAmp = 3; % strict=2 - before 3 and median instead of q95
nTimesAboveBaseArea = 3; % strict=2 -  before 3 and median instead of q95
nStdResponsiveP2P = 2.576;  %2.576=99% / 2.33=98% / 1.96~2=95%
nStdResponsiveP2P2P = nStdResponsiveP2P*2; %8 before 1.5=6; 
nStdResponsiveAmp = nStdResponsiveP2P; %2.576;  %3; %nStdResponsiveP2P*2; % 5;
thArea = 400; % Area = Width (samples) x prominence (zScore). E.g. if prominence (similar to p2p amp) is 4 -> it has to be 150ms long - this allows finding wide but short peaks
thP2PArea = thArea; % Area = Width (samples) x prominence (zScore). idem  Area -  E.g. if prominence (similar to p2p amp) is 4 -> it has to be 150ms long - this allows finding wide but short peaks
thP2P2PArea = thArea*2; %before 1.5* Area = Width (samples) x prominence (zScore).50% more than Area -  E.g. if prominence (similar to p2p amp) is 4 -> it has to be 150ms long - this allows finding wide but short peaks
minPercAboveTh = 0.75; %at least 75% of the trials MUST be above nStdResponsiveP2P threshold


cfgInfoPeaks.nStdResponsiveP2P = nStdResponsive;
cfgInfoPeaks.nStdResponsiveP2P2P = [];
cfgInfoPeaks.nStdResponsiveAmp = nStdResponsive;
cfgInfoPeaks.minPercAboveTh = [];
cfgInfoPeaks.minNumberTrials = minNumberTrials;
cfgInfoPeaks.nTimesAboveBaseAmp = [];
cfgInfoPeaks.nTimesAboveBaseArea = [];
cfgInfoPeaks.minPeakLocation = [];
cfgInfoPeaks.thArea = [];
cfgInfoPeaks.thP2PArea = [];
cfgInfoPeaks.thP2P2PArea = [];


disp(['Time to analyse: ',num2str(tLimitsSec(1)),' - ',num2str(tLimitsSec(2)),' sec']);
disp(['Configuration: ', ' nStdResponsiveP2P= ', num2str(nStdResponsive)]);
disp(cfgInfoPeaks);

if isempty(EEGStimTrialMATfile)
    lstResponsiveChannel=cell(1,0);
    channInfoRespCh=struct('lstResponsiveChannel',cell(0,0),'ampResponsiveCh',cell(0,0),'ptpResponsiveCh',cell(0,0),'locFirstPeakRespCh',cell(0,0),'locMaxPeakRespCh',cell(0,0),'rmsDataPerCh',cell(0,0),...
        'areaPerCh',cell(0,0),'areaP2PPerCh',cell(0,0),'prominencePerCh',cell(0,0),'p2P2PAmpPerCh',cell(0,0),'peakMaxMinAmpPerCh',cell(0,0),'nPeaksCh',cell(0,0),...
        'chNamesSelected',[],'chNamesExcluded',[],'chNamesSelectedOrig',[],'indExcludedChannels',[],'isChExcluded',[],'isChResponsive',[],'stimSiteNames',[],...
        'titName',[],'whatToUse',whatToUse,'useAverage',useAverage,'tLimitsSec',tLimitsSec,...
        'anatRegionsResp',cell(0,0),'RASCoordResp',cell(0,0),'anatRegionsStimCh',cell(0,0),'RASCoordPerChStimCh',cell(0,0),'anatRegionsPerCh',cell(0,0),'RASCoordPerCh',cell(0,0),...
        'infoAmpPerCh',[],'infoAmpPerChPerTrial',[],'cfgInfoPlot',[],'cfgInfoPeaks',cfgInfoPeaks,...
        'relAmpPerCh',cell(0,0),'relP2PPerCh',cell(0,0),'relP2P2PPerCh',cell(0,0),'relAreaPerCh',cell(0,0),'relP2PAreaPerCh',cell(0,0),'relP2P2PAreaPerCh',cell(0,0),'relMaxMinAmpPerCh',cell(0,0));
    return;
end
% Load Data
stData = load(EEGStimTrialMATfile);
titName = stData.titName;
stimSiteNames = stData.stimSiteNames; %  stim #1 & #2
    % stimSiteNames{2} = % before We were missing stim #2: strcat(stimSiteNames{1}(1:end-1),num2str(str2num(stimSiteNames{1}(end))+1)); % BAD HACK: add next channel as 2nd STIM channel!!

chNamesSelectedOrig = stData.chNamesSelected;
timeVals = stData.timePerTrialSec;
Fs = stData.hdr.Fs;

%% Select WHAT to USE in ANALYSIS
EEGtoAnalyzeAllTrials = selectWhatSignalToUse(stData, whatToUse, [], cfgInfoPeaks);
strWhatToUSe = whatToUse;

%% Exclude Channels
chNamesSelected = chNamesSelectedOrig;
chNamesExcluded = [];
indExcludedChannels =[];
isChExcluded = zeros(1,numel(chNamesSelectedOrig));
if ~isempty(channInfo) && isfield(channInfo,'excludedChannels') && ~isempty(channInfo.excludedChannels)
    [chNamesSelected, indExcludedChannels, EEGtoAnalyzeAllTrials] = excludeSpecificChannels(chNamesSelectedOrig, channInfo.excludedChannels, EEGtoAnalyzeAllTrials);
    chNamesExcluded = chNamesSelectedOrig(indExcludedChannels);
    isChExcluded(indExcludedChannels) = 1;
end
nChannels = numel(chNamesSelected);

%% Remove trials to exclude
for iCh=1:nChannels
    indTrialsToExcPerCh = intersect([1:size(EEGtoAnalyzeAllTrials{iCh},2)], indTrialsToExclude);
    EEGtoAnalyzeAllTrials{iCh}(:,indTrialsToExcPerCh)=[];
    nTrials(iCh)= size(EEGtoAnalyzeAllTrials{iCh},2);
end
nStim=nTrials;

%% Select if AVERAGE or Trial by trial
if useAverage
    %  case 'AVERAGE'
    for iCh=1:nChannels
        EEGtoAnalyze{iCh} = mean(EEGtoAnalyzeAllTrials{iCh}, 2); %use  median to remove outliers / mean would give a smooth signal though!
    end
    nStim = ones(1,nChannels); % since we are averaging all the responses - it is as if there was only 1 stim
    strWhatToUSe = [strWhatToUSe,' AVERAGED'];
end

%% Get RAS and Region information
[anatRegionsPerCh, RASCoordPerCh, anatRegionsStimCh, RASCoordPerChStimCh, ~, ~, cfgInfoPlot] = getRegionRASPerChannel(stData,[],chNamesSelected);

%% find peaks
indStim = find(timeVals>=0,1); 
indTimeStart = round(tLimitsSec(1)*Fs + indStim); % detect all peaks from 5ms to 200ms after stim
indTimeEnd = round(tLimitsSec(2)*Fs + indStim);

% peak is the abs amplitude in the 50-500ms after stim
indTimeStartPeakDet = round( 50 /1000 *Fs + indStim);% following stim % From Keller 2011
indTimeEndPeakDet =  round(500 /1000 *Fs + indStim);% From Keller 2011

 % Baseline time is from 500ms to 50ms  BEFORE stim - before time for baseline
indTimeStartBaseline =  round(-500/1000 *Fs + indStim); % ONLY 1 baseline segment for Keller 2011 - in our case: randperm(maxSampleStartBaseline, nBaselineIntervals)+ cfgInfoPeaks.extraSamplesForPeakDet; % to ensure that we don't have negative smaples when detecting peaks
indTimeEndBaseline =   round(-50/1000 *Fs + indStim);% From Keller 2011 - our: round(indTimeStartBaseline + tLimitsSec(2)*Fs); %round(indStim +(cfgInfoPeaks.tBaselineForZeroMean(1)  - tLimitsSec(1))*Fs - cfgInfoPeaks.extraSamplesForPeakDet);

lstResponsiveChannel=cell(1,0);
ampResponsiveCh=cell(1,0);
ptpResponsiveCh=cell(1,0);
locFirstPeakRespCh=cell(1,0);
locMaxPeakRespCh=cell(1,0);
isChResponsive = zeros(1,nChannels);
meanDataPerCh=[];
rmsDataPerCh=cell(1,0);
nPeaksCh=cell(1,0);
anatRegionsResp=cell(1,0);
RASCoordResp=cell(1,0);
perP2PAboveThCh=cell(1,0);
areaPerCh=cell(1,0);
areaP2PPerCh=cell(1,0);
p2P2PAmpPerCh=cell(1,0);
avProminencePerCh=cell(1,0);
peakMaxMinAmpPerCh=cell(1,0);
relAmpPerCh=cell(1,0);
relP2PPerCh=cell(1,0);
relP2P2PPerCh=cell(1,0);
relAreaPerCh=cell(1,0);
relP2PAreaPerCh=cell(1,0);
relP2P2PAreaPerCh=cell(1,0);
relMaxMinAmpPerCh=cell(1,0);
for iCh=1:nChannels
    if nTrials(iCh)>= minNumberTrials
        data1 = squeeze(EEGtoAnalyze{iCh});
        largestAmpN2 = max(abs(data1(indTimeStartPeakDet: indTimeEndPeakDet))); % simply get the max ampltiude of the pertrial normalized averaged signal
        
%         % Find peaks after STIM
        [infoFirstPeak, infoAllPeaks, infoLargestPeak] = getPosNegPeaks(data1, indTimeStart, indTimeEnd, cfgInfoPeaks);
        firstPeakAmp = sum(abs([infoFirstPeak.peakAmp]));
        avFirstPeakAmp = firstPeakAmp /nStim(iCh);
        peakToPeakAmp = abs([infoLargestPeak.peakToPeakAmp]);   % p2p to consider typical CCEP
        p2P2PAmp = abs([infoLargestPeak.p2P2PAmp]);             % p2p2p to consider W type of shape
        largestAmp = abs([infoLargestPeak.peakAmp]);            % Max amplitude to consider long lasting CCEP -  ^ shape
        peakMaxMinAmp = abs([infoLargestPeak.peakMaxMinAmp]);    % peak max - peak min
% 
%         avLargestAmp = sum(largestAmp)/nStim(iCh); % if peak no found consider it as 0 in zscore
        avLargestAmp = largestAmpN2; % in Keller 2011 simply consider the largest amplitude
        
        sdBaseline = std(data1(indTimeStartBaseline:indTimeEndBaseline));
        meanBaseline = mean(abs(data1(indTimeStartBaseline:indTimeEndBaseline)));
        
        avPeakToPeakAmp = sum(peakToPeakAmp)/nStim(iCh); % if peak no found consider it as 0 in zscore
        allPeaks = [infoAllPeaks{:}];
        avPeakToPeakAmpPerCh(iCh) = avPeakToPeakAmp;
        avProminence = infoLargestPeak.peakProm /nStim(iCh); % Prominince of the largest peak
        avPeakMaxMinAmp = sum(peakMaxMinAmp)/nStim(iCh); % if peak no found consider it as 0 in zscore
        avArea = sum(infoLargestPeak.peakIntegral)/nStim(iCh); % Is AREA > than threshold? - corresponds to large peak
        avP2PArea = max(avArea, sum(abs([infoLargestPeak.peakToPeakIntegral]))/nStim(iCh));
        avP2P2PArea = max(avP2PArea, sum(abs([infoLargestPeak.peakToPeakToPeakIntegral]))/nStim(iCh));
        if ~infoFirstPeak.peakLoc, firstPeakLocation = inf;
        else, firstPeakLocation =  1000*timeVals(round(mean([infoFirstPeak.peakLoc],'omitnan')));end %in samples - thus the round -> then in milisec
        if ~infoLargestPeak.peakLoc, maxPeakLocation = inf;
        else, maxPeakLocation =  1000*timeVals(round(mean([infoLargestPeak.peakLoc],'omitnan')));end %in samples - thus the round -> then in milisec

        % Baseline values
        % Find peaks before STIM use many baseline segents each of same duration as interval of interest
        infoLargestPeakBaseline=[];
        for iBase=1:length(indTimeStartBaseline)
            [~, ~, infoLargestPeakTemp] = getPosNegPeaks(data1, indTimeStartBaseline(iBase), indTimeEndBaseline(iBase), cfgInfoPeaks);
            minAmp = min(data1(indTimeStartBaseline(iBase): indTimeEndBaseline(iBase)));
            maxAmp = max(data1(indTimeStartBaseline(iBase): indTimeEndBaseline(iBase)));
            % if not peak found - use min max values
            if infoLargestPeakTemp.peakAmp ==0
                infoLargestPeakTemp.peakAmp = max(abs([minAmp,maxAmp]));
                infoLargestPeakTemp.peakToPeakAmp = maxAmp-minAmp;
                infoLargestPeakTemp.p2P2PAmp = maxAmp-minAmp;
                infoLargestPeakTemp.peakMaxMinAmp = maxAmp-minAmp;
            end
            infoLargestPeakBaseline = [infoLargestPeakBaseline,infoLargestPeakTemp];
        end
       % avAmpBase =  (sum(abs([infoLargestPeakBaseline.peakAmp]))/nStim(iCh));
        avAmpBase =  quantile(abs([infoLargestPeakBaseline.peakAmp]),thQuantileBaseline);
        peakToPeakAmpBase = quantile(abs([infoLargestPeakBaseline.peakToPeakAmp]),thQuantileBaseline);   % p2p to consider typical CCEP
        p2P2PAmpBase = quantile(abs([infoLargestPeakBaseline.p2P2PAmp]),thQuantileBaseline);             % p2p2p to consider W type of shape
        peakAreaBase =  quantile(abs([infoLargestPeakBaseline.peakIntegral]),thQuantileBaseline);         % area of largest peak
        p2PAreaBase =  max(peakAreaBase, quantile(abs([infoLargestPeakBaseline.peakToPeakIntegral]),thQuantileBaseline));    % p2p area cannot be smaller than peak area
        p2P2PAreaBase =  max(p2PAreaBase, quantile(abs([infoLargestPeakBaseline.peakToPeakToPeakIntegral]),thQuantileBaseline));    % p2p2p area 
        peakMaxMinBase =  quantile(abs([infoLargestPeakBaseline.peakMaxMinAmp]),thQuantileBaseline);    % peak max - peak min 
          
        % Is larger than baseline "peaks"
        relAmpAboveBase = sum(avLargestAmp > nTimesAboveBaseAmp * avAmpBase)/nStim(iCh) > minPercAboveTh; % Is amplitude of first peak > than threshold?
        relP2PAmpAboveBase = sum(peakToPeakAmp > nTimesAboveBaseAmp * peakToPeakAmpBase)/nStim(iCh) > minPercAboveTh; % Is P2P amplitude > than threshold?
        relP2P2PAboveBase = sum(p2P2PAmp > nTimesAboveBaseAmp * p2P2PAmpBase)/nStim(iCh) > minPercAboveTh; % Is P2P amplitude > than threshold?
        relMaxMinAmpAboveBase = sum(avPeakMaxMinAmp > nTimesAboveBaseAmp * peakMaxMinBase)/nStim(iCh)> minPercAboveTh ; % Is amplitude of first peak > than threshold?
        relAreaAboveBase = sum(avArea > nTimesAboveBaseArea * peakAreaBase)/nStim(iCh)> minPercAboveTh ; % Is P2P amplitude > than threshold?
        relP2PAreaAboveBase = sum(avP2PArea > nTimesAboveBaseArea * p2PAreaBase)/nStim(iCh)> minPercAboveTh ; % Is P2P amplitude > than threshold?
        relP2P2PAreaAboveBase = sum(avP2P2PArea > nTimesAboveBaseArea * p2P2PAreaBase)/nStim(iCh)> minPercAboveTh ; % Is P2P amplitude > than threshold?
        
        % percentage above threshold
        perP2PAboveTh = sum(peakToPeakAmp>nStdResponsive)/nStim(iCh)> minPercAboveTh; % Is P2P amplitude > than threshold?
        perP2P2PAboveTh = sum(p2P2PAmp>nStdResponsiveP2P2P)/nStim(iCh)> minPercAboveTh; % Is P2P amplitude > than threshold?
        perMaxMinAmpAboveTh = sum(avPeakMaxMinAmp>nStdResponsiveAmp)/nStim(iCh)> minPercAboveTh; % Is P2P amplitude > than threshold?
        promAboveTh = sum(infoLargestPeak.peakProm > nStdResponsiveAmp)/nStim(iCh)> minPercAboveTh; % Is largest amplitude > than threshold?
        perAmpAboveTh = sum(largestAmp>nStdResponsiveAmp)/nStim(iCh)> minPercAboveTh; % Is  amplitude of first peak > than threshold?
        avAreaAboveTh = sum(infoLargestPeak.peakIntegral>thArea)/nStim(iCh)> minPercAboveTh; % Is AREA > than threshold? - corresponds to large peak
        avP2PAreaAboveTh = sum(infoLargestPeak.peakToPeakIntegral>thP2PArea)/nStim(iCh)> minPercAboveTh; % Is P2P AREA > than threshold? - corresponds to large peak
        avP2P2PAreaAboveTh = sum(infoLargestPeak.peakToPeakToPeakIntegral>thP2P2PArea)/nStim(iCh)> minPercAboveTh; % Is P2P AREA > than threshold? - corresponds to large peak

        % COmparison of amplitude and area for peak, P2P and P2P2P 
        % All we care with this method is that the peak in N2 is larger than threshold 
        %- everything else was kept to have some values in the struct so it does not crash
        if  avLargestAmp >( nStdResponsive * sdBaseline + meanBaseline) % Keller 2011- peak amplitude > 6SD above mean baseline
%         if (firstPeakLocation <= minPeakLocation) && ...
%            (  ((relAmpAboveBase || relAreaAboveBase) && avAreaAboveTh && perAmpAboveTh ) ...
%            || ((relP2PAmpAboveBase || relP2PAreaAboveBase) && avP2PAreaAboveTh && perP2PAboveTh) ...
%            || ((relP2P2PAboveBase || relP2P2PAreaAboveBase) && avP2P2PAreaAboveTh && perP2P2PAboveTh))       
            isChResponsive(iCh)=1;
            lstResponsiveChannel = [lstResponsiveChannel, chNamesSelected(iCh)];
            ampResponsiveCh = [ampResponsiveCh, num2cell(avLargestAmp)];
            ptpResponsiveCh = [ptpResponsiveCh, num2cell(avPeakToPeakAmp)];
            locFirstPeakRespCh = [locFirstPeakRespCh, num2cell(firstPeakLocation)]; %in sec
            locMaxPeakRespCh = [locMaxPeakRespCh, num2cell(maxPeakLocation)]; % in sec
            meanDataPerCh = [meanDataPerCh, mean(data1,2)];
            rmsPerTrial = rms(data1(indTimeStart:indTimeEnd,:));
            rmsDataPerCh = [rmsDataPerCh, num2cell(mean(rmsPerTrial))];
            nPeaksCh = [nPeaksCh, num2cell(mean([allPeaks.nPeaks]))];
            anatRegionsResp = [anatRegionsResp, anatRegionsPerCh(iCh)];
            RASCoordResp = [RASCoordResp, {RASCoordPerCh(iCh,:)}];
            perP2PAboveThCh = [perP2PAboveThCh, num2cell(perP2PAboveTh)];
            areaPerCh = [areaPerCh, num2cell(avArea)];
            areaP2PPerCh = [areaP2PPerCh, num2cell(avP2PArea)];
            p2P2PAmpPerCh = [p2P2PAmpPerCh, num2cell(p2P2PAmp)];
            avProminencePerCh = [avProminencePerCh, num2cell(avProminence)];
            peakMaxMinAmpPerCh = [peakMaxMinAmpPerCh, num2cell(avPeakMaxMinAmp)];
            
            % Relative info
            relAmpPerCh = [relAmpPerCh, num2cell(avLargestAmp/avAmpBase)];
            relP2PPerCh = [relP2PPerCh, num2cell(peakToPeakAmp/peakToPeakAmpBase)];
            relP2P2PPerCh = [relP2P2PPerCh, num2cell(p2P2PAmp/p2P2PAmpBase)];
            relAreaPerCh = [relAreaPerCh, num2cell(avArea/peakAreaBase)];
            relP2PAreaPerCh = [relP2PAreaPerCh, num2cell(avP2PArea/p2PAreaBase)];
            relP2P2PAreaPerCh = [relP2P2PAreaPerCh, num2cell(avP2P2PArea/p2P2PAreaBase)];
            relMaxMinAmpPerCh = [relMaxMinAmpPerCh, num2cell(avPeakMaxMinAmp/peakMaxMinBase)];
           
        end
        
        infoAmpPerCh.peakToPeakAmp(iCh) = avPeakToPeakAmp;
        infoAmpPerCh.avPeakMaxMinAmp(iCh) = avPeakMaxMinAmp;
        infoAmpPerCh.avPeakAreaPerCh(iCh) = avArea;
        % compute also signal amplitude for all channels
        dataEpoch = data1(indTimeStart: indTimeEnd);
        minAmp = min(dataEpoch);
        maxAmp = max(dataEpoch);
        infoAmpPerCh.peakAmp(iCh) = max(abs([minAmp,maxAmp]));
        infoAmpPerCh.dataMaxMinAmp(iCh) = maxAmp-minAmp;
        infoAmpPerCh.area(iCh) = trapz(abs(dataEpoch));
        
        %save some per trial info as well
        dataEpoch = EEGtoAnalyzeAllTrials{iCh}(indTimeStart: indTimeEnd,:);
        minAmp = min(dataEpoch,[],1);
        maxAmp = max(dataEpoch,[],1);
        infoAmpPerChPerTrial.peakAmp{iCh} = max(abs([minAmp;maxAmp]),[],1);
        infoAmpPerChPerTrial.dataMaxMinAmp{iCh} = maxAmp-minAmp;
        infoAmpPerChPerTrial.area{iCh} = trapz(abs(dataEpoch),1);
    else
        infoAmpPerCh.peakToPeakAmp(iCh) = NaN;
        infoAmpPerCh.avPeakMaxMinAmp(iCh) = NaN;
        infoAmpPerCh.avPeakAreaPerCh(iCh) = NaN;
         infoAmpPerCh.peakAmp(iCh) =NaN;
        infoAmpPerCh.dataMaxMinAmp(iCh) =NaN;
        infoAmpPerCh.area(iCh) = NaN;
        infoAmpPerChPerTrial.peakAmp{iCh} =NaN;
        infoAmpPerChPerTrial.dataMaxMinAmp{iCh} = NaN;
        infoAmpPerChPerTrial.area{iCh} = NaN;
    end
    infoAmpPerChPerTrial.nTrials(iCh) = nTrials(iCh);
end

disp([titName,' ',strWhatToUSe,' - Stim Channel: ',stimSiteNames{1}])
disp(['Responsive Channels:'])
disp({'Channel', 'Region', 'MeanAmp','P2PAmp','1stPeakLoc','RMS','nPeaks','%PsP>Th','Area', 'P2PArea','P2P2PAmp','avPeakMaxMinAmp'})
disp([lstResponsiveChannel', anatRegionsResp', ampResponsiveCh', ptpResponsiveCh', locFirstPeakRespCh', rmsDataPerCh', nPeaksCh',perP2PAboveThCh',areaPerCh',areaP2PPerCh', p2P2PAmpPerCh', peakMaxMinAmpPerCh'])
disp(['Relative to Baseline'])
disp({'Channel', 'Region', 'MeanAmp','P2PAmp','P2P2PAmp','MaxPeakLoc','RelAmp','RelP2P','RelP2P2P','RelArea', 'RelP2PArea', 'RelP2P2PArea','RelMaxMinAmpPerCh'})
disp([lstResponsiveChannel', anatRegionsResp', ampResponsiveCh', ptpResponsiveCh', p2P2PAmpPerCh', locMaxPeakRespCh',...
    relAmpPerCh', relP2PPerCh',relP2P2PPerCh',relAreaPerCh',relP2PAreaPerCh',relP2P2PAreaPerCh',relMaxMinAmpPerCh'])


%% Organize in struct
channInfoRespCh.lstResponsiveChannel = lstResponsiveChannel;
channInfoRespCh.ampResponsiveCh = ampResponsiveCh;
channInfoRespCh.ptpResponsiveCh = ptpResponsiveCh;
channInfoRespCh.locFirstPeakRespCh = locFirstPeakRespCh;
channInfoRespCh.locMaxPeakRespCh = locMaxPeakRespCh;
channInfoRespCh.rmsDataPerCh = rmsDataPerCh;
channInfoRespCh.areaPerCh = areaPerCh;
channInfoRespCh.areaP2PPerCh = areaP2PPerCh;
channInfoRespCh.prominencePerCh = avProminencePerCh;
channInfoRespCh.p2P2PAmpPerCh = p2P2PAmpPerCh;
channInfoRespCh.peakMaxMinAmpPerCh = peakMaxMinAmpPerCh;
channInfoRespCh.nPeaksCh = nPeaksCh;
channInfoRespCh.chNamesSelected = chNamesSelected;
channInfoRespCh.chNamesExcluded = chNamesExcluded;
channInfoRespCh.chNamesSelectedOrig = chNamesSelectedOrig;
channInfoRespCh.indExcludedChannels = indExcludedChannels;
channInfoRespCh.isChExcluded = isChExcluded;
channInfoRespCh.isChResponsive = isChResponsive;
channInfoRespCh.stimSiteNames = stimSiteNames;
channInfoRespCh.titName = titName;
channInfoRespCh.whatToUse = whatToUse;
channInfoRespCh.useAverage = useAverage;
channInfoRespCh.tLimitsSec = tLimitsSec;
channInfoRespCh.anatRegionsResp	 = anatRegionsResp;
channInfoRespCh.RASCoordResp = RASCoordResp;
channInfoRespCh.anatRegionsStimCh = anatRegionsStimCh;
channInfoRespCh.RASCoordPerChStimCh = RASCoordPerChStimCh;
channInfoRespCh.anatRegionsPerCh = anatRegionsPerCh;
channInfoRespCh.RASCoordPerCh = RASCoordPerCh;
channInfoRespCh.cfgInfoPlot = cfgInfoPlot;
channInfoRespCh.cfgInfoPeaks = cfgInfoPeaks;
channInfoRespCh.relAmpPerCh = relAmpPerCh;
channInfoRespCh.relMaxMinAmpPerCh = relMaxMinAmpPerCh;
channInfoRespCh.relP2PPerCh = relP2PPerCh;
channInfoRespCh.relP2P2PPerCh = relP2P2PPerCh;
channInfoRespCh.relAreaPerCh = relAreaPerCh;
channInfoRespCh.relP2PAreaPerCh = relP2PAreaPerCh;
channInfoRespCh.relP2P2PAreaPerCh = relP2P2PAreaPerCh;
channInfoRespCh.infoAmpPerCh =infoAmpPerCh;
channInfoRespCh.infoAmpPerChPerTrial = infoAmpPerChPerTrial;

if ~isempty(dirImages) && ~isempty(meanDataPerCh)
    titNameToPlot = regexprep(titName,'_',' ');
    figure('Name', [titNameToPlot,' Stim ',stimSiteNames{1}]);
    hold on;
    plot(timeVals, meanDataPerCh)
    legend(lstResponsiveChannel,'Location','northeastoutside')
    stem([tLimitsSec(1) tLimitsSec(2)],3* ones(2,1),'m')
    title(['\fontsize{10}', titNameToPlot,' Stim ',stimSiteNames{1},' ',strWhatToUSe])
    if ~exist(dirImages,'dir'), mkdir(dirImages); end
    savefig(gcf, [dirImages,filesep,titName,'_',strWhatToUSe,'_StimCh_',stimSiteNames{1}],'compact')
    saveas(gcf,[dirImages,filesep,titName,'_',strWhatToUSe,'_StimCh_',stimSiteNames{1}],'png');
end
