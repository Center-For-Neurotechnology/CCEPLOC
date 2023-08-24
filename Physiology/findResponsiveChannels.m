function [lstResponsiveChannel, channInfoRespCh] = findResponsiveChannels(EEGStimTrialMATfile, dirImages, whatToUse,useAverage, indTrialsToExclude, tLimitsSec)

% Responsive channels are channels were mean N1 peak is at least 3 std above baseline
% Usually done for Wake data and then used during anesthesia
if ~exist('indTrialsToExclude','var'),indTrialsToExclude=[]; end

%Config
minNumberTrials = 10; % at least 10 trials to find peaks!
nStdResponsiveP2P = 4; %2.576;  %2.576=99% / 2.33=98% / 1.96~2=95%
nStdResponsiveP2P2P = 8; %nStdResponsiveP2P*2;
nStdResponsiveAmp = 4; %nStdResponsiveP2P*2; % 5;
thArea = 600; % Area = Width (samples) x prominence (zScore). E.g. if prominence (similar to p2p amp) is 4 -> it has to be 75ms long - this allows finding wide but short peaks
thP2PArea = 800; % Area = Width (samples) x prominence (zScore). E.g. if prominence (similar to p2p amp) is 4 -> it has to be 100ms long - this allows finding wide but short peaks
minPercAboveTh = 0.75; %at least 75% of the trials MUST be above nStdResponsiveP2P threshold
%nMaxPeaks = 10; %if more than 10 peaks, assume it is too noisy

cfgInfoPeaks.nStdResponsiveP2P = nStdResponsiveP2P;
cfgInfoPeaks.nStdResponsiveAmp = nStdResponsiveAmp;
cfgInfoPeaks.minPercAboveTh = minPercAboveTh;

cfgInfoPeaks.minPeakProminence = 1; %0.1;0.3; %
cfgInfoPeaks.minPeakWidth= 10; % in samples(5ms)- BEfore: 20samplesto avoid detecting 60Hz noise (17 ms period /2 for half sine)
cfgInfoPeaks.minPeakDistance= 40; % =20ms: to be larger than 60Hz noise (17ms) - in samples (before: 10ms)
cfgInfoPeaks.tBaselineForZeroMean  =  -[26 1]/1000;% 25 ms right before stim
cfgInfoPeaks.extraSamplesForPeakDet = [20 100]; % added time for detection of peaks (peak through must be within tLimitsSec, but we add some extra samples to get the full peak info)

disp(['Time to analyse: ',num2str(tLimitsSec(1)),' - ',num2str(tLimitsSec(2)),' sec']);
if isempty(EEGStimTrialMATfile)
    lstResponsiveChannel=cell(1,0);
    channInfoRespCh=struct('lstResponsiveChannel',cell(0,0),'ampResponsiveCh',cell(0,0),'ptpResponsiveCh',cell(0,0),'locResponsiveCh',cell(0,0),'rmsDataPerCh',cell(0,0),'prominencePerCh',cell(0,0),'nPeaksCh',cell(0,0),...
        'chNamesSelected',[],'isChResponsive',[],'stimSiteNames',[],'titName',[],'whatToUse',whatToUse,'useAverage',useAverage,'tLimitsSec',tLimitsSec,...
        'anatRegionsResp',cell(0,0),'RASCoordResp',cell(0,0),'anatRegionsStimCh',cell(0,0),'RASCoordPerChStimCh',cell(0,0),'anatRegionsPerCh',cell(0,0),'RASCoordPerCh',cell(0,0),...
        'avPeakToPeakAmpPerCh',[],'p2P2PAmpPerCh',cell(0,0),'cfgInfoPlot',[],'cfgInfoPeaks',cfgInfoPeaks);
    return;
end
% Load Data
stData = load(EEGStimTrialMATfile);
titName = stData.titName;
stimSiteNames = stData.stimSiteNames; %  stim #1 & #2
    % stimSiteNames{2} = % before We were missing stim #2: strcat(stimSiteNames{1}(1:end-1),num2str(str2num(stimSiteNames{1}(end))+1)); % BAD HACK: add next channel as 2nd STIM channel!!

