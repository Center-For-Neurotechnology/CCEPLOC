function [PCIstVal, channInfoPCI] = computePCIperStimChannel(EEGStimTrialMATfile, dirImages, whatToUse,useAverage, indTrialsToExclude, tLimitsSec, channInfo)

% Compute PCI st from (Comolatti et al, Brain Stimulation 2019)
% 
% signal_evk = channels x samples
% times = 1 x samples (in milliseconds)
% parameters = struct (optional) - for more details see nested function

% Usually done for Wake data and then used during anesthesia
if ~exist('indTrialsToExclude','var'),indTrialsToExclude=[]; end
if ~exist('channInfo','var'),channInfo=[]; end

%% Config
minNumberTrials = 5; % at least 5 (before: 10) trials to find peaks!

% PCI parameters 
paramsPCI.baseline =[-700 -100]; %  default -400 to -50 - but in paper -400 to -5
paramsPCI.response =[0 600];  %default 0 300
paramsPCI.k = 1.2;
paramsPCI.min_snr = 1.1;
paramsPCI.max_var =99;
paramsPCI.nsteps = 100;
% paramsPCI.avgref =0;

cfgInfoPCI.tBaselineForZeroMean  =  paramsPCI.baseline/1000; %now same as baseliene segment - before:[-125 100]/1000;% with filter data it has to come before! 100ms before for LP10Hz / 50-25ms for LP45Hz / in original: 25-1 ms right before stim
cfgInfoPCI.paramsPCI = paramsPCI;

disp(['Time to analyse: ',num2str(tLimitsSec(1)),' - ',num2str(tLimitsSec(2)),' sec']);
%disp(['Configuration: nTimesAboveBaseAmp= ', num2str(nTimesAboveBaseAmp),' nStdResponsiveP2P= ', num2str(nStdResponsiveP2P)]);
disp(cfgInfoPCI.paramsPCI);

if isempty(EEGStimTrialMATfile)
    PCIstVal = [];
    channInfoPCI=struct('PCIstVal',[],...
        'chNamesSelected',[],'chNamesExcluded',[],'isChResponsive',[],'stimSiteNames',[],'titName',[],'whatToUse',whatToUse,'useAverage',useAverage,'tLimitsSec',tLimitsSec,...
        'anatRegionsStimCh',cell(0,0),'RASCoordPerChStimCh',cell(0,0),'anatRegionsPerCh',cell(0,0),'RASCoordPerCh',cell(0,0),...
       'cfgInfoPlot',[],'cfgInfoPeaks',cfgInfoPCI);
    return;
end

%% Load Data
stData = load(EEGStimTrialMATfile);
titName = stData.titName;
stimSiteNames = stData.stimSiteNames; %  stim #1 & #2
stimPatChNames =  strcat(stimSiteNames{2},'-',stimSiteNames{1},'_',channInfo.pName);
chNamesSelectedOrig = stData.chNamesSelected;
timeVals = stData.timePerTrialSec;
timeValsMs = timeVals*1000;
Fs = stData.hdr.Fs;

%% Select WHAT to USE in ANALYSIS
EEGtoAnalyze = selectWhatSignalToUse(stData, whatToUse, [], cfgInfoPCI);
strWhatToUSe = whatToUse;

%% Get RAS and Region information
[anatRegionsPerCh, RASCoordPerCh, anatRegionsStimCh, RASCoordPerChStimCh, ~, ~, cfgInfoPlot] = getRegionRASPerChannel(stData);

%% Exclude Channels - e.g. exclude SOZ channels
chNamesSelected = chNamesSelectedOrig;
chNamesExcluded = [];
if ~isempty(channInfo) && isfield(channInfo,'excludedChannels') && ~isempty(channInfo.excludedChannels)
    [chNamesSelected, indExcludedChannels, EEGtoAnalyze] = excludeSpecificChannels(chNamesSelectedOrig, channInfo.excludedChannels, EEGtoAnalyze);
    chNamesExcluded = chNamesSelectedOrig(indExcludedChannels);
    anatRegionsPerCh(indExcludedChannels)=[];
    RASCoordPerCh(indExcludedChannels)=[];
end
nChannels = numel(chNamesSelected);

