function fileNameProgResults = analyzeSTIMArtifact(fileNameNSxPerNSP, fileNameStimSites, dirResults, channInfo, titName, trialsToExclude)

%% CONFIG
tIntervalSec{1} = [5 50]/1000;
%tIntervalSec{2} = [50 250]/1000;
%tIntervalSec{3} = [250 1000]/1000;
%tIntervalSec{2} = [1000 5000]/1000;
tIntervalSec{2} = [5 8000]/1000;
tBeforeStimSec = 1; %0.5;
tAfterStimSec = 10; %5;
tRemoveSTIMArtifactSec = [-5 5]/1000; % Remove 5ms around STIM

cfgStats.dirImages = [dirResults,filesep,'images'];
if ~exist(cfgStats.dirImages,'dir'), mkdir(cfgStats.dirImages); end

if ~exist('trialsToExclude','var'),trialsToExclude=[];end

%% Get EEG data from STIM channels
[fileNameStimSitesWNSXinfo,dataBipolarPerCh, chNamesBipolar, indTimeSTIMAll,allChNames, hdr] = scriptCheckStimInNSX(fileNameNSxPerNSP, fileNameStimSites, dirResults, channInfo.stimAINPChNames, channInfo, titName);
if ~isempty(trialsToExclude)
    for iNSP=1:numel(indTimeSTIMAll)
        indTimeSTIMAll{iNSP}(trialsToExclude)=[];
    end
end
cfgStats.Fs = hdr.Fs;

%% Plot Continuous data
    % Plot each channel in a searate subplot
scrsz = get(groot,'ScreenSize');
figure('Position',[1 1 scrsz(3)/2 scrsz(4)],'Name',titName)
suptitle('EEG STIM Channels')
nChannels = length(unique(channInfo.stimChNames(1,:)));
for iNSP=1:numel(dataBipolarPerCh)
    for iCh=1:size(dataBipolarPerCh{iNSP},2)
        subplot(nChannels, 1, iCh+size(dataBipolarPerCh,2)*(iNSP-1))
        plot([1:size(dataBipolarPerCh{iNSP},1)]*1/hdr.Fs , dataBipolarPerCh{iNSP}(:,iCh));
        ylabel(chNamesBipolar{iNSP}{iCh})
        xticklabels({})
    end
end
xticklabels('auto');
xlabel('Time (sec)')
savefig(gcf,[cfgStats.dirImages, filesep,'EEG_STIMChannels_',titName,'.fig'],'compact');
saveas(gcf,[cfgStats.dirImages, filesep,'EEG_STIMChannels_',titName,'.png']);

%% Divide in trials (reduced version from AnesthesiaAnalysis)
if ~isempty(strfind(lower(fileNameStimSites),'.txt'))
    [stimSitesFromLog] = readStimSiteFromTxtFile(fileNameStimSites);