chNamesSelected = stData.chNamesSelected;
nChannels = numel(chNamesSelected);
timeVals = stData.timePerTrialSec;
Fs = stData.hdr.Fs;

%% Select WHAT to USE in ANALYSIS
EEGtoAnalyze = selectWhatSignalToUse(stData, whatToUse, [], cfgInfoPeaks);
strWhatToUSe = whatToUse;

%% Remove trials to exclude
for iCh=1:nChannels
    indTrialsToExcPerCh = intersect([1:size(EEGtoAnalyze{iCh},2)], indTrialsToExclude);
    EEGtoAnalyze{iCh}(:,indTrialsToExcPerCh)=[];
    nStimOrig(iCh)= size(EEGtoAnalyze{iCh},2);
end
nStim=nStimOrig;

%% Select if AVERAGE or Trial by trial
if useAverage
    %  case 'AVERAGE'
    for iCh=1:nChannels
        EEGtoAnalyze{iCh} = median(EEGtoAnalyze{iCh}, 2); %use  median to remove outliers / mean would give a smooth signal though!
    end
    nStim = ones(1,nChannels); % since we are averaging all the responses - it is as if there was only 1 stim
    strWhatToUSe = [strWhatToUSe,' AVERAGED'];
end

%% Get RAS and Region information
[anatRegionsPerCh, RASCoordPerCh, anatRegionsStimCh, RASCoordPerChStimCh, ~, ~, cfgInfoPlot] = getRegionRASPerChannel(stData);

%% find peaks
indStim = find(timeVals>=0,1); 
indTimeStart = round(tLimitsSec(1)*Fs + indStim); % detect all peaks from 5ms to 200ms after stim
indTimeEnd = round(tLimitsSec(2)*Fs + indStim);