%% Remove trials to exclude
iKeepCh =[];
for iCh=1:nChannels
    indTrialsToExcPerCh = intersect([1:size(EEGtoAnalyze{iCh},2)], indTrialsToExclude);
    EEGtoAnalyze{iCh}(:,indTrialsToExcPerCh)=[];
    nStimOrig(iCh)= size(EEGtoAnalyze{iCh},2);
    if nStimOrig(iCh)>= minNumberTrials && any(~isnan(EEGtoAnalyze{iCh}(:)))% only STIM channels with at least min number of STIM
        iKeepCh = [iKeepCh,iCh];     % Exclude also channels with few trials
    end
end
nStim=length(iKeepCh);

%% Select if AVERAGE or Trial by trial
if useAverage
    %  case 'AVERAGE'
    EEGforPCI = zeros(nChannels,length(timeVals));
    for iCh=1:nChannels
        EEGforPCI(iCh, :) = mean(EEGtoAnalyze{iCh}, 2,'omitnan'); %now mean - before use  median to remove outliers / mean would give a smooth signal though!
    end
    strWhatToUSe = [strWhatToUSe,' AVERAGED'];
else
    disp('trial by trial not supported for PCI!');
    return;
end

% Keep only those with enough trials
EEGforPCI = EEGforPCI(iKeepCh,:);
chNamesSelected = chNamesSelected(iKeepCh);
anatRegionsPerCh=anatRegionsPerCh(iKeepCh);
RASCoordPerCh=RASCoordPerCh(iKeepCh);

%% Compute PCI
[PCIstVal, dNST, PCAVals, paramsPCI] = PCIst2020(EEGforPCI, timeValsMs, paramsPCI); % version that comptes also PCI for baseline - slower but more robust to noise
%[PCIstVal, dNST,PCAVals, paramsPCI] = PCIst(EEGforPCI, timeValsMs, paramsPCI);

disp([titName,' ',strWhatToUSe,' - Stim Channel: ',stimPatChNames])
disp(['PCI per STIM Channel: ', num2str(PCIstVal),' #PCA components: ',num2str(size(PCAVals,1))])



%% Organize in struct
channInfoPCI.PCIstVals = PCIstVal;
channInfoPCI.PCAVals = PCAVals;
channInfoPCI.dNST = dNST;
channInfoPCI.chNamesSelected = chNamesSelected;
channInfoPCI.stimPatChNames = stimPatChNames;
channInfoPCI.chNamesExcluded = chNamesExcluded;
channInfoPCI.stimSiteNames = stimSiteNames;
channInfoPCI.titName = titName;
channInfoPCI.whatToUse = whatToUse;
channInfoPCI.useAverage = useAverage;
channInfoPCI.tLimitsSec = tLimitsSec;
channInfoPCI.anatRegionsStimCh = anatRegionsStimCh;
channInfoPCI.RASCoordPerChStimCh = RASCoordPerChStimCh;
channInfoPCI.anatRegionsPerCh = anatRegionsPerCh;
channInfoPCI.RASCoordPerCh = RASCoordPerCh;
channInfoPCI.cfgInfoPlot = cfgInfoPlot;
channInfoPCI.cfgInfoPeaks = cfgInfoPCI;
channInfoPCI.paramsPCI = paramsPCI;

if ~isempty(dirImages) && ~isempty(EEGforPCI)
    titNameToPlot = regexprep(titName,'_',' ');
    figure('Name', [titNameToPlot,' Stim ',stimSiteNames{1}]);
    subplot(2,1,1)
    hold on;
    plot(timeVals, EEGforPCI)
    legend(chNamesSelected,'Location','northwest','FontSize',9,'Visible','off')
    legend('hide')
    stem([tLimitsSec(1) tLimitsSec(2)],3* ones(2,1),'m')
    title(['\fontsize{10}', titNameToPlot,' Stim ',stimPatChNames,' ',strWhatToUSe])
    xlabel(['PCI = ',num2str(PCIstVal)])
    ylim([-10 10]);
    subplot(2,1,2)
    hold on;
    plot(timeVals, PCAVals)
    stem([tLimitsSec(1) tLimitsSec(2)],3* ones(2,1),'m')
    xlabel(['nPCA = ',num2str(size(PCAVals,1))])
    ylim([-10 10]);
    if ~exist(dirImages,'dir'), mkdir(dirImages); end
    savefig(gcf, [dirImages,filesep,'PCI_',titName,'_',strWhatToUSe,'_StimCh_',stimPatChNames],'compact')
    saveas(gcf,[dirImages,filesep,'PCI_',titName,'_',strWhatToUSe,'_StimCh_',stimPatChNames],'png');
end
