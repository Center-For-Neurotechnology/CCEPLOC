function [unTrialsWithArtifacts, indChWithProblems, indLargeTrials, stimSiteName] = checkAmplitudeStimResponseIsNeuronal(EEGStimTrialMATfile, dirResults, titName)
% small function to find channels that have large stimulation ari=tifact.
% These channels are likely outside the brain or in CSF.

[onlyPath, onlyFileName] = fileparts(EEGStimTrialMATfile);
if ~exist('dirResults','var')
    dirResults = [onlyPath,filesep,'trialsToExclude'];
end

if ~exist('titName','var'),titName=[]; end
tToAnalyseSec = [0.025 0.6]; % from 25ms up to 600msec after stim

% indSTIMdataPts = 2990:3050;
% indPtsToCheck = [1:2000] + indSTIMdataPts(end); % look for 1 second after STIM (could be improved!)
thMaxAmplitude = 5000;
thMaxAmplitudeZNorm = 20;
thPercLargeTrials = 0.2; % if half the trials are large - It could be a very large response or a channel with problems (e.g. outside the brain)
ignoreSTIMCh = 1; % Whether stim channels are considered separately 

dirImages = [dirResults, filesep, 'images'];
if ~exist(dirImages,'dir'),mkdir(dirImages); end

stEEGStim = load(EEGStimTrialMATfile);
indPtsToCheck = [round(tToAnalyseSec(1)*stEEGStim.hdr.Fs) : round(tToAnalyseSec(2)*stEEGStim.hdr.Fs)]  + find(stEEGStim.timePerTrialSec==0);

chNamesSelected = stEEGStim.chNamesSelected;
EEGStimTrials = stEEGStim.EEGStimTrials;
perTrialNormEEGStim = stEEGStim.perTrialNormEEGStim;
indTimePerStimPerSite = stEEGStim.indTimePerStimPerSite{1};
stimSiteName = [stEEGStim.stimSiteNames{2},'-', stEEGStim.stimSiteNames{1}];
timePerTrialSec =stEEGStim.timePerTrialSec;
allStimChNames = [stEEGStim.stimChannInfo.stimChNames(:)];

nChannels = numel(EEGStimTrials);

if isempty(titName)
    titName = [stEEGStim.titName,' ',stEEGStim.pName,' stim',num2str(stEEGStim.indStim),' ',stimSiteName];
end

% Check which channels are stim channels
isStimCh =zeros(1,nChannels);
isStimShaftCh =zeros(1,nChannels);
unStimElectrodeNames = getElectrodeNames(allStimChNames);
for iCh=1:nChannels 
    contactNames = split(chNamesSelected{iCh},'-');
    if numel(contactNames)==2 % assume it is bipolar - otherwise assume referential
        isStimCh(iCh) = any([strcmpi(contactNames{1}, allStimChNames); strcmpi(contactNames{2}, allStimChNames)]);
    else
        isStimCh(iCh) = any(strcmpi(contactNames{1}, allStimChNames));
    end
    % it is wihtin the same shaft - also ignore as stim response tends to be bigger  - CSF build up related??
    isStimShaftCh(iCh) =  any(strcmp(getElectrodeNames({stimSiteName}), getElectrodeNames(chNamesSelected(iCh))));
end

% Check for channels with large max amplitude
indChWithLargeResp=[];
indLargeTrials = cell(nChannels,1);
maxAmpEEGPerCh = zeros(1,nChannels);
maxAmpPerTrialPerCh = zeros(1,nChannels);

for iCh=1:nChannels 
    if ~isempty(EEGStimTrials{iCh})
        maxAmpEEGPerCh(iCh) = max(max(abs(EEGStimTrials{iCh}(indPtsToCheck,:))));
        maxAmpPerTrialPerCh(iCh) = max(max(abs(perTrialNormEEGStim{iCh}(indPtsToCheck,:))));
        if  (maxAmpPerTrialPerCh(iCh) > thMaxAmplitudeZNorm)|| (maxAmpEEGPerCh(iCh) > thMaxAmplitude) % look at zScore and amplitude
            indChWithLargeResp =[indChWithLargeResp, iCh];
            indLargeTrialsPerTrial = find(max(abs(perTrialNormEEGStim{iCh}(indPtsToCheck,:)))>thMaxAmplitudeZNorm);
            indLargeTrialsRawEEG = find(max(abs(EEGStimTrials{iCh}(indPtsToCheck,:)))>thMaxAmplitude);
            indLargeTrials{iCh} = unique([indLargeTrialsPerTrial, indLargeTrialsRawEEG]);
        end
    else
        indChWithLargeResp =[indChWithLargeResp, iCh];
    end