lstResponsiveChannel=cell(1,0);
ampResponsiveCh=cell(1,0);
ptpResponsiveCh=cell(1,0);
locResponsiveCh=cell(1,0);
isChResponsive = zeros(1,nChannels);
meanDataPerCh=[];
rmsDataPerCh=cell(1,0);
nPeaksCh=cell(1,0);
anatRegionsResp=cell(1,0);
RASCoordResp=cell(1,0);
avPeakToPeakAmpPerCh=zeros(1,nChannels);
perP2PAboveThCh=cell(1,0);
areaPerCh=cell(1,0);
areaP2PPerCh=cell(1,0);
p2P2PAmpPerCh=cell(1,0);
avProminencePerCh=cell(1,0);
for iCh=1:nChannels
    if nStimOrig(iCh)> minNumberTrials
        data1 = squeeze(EEGtoAnalyze{iCh});
        [infoFirstPeak, infoAllPeaks, infoLargestPeak] = getPosNegPeaks(data1, indTimeStart, indTimeEnd, cfgInfoPeaks);
        avAmp = sum(abs([infoFirstPeak.peakAmp]))/nStim(iCh);
        peakToPeakAmp = abs([infoLargestPeak.peakToPeakAmp]);   % p2p to consider typical CCEP
        p2P2PAmp = abs([infoLargestPeak.p2P2PAmp]);             % p2p2p to consider W type of shape
        largestAmp = abs([infoLargestPeak.peakAmp]);            % Max amplitude to consider long lasting CCEP -  ^ shape
        avPeakToPeakAmp = sum(peakToPeakAmp)/nStim(iCh); % if peak no found consider it as 0 in zscore
        avLargestAmp = sum(largestAmp)/nStim(iCh); % if peak no found consider it as 0 in zscore
        allPeaks = [infoAllPeaks{:}];
        avPeakToPeakAmpPerCh(iCh) = avPeakToPeakAmp;
        avP2PArea = sum(abs([infoLargestPeak.peakToPeakIntegral]))/nStim(iCh);
        avProminence = infoLargestPeak.peakProm /nStim(iCh); % Prominince of the largest peak
        
        perP2PAboveTh = sum(peakToPeakAmp>nStdResponsiveP2P)/nStim(iCh); % Is P2P amplitude > than threshold?
        perP2P2PAboveTh = sum(p2P2PAmp>nStdResponsiveP2P2P)/nStim(iCh); % Is P2P amplitude > than threshold?
        promAboveTh = sum(infoLargestPeak.peakProm > nStdResponsiveAmp)/nStim(iCh); % Is largest amplitude > than threshold?
        perAmpAboveTh = sum(largestAmp>nStdResponsiveAmp)/nStim(iCh); % Is largest amplitude > than threshold?
        avArea = sum(infoLargestPeak.peakIntegral)/nStim(iCh); % Is AREA > than threshold? - corresponds to large peak
        avAreaAboveTh = sum(infoLargestPeak.peakIntegral>thArea)/nStim(iCh); % Is AREA > than threshold? - corresponds to large peak
        avP2PAreaAboveTh = sum(infoLargestPeak.peakToPeakIntegral>thP2PArea)/nStim(iCh); % Is P2P AREA > than threshold? - corresponds to large peak
        if perP2PAboveTh > minPercAboveTh || perP2P2PAboveTh > minPercAboveTh || avAreaAboveTh > minPercAboveTh || avP2PAreaAboveTh > minPercAboveTh
            % if perP2PAboveTh > minPercAboveTh || perP2P2PAboveTh > minPercAboveTh || perAmpAboveTh > minPercAboveTh || promAboveTh > minPercAboveTh
            %if avPeakToPeakAmp>nStdResponsiveP2P || avAmp>nStdResponsiveAmp %&& mean([allPeaks.nPeaks])< nMaxPeaks % Checks for peak to peak amplitude and  assumes that if a lot of peaks, it is likely too noisy
            isChResponsive(iCh)=1;
            lstResponsiveChannel = [lstResponsiveChannel, chNamesSelected(iCh)];
            ampResponsiveCh = [ampResponsiveCh, num2cell(avLargestAmp)];
            ptpResponsiveCh = [ptpResponsiveCh, num2cell(avPeakToPeakAmp)];
            locResponsiveCh = [locResponsiveCh, num2cell(1000*timeVals(round(mean([infoLargestPeak.peakLoc],'omitnan'))))]; %in samples - thus the round -> then in sec
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
            
        end
    end
end
disp([titName,' ',strWhatToUSe,' - Stim Channel: ',stimSiteNames{1}])
disp(['Responsive Channels:'])
disp({'Channel', 'Region', 'Mean Amp.','P2P Amp.','PeakLoc.','RMS','nPeaks','%PsP>Th','Area', 'P2P Area','P2P2P Amp.','Prom'})
disp([lstResponsiveChannel', anatRegionsResp', ampResponsiveCh', ptpResponsiveCh', locResponsiveCh', rmsDataPerCh', nPeaksCh',perP2PAboveThCh',areaPerCh',areaP2PPerCh', p2P2PAmpPerCh', avProminencePerCh'])


%% Organize in struct
channInfoRespCh.lstResponsiveChannel = lstResponsiveChannel;
channInfoRespCh.ampResponsiveCh = ampResponsiveCh;
channInfoRespCh.ptpResponsiveCh = ptpResponsiveCh;
channInfoRespCh.locResponsiveCh = locResponsiveCh;
channInfoRespCh.rmsDataPerCh = rmsDataPerCh;
channInfoRespCh.prominencePerCh = areaPerCh;
channInfoRespCh.p2P2PAmpPerCh = p2P2PAmpPerCh;
channInfoRespCh.nPeaksCh = nPeaksCh;
channInfoRespCh.chNamesSelected = chNamesSelected;
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
channInfoRespCh.avPeakToPeakAmpPerCh = avPeakToPeakAmpPerCh;

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