elseif ~isempty(strfind(lower(fileNameStimSites),'.mat')) %assumes .mat file
    stStimSites = load(fileNameStimSites);
    stimSitesFromLog = stStimSites.stimchans;
    stimSitesFromLog = [[0:(size(stimSitesFromLog,1)-1)]',stimSitesFromLog];
end

chNamesBipolarAll=cell(1,nChannels);
EEGStimTrialsAllCh=cell(1,nChannels);
nChTotal=1;
for iNSP=1:numel(dataBipolarPerCh)
    for iCh=1:size(dataBipolarPerCh{iNSP},2)
        chNameRef = split(chNamesBipolar{iNSP}{iCh},'-');
        % Detrend data and compute abs to find ALL peaks ?
        dataPerCh = dataBipolarPerCh{iNSP}(:,iCh);% abs(EEGAnesthesia{iCh}(:,trialsAnesthesia));
        indSTIMCh = find(strcmpi(channInfo.stimChNames(1,:),chNameRef{1}),1);
        indPerSite = find(stimSitesFromLog(:,2)==channInfo.stimChNumber(1,indSTIMCh));
        indPerSite(indPerSite>length(indTimeSTIMAll{iNSP}))=[]; % remove those not in eeg files
        indTimePerStimPerSite = indTimeSTIMAll{iNSP}(indPerSite);
        [EEGStim, timePerTrialSec] = convertNSXDataToEpochs(dataPerCh, indTimePerStimPerSite, tBeforeStimSec, tAfterStimSec, hdr.Fs);
        EEGStimTrialsAllCh(nChTotal) = EEGStim;
        chNamesBipolarAll{nChTotal} = chNamesBipolar{iNSP}{iCh};
        nChTotal = nChTotal +1;
    end
end
cfgStats.indStim = find(timePerTrialSec>=0,1); 

%% Plot per trial
figure('Position',[1 1 scrsz(3)/2 scrsz(4)],'Name',titName)
suptitle('Time to settle back')
for iCh=1:numel(EEGStimTrialsAllCh)
    subplot(nChannels, 1, iCh)
    imagesc(timePerTrialSec,1:size(EEGStimTrialsAllCh{iCh},2),EEGStimTrialsAllCh{iCh}')
    ylabel(chNamesBipolarAll{iCh})
%    legend(strcat(chNamesBipolar{1},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
    xticklabels({})
end
xticklabels('auto');
xlabel('Time (sec)')
savefig(gcf,[cfgStats.dirImages, filesep,'PerTrialSTIM_',titName,'.fig'],'compact');
saveas(gcf,[cfgStats.dirImages, filesep,'PerTrialSTIM_',titName,'.png']);

%% Plot per trial contiously removing STIM artifact
tRemoveSTIMArtifactSamp = tRemoveSTIMArtifactSec * hdr.Fs + find(timePerTrialSec>0,1) ;
indKeepSamples = [1:tRemoveSTIMArtifactSamp(1),tRemoveSTIMArtifactSamp(2):length(timePerTrialSec)];
figure('Position',[1 1 scrsz(3)/2 scrsz(4)],'Name',titName)
suptitle('STIM trials - No Artifact')
for iCh=1:numel(EEGStimTrialsAllCh)
    subplot(nChannels, 1, iCh)
    contEEG = EEGStimTrialsAllCh{iCh}(indKeepSamples,:);
    plot(contEEG(:))
    ylabel(chNamesBipolarAll{iCh})
%    legend(strcat(chNamesBipolar{1},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
    xticklabels({})
    grid on;
end
xticklabels('auto');
xlabel('Time (samples)')

savefig(gcf,[cfgStats.dirImages, filesep,'ContTrialsSTIM_',titName,'.fig'],'compact');
saveas(gcf,[cfgStats.dirImages, filesep,'ContTrialsSTIM_',titName,'.png']);

%% Let's plot the first and the last STIM
figure('Position',[1 1 scrsz(3)/2 scrsz(4)],'Name',titName)
suptitle('First-Last STIM trials')
nTrials=3;
for iCh=1:numel(EEGStimTrialsAllCh)
    subplot(nChannels, 1, iCh)
    if size(EEGStimTrialsAllCh{iCh},2)>=nTrials
        firstEEG = EEGStimTrialsAllCh{iCh}(:,1:nTrials);
        lastEEG = EEGStimTrialsAllCh{iCh}(:,end-nTrials+1:end);
        contEEG = [firstEEG(:), lastEEG(:)];
        plot(contEEG(:))
        hold on;
        line([size(contEEG,1),size(contEEG,1)],[min(contEEG(:)),max(contEEG(:))],'Color','m')
        ylabel(chNamesBipolarAll{iCh})
        %    legend(strcat(chNamesBipolar{1},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
        xticklabels({})
        grid on;
    end
end
xticklabels('auto');
xlabel('Time (samples)')

savefig(gcf,[cfgStats.dirImages, filesep,'FirstLastSTIM_',titName,'.fig'],'compact');
saveas(gcf,[cfgStats.dirImages, filesep,'FirstLastSTIM_',titName,'.png']);


%% Plot Waterfall of stim data
% cfgInfoPlot.xlimZoomMiliSec = [-10 250];
% cfgInfoPlot.xTimeForYlim = [3 100]/1000; % in seconds
% cfgInfoPlot.indXTimeForYlim = cfgInfoPlot.xTimeForYlim * hdr.Fs + find(timePerTrialSec>=0,1);
for iCh=1:nChannels
    % Get Ch name and EEG data
    chName = regexprep(chNamesBipolarAll{iCh},'\W',''); %remove extra spaces & / and get contacts names
    EEGtoPlotPerCh = EEGStimTrialsAllCh{iCh};
    %  data must be in format: time x ntrials x channels matrix
    plotWaterFall(EEGtoPlotPerCh, timePerTrialSec, chName, titName, cfgStats.dirImages, []);
end

%% Progression Analysis
for iCh=1:numel(EEGStimTrialsAllCh)
    chName = chNamesBipolarAll{iCh};
    for iT=1:numel(tIntervalSec)
        cfgStats.peakType = ['t',num2str(tIntervalSec{iT}(:)')];
        disp(['Interval ',cfgStats.peakType,' - Progression ',titName,' channel: ',chName]);
        cfgStats.titName = [titName,cfgStats.peakType,chName];
        [pVals{iCh}, rhoVals{iCh}, infoPeak, depLabels] = progressionPeaks(EEGStimTrialsAllCh{iCh}, tIntervalSec{iT}, cfgStats);
        infoPeaksPerCh{iCh,iT}.infoPeak =infoPeak;
        infoPeaksPerCh{iCh,iT}.chName = chName;
        infoPeaksPerCh{iCh,iT}.pVals = pVals{iCh};
        infoPeaksPerCh{iCh,iT}.rhoVals = rhoVals{iCh};
        infoPeaksPerCh{iCh,iT}.depLabels = depLabels;
    end
    close all;
end
%% Save Progression
cfgStats.titName = titName;
cfgStats.sheetName = cfgStats.titName;
cfgStats.tIntervalSec =tIntervalSec;
cfgStats.tRemoveSTIMArtifactSec =tRemoveSTIMArtifactSec;
fileNameProgResults = [dirResults,filesep,'ProgArtifactResp_',titName,'.mat'];
save(fileNameProgResults,'infoPeaksPerCh','chNamesBipolarAll','EEGStimTrialsAllCh','cfgStats','channInfo','fileNameNSxPerNSP', 'fileNameStimSites')