end
unLargeTrials = unique([indLargeTrials{:}]);
nLargeTrials = histc([indLargeTrials{:}], unLargeTrials);
disp(['Trials with many channels: ',titName])
disp(['#Trial ','nChannels'])
disp([num2cell(unLargeTrials)', num2cell(nLargeTrials)'])
disp('************************')
indChWithFewArtifacts=[];indChWithProblems=[];
unTrialsWithArtifacts=[];
for iCh=1:length(indChWithLargeResp)
    indCh = indChWithLargeResp(iCh);
    percLargeTrialsPerCh(iCh) = length([indLargeTrials{indCh}])/size(EEGStimTrials{iCh},2);
    disp([titName,' ch#', num2str(indCh),' ',chNamesSelected{indCh}, ' %Trials= ',num2str(percLargeTrialsPerCh(iCh)),' maxAmp= ',num2str(maxAmpEEGPerCh(indCh)),' perTrailMaxAmp= ', num2str(maxAmpPerTrialPerCh(indCh)), ' inTrials=',num2str([indLargeTrials{indCh}])])
    % Separate channels with large trials due to large response (likely in most trials) and due to  individual artifacts
    if percLargeTrialsPerCh(iCh)>= thPercLargeTrials % large response if a lot of trials are large
        indChWithProblems = [indChWithProblems, indCh];
    elseif ~ignoreSTIMCh || (ignoreSTIMCh && ~isStimCh(indCh) && ~isStimShaftCh(indCh)) %otherwise is likely an artifact and should be removed (unlless is a stim channel - then it might be stim ralying removed separately)
        indChWithFewArtifacts = [indChWithFewArtifacts, indCh];
        unTrialsWithArtifacts = unique([unTrialsWithArtifacts,indLargeTrials{indCh}]);
    end
end
disp(['All Stim channels: ',allStimChNames'])
disp(['Trials to Exclude: ',num2str(unTrialsWithArtifacts)])


%% Plot
figure('Name',titName);
subplot(2,1,1);
plot(maxAmpEEGPerCh)
title(titName)
ax2=subplot(2,1,2);
plot(maxAmpPerTrialPerCh)
xticks(1:length(maxAmpPerTrialPerCh))
xticklabels(chNamesSelected)
xtickangle(60)
ax2.FontSize = 7;
saveFigToExt(gcf,dirImages, [regexprep(titName,' ','_')],'png');


%Plot indivdual channels with more than 750 max amplitude / 50 zcore
nSubPlots = ceil(sqrt(length(indChWithLargeResp)));
scrsz = get(groot,'ScreenSize');
if ~isempty(indChWithLargeResp)
    figure('Name',[titName,' largeCh'], 'Position',[1 1 scrsz(3) scrsz(4)]);
    for iCh=1:length(indChWithLargeResp)
        indCh = indChWithLargeResp(iCh);
        subplot(nSubPlots,nSubPlots,iCh)
        hold on;
        if ~isempty(EEGStimTrials{indCh})
            plot(timePerTrialSec, detrend(EEGStimTrials{indCh}),'b');
            plot(timePerTrialSec, detrend(EEGStimTrials{indCh}(:,indLargeTrials{indCh})),'r');
        end
        plot(timePerTrialSec, median(detrend(EEGStimTrials{indCh}),2),'k','LineWidth',3)
        title([chNamesSelected{indCh},' ',num2str(isStimCh(iCh))])
        xlim([-1 1])
    end
    saveFigToExt(gcf,dirImages, [regexprep(titName,' ','_'),'_largeCh'],'png');
    savefig(gcf,[dirImages, filesep,regexprep(titName,' ','_'),'_largeCh'],'compact');
end

%% Save
if ~exist(dirResults,'dir'),mkdir(dirResults);end
save([dirResults,filesep,'checkAmplitudes_',titName,'.mat'],'unLargeTrials','indChWithProblems','indLargeTrials','thMaxAmplitudeZNorm','thMaxAmplitude',...
    'indChWithLargeResp','indChWithFewArtifacts','unTrialsWithArtifacts','isStimCh','thPercLargeTrials','thMaxAmplitudeZNorm','ignoreSTIMCh',...
    'tToAnalyseSec','maxAmpPerTrialPerCh','maxAmpEEGPerCh','chNamesSelected','titName','EEGStimTrialMATfile','stimSiteName'); %'EEGStimTrials','perTrialNormEEGStim',

% save only trials to remove - to have separate small files with the relevant info 
save([dirResults, filesep, onlyFileName,'_TrialsToExcludeLargeAmp','.mat'],...
            'unLargeTrials','indChWithProblems','indLargeTrials','thMaxAmplitudeZNorm','thMaxAmplitude',...
            'indChWithLargeResp','indChWithFewArtifacts','unTrialsWithArtifacts','isStimCh','thPercLargeTrials','thMaxAmplitudeZNorm','ignoreSTIMCh',...
            'tToAnalyseSec','chNamesSelected','titName','EEGStimTrialMATfile','stimSiteName');

