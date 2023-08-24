function [EEGStimTrialMATfile] = AnesthesiaAnalysisFromAINP(fileNameNSx, fileNameStimSites, dirResults, titName, stimChannInfo, indStim, stimAINPChNames, startNSxSec, endNSxSec,excludeTrials,chNamesToExcludeInput, fileNameAudioTaskAnesthesia, indTimeSTIMInput, timeLOCSec)

%Very similar to IEDsAnalysisFromAINP,
% Read tt file to know which ectrode was stimulated each "trial"
% NOTE: it is all in BIPOLAR! perhaps change?
if ~exist('fileNameAudioTaskAnesthesia','var'),fileNameAudioTaskAnesthesia=[]; end
if ~exist('indTimeSTIMInput','var'),indTimeSTIMInput=[]; end
if ~exist('timeLOCSec','var'),timeLOCSec=[]; end % fix the minimum time for LOC - usually obtain in a seprate Spectral analysis - use timeLOCSec=0 to consider ALL file as LOC (e.g. separate files for Anesthesia and WakeOR)

%% Config
tBeforeStimSec = 1.5; %0.5;
tAfterStimSec = 1.5; %0.5;

tBaselineDurationSec = 10;  % Duration Baseline in seconds
tBaselineStartSec = 10;      % start of baseline in sec after start of file or BEFORE stim - 
computeBaselineFrom = 'BEFOREFIRSTSTIM'; %'START'; % 10 sec before first STIM

tBaselineBeforeStimPerTrialSec = [100 600]/1000; %use 500ms up to 100ms before stim as trialbytrial stim time

% tBeforeToInterpolateSec = 4/1000; %4ms before and after as in David 2013
% tAfterToInterpolateSec = 4/1000; %4ms before and after as in David 2013
%trialsUseInBaseline = 1:10;     % do not use all stimulation for baseline CCEP calculation as anesthesia might affect them.

if isfield(stimChannInfo, 'useBipolar')
    useBipolar = stimChannInfo.useBipolar;
else
    useBipolar = 1;   % DEFAULT: use BIPOLAR montage
end
 
% Scalp channels - remove for iEEG - keep at the end of the stim files!
chNamesScalp = {'T1','T2','T3','T4','T5','T6','F3', 'F4', 'F7', 'F8','Fp1','Fp2','Fz', 'Cz','Pz', 'C3', 'C4','P3','P4', 'O1', 'O2', 'A1', 'A2','LOC','ROC','CII'}; % remove scalp electrodes / analyse separately
% Channels to Exclude
chNamesToExcludeDefault = {'ainp','empty','EMG','chan','EKG','SYNC','TRIGGER','IMAGE','DETECT','SHAM','SEND STIM','BLANK'}; % remove AINP,"empty" and EMG channels
chNamesToExcludeDefault = [chNamesToExcludeDefault, cellfun(@num2str,num2cell(34:46),'UniformOutput',false)];
if ~iscell(chNamesToExcludeInput), chNamesToExcludeInput={chNamesToExcludeInput}; end
chNamesToExclude = [chNamesToExcludeDefault, chNamesToExcludeInput]; % remove also scalp - it is saved separately

%minDistanceDet = 500; %Detection time
%pName = strtok(titName,{' ','_'});

if isfield(stimChannInfo, 'useAbsolute')
    useAbsolute = stimChannInfo.useAbsolute;
else
    useAbsolute =0; % DEFAULT: Do NOT rectify signal before processing
end
if isfield(stimChannInfo, 'REMOVESTIM')
    REMOVESTIM = stimChannInfo.REMOVESTIM;
else
    REMOVESTIM =0; % DEFAULT: Do NOT remove STIM artifact
end
if isfield(stimChannInfo, 'FILTERTYPE')
    FILTERTYPE = stimChannInfo.FILTERTYPE;
    if ~iscell(FILTERTYPE) && ~isempty(FILTERTYPE) && isnumeric(FILTERTYPE) && (FILTERTYPE==0), FILTERTYPE=[]; end % compatibility - change to new convention
else
    FILTERTYPE = []; % DEFAULT: Do NOT filter signal - keep it RAW
end
if isfield(stimChannInfo, 'REMOVE60Hz')
    REMOVE60Hz = stimChannInfo.REMOVE60Hz;
else
    REMOVE60Hz =0; % DEFAULT: Do NOT clean signal - keep it RAW
end

if ~isfield(stimChannInfo,'bankInfo')
    stimChannInfo.bankInfo =[];
end

verbose=0;
minDistSTIMPulses= [1000 * ones(1,length(stimAINPChNames))]; % 500ms for STIM and all other pulses


%% Organize inputs
pName = stimChannInfo.pName;
stimNumber1InNSX = stimChannInfo.stimChNumberInNSX(1,indStim);
stimNumber2InNSX = stimChannInfo.stimChNumberInNSX(2,indStim);
stimChNumber1 = stimChannInfo.stimChNumber(1,indStim);
stimChNumber2 = stimChannInfo.stimChNumber(2,indStim);
stimSiteNames = stimChannInfo.stimChNames(:,indStim);
stimSiteNSP = stimChannInfo.NSPnumber(:,indStim);

selChNames = [];% Assume ALL channels
selBipolar = [];% Assume ALL channels
if isfield(stimChannInfo,'recChPerStim')
    selChNames = stimChannInfo.recChPerStim{indStim};
    selBipolar = stimChannInfo.selBipolar{indStim};
elseif isfield(stimChannInfo,'recBipolarChPerStim') % Get info of referential channels from bipolar
    bipChannels = stimChannInfo.recBipolarChPerStim{indStim};
    refCh=cell(1,numel(bipChannels));
    for iCh=1:numel(bipChannels)
        refCh{iCh} = strsplit(bipChannels{iCh},'-');
    end
    selChNames= unique([refCh{:}]);
    for iCh=1:numel(bipChannels)
        selBipolar(iCh,1) = find(strcmpi(refCh{iCh}(1),selChNames));
        selBipolar(iCh,2) = find(strcmpi(refCh{iCh}(2),selChNames));
    end    
end

if ~isfield(stimChannInfo,'isStimInAINP')
    stimChannInfo.isStimInAINP=1; %Default is stim info on AINP (SYNC)
end


%% NSX data
[dataBipolarPerCh, allChNamesBipolar, dataStim, indTimeAllSTIM, dataReferentialPerCh, allChNamesReferential, allChNames, hdr] = GetBipolarEEGFromNSX(fileNameNSx, selChNames, selBipolar, stimAINPChNames, startNSxSec, endNSxSec, verbose, minDistSTIMPulses);
if isempty(indTimeSTIMInput) % in most cases indTimeSTIMInput is empty (only useful when there is NO SYNC)
    if stimChannInfo.isStimInAINP ==1 % whether stim information is on AINP or we should get it from stim artifact on stim channels
        indTimeSTIM = indTimeAllSTIM{1};
    else
        indTimeSTIM = unique([indTimeAllSTIM{:}]); % All instead of first to take into account when no AINp but each - Before:indTimeAllSTIM{1};
    end
else
    indTimeSTIM = indTimeSTIMInput; % use the input as stim information -> useful when NO STIM info in one NSP
end

%nChannels = numel(allChNamesBipolar);
%nDataPts = size(dataBipolarPerCh,1);
indTimeFirstSTIM = indTimeSTIM(1); % keep first stim to compute baseline before THIS time

indTimeSTIM(excludeTrials)=[];
nStim = length(indTimeSTIM);
disp(['Number of NSX Stim: ', num2str(nStim)])
distStimSec=diff([indTimeSTIM])/hdr.Fs;
disp(['Inter Stim interval: ', num2str(mean(distStimSec)),'+/- ',num2str(std(distStimSec))])

%% Decide whether to use Referential or Bipolar data
[dataPerAllCh, chNamesAll] = createIEEGMontage(useBipolar, dataReferentialPerCh, allChNamesReferential);

%% create montage for scalp EEG data if useBipolar =0 -> keep scalp also in referential
if ~useBipolar, stimChannInfo.selScalpMontage= 'Referential'; end
[scalpEEGStimTrials,scalpChNames, stimChannInfo] = createScalpMontage(dataReferentialPerCh, allChNamesReferential, stimChannInfo);
% Add scalp at the end
dataPerAllCh = [dataPerAllCh, scalpEEGStimTrials];
chNamesAll = [chNamesAll, scalpChNames];

%% remove STIM artifact -
if REMOVESTIM
    [dataPerAllCh] = removeStimArtifactCerestim(dataPerAllCh, indTimeSTIM); % removes both the initial stim artifact and the rebound at 10ms
end

%% Filter data -  MUST remove STIM artifact before filtering
if ~isempty(FILTERTYPE) 
    if ~iscell(FILTERTYPE), FILTERTYPE = {FILTERTYPE};end
    for iFilt=1:numel(FILTERTYPE) % to filter HF we need 2 filters: 1. HP to remove stim ERP, 2. BP HF
        dataPerAllCh = filterWithSpecificFilter(dataPerAllCh, FILTERTYPE{iFilt}); % e.g. LP300Hz
    end
end

%% remove Line noise
if REMOVE60Hz
    dataPerAllCh = remove60Hz(dataPerAllCh); % remove 60Hz
end

%% use absolute?
if useAbsolute ==1  % Absolute value
    dataPerAllCh = abs(dataPerAllCh);
end

nAllChannels = size(dataPerAllCh,2);

%% Read File with STIM site per trial
[stimSitesFromLog, stWithStimInfo] = readFileWithSTIMsitesPerTrial(fileNameStimSites);
if isempty(stimSitesFromLog) %if NO file Return empty and then ->USE ALL STIM
    stimSitesFromLog = zeros(length(indTimeSTIM),3);
    stimSitesFromLog(:,1) = 0:length(indTimeSTIM)-1;
    stimSitesFromLog(:,2) = find(strncmpi(allChNames,stimAINPChNames{1},length(stimAINPChNames{1})));
    stimSitesFromLog(:,3) = stimSitesFromLog(:,2) +1; % Assumes consecutive!!
end
nStimFromTXT = size(stimSitesFromLog,1);

%% Check number stim in log and in file are the same
disp(['Number of OR TXT file Stim: ', num2str(nStimFromTXT),' Number of Stim from NSX: ',num2str(nStim)])
if nStimFromTXT > nStim %&& ~strncmpi(stimAINPChNames,allChNames{stimChNumber1},length(stimAINPChNames))
    % Assumption is that Cerestim was disconnected before Auditory/Stim program finished
    disp(['Analyzing only first ', num2str(nStim), ' Stims recorded on TXT file'])
    stimSitesFromLog(nStim+1:end,:)=[];
    nStimFromTXT = size(stimSitesFromLog,1);
elseif nStimFromTXT < nStim
    disp(['Analyzing only first ', num2str(nStimFromTXT), ' Stims - the ones recorded on TXT file'])
    indTimeSTIM(nStimFromTXT+1:end)=[];
    nStim = size(indTimeSTIM,1);
end
 

%% Read Auditory Task information - to find loss of consciousness
stAudioTask=[];
if ~isempty(timeLOCSec)
    firstLossConscTrial = find(indTimeSTIM >= (timeLOCSec)*hdr.Fs, 1); % use the input value for LOC initial time - hdr.startNSxSec
else
    [firstLossConscTrial, ~, ~, stAudioTask] = readAuditoryTaskInfoFromFile(fileNameAudioTaskAnesthesia, [], indTimeSTIM*hdr.Fs);
end

% if we are in anesthesia -> remove all time before LOC
if strncmpi(titName, 'Anest',length('Anest')) && ~isempty(firstLossConscTrial)
    indTimeSTIM(1:firstLossConscTrial)=[];
    stimSitesFromLog(1:firstLossConscTrial,:)=[];
end
% if we are in wakeOR -> remove all time after LOC-1 (as LOC could occur before the first unresponsive trial)
if strncmpi(titName, 'wakeOR',length('wakeOR')) && ~isempty(firstLossConscTrial)
    indTimeSTIM(firstLossConscTrial-1:end)=[];
    stimSitesFromLog(firstLossConscTrial-1:end,:)=[];
end
nStim = length(indTimeSTIM);


%% Organize Stim data to separate different sites of STIM
%Find trials perStim site - ASSUMES UNIQUE FIRST ELECTRODE PER PAIR!!
% and Organize  NSX data per site
allStimSites = unique(stimSitesFromLog(:,2));
if isempty(stimChNumber1) % use all
    stimChNumber1 = allStimSites; %Possible site for electrode 1 (assumes unique)
    stimChNumber2 = allStimSites; %Possible site for electrode 2 (assumes unique)
else
  %check that channel is on TXT file
  if ~ismember(stimChNumber1, allStimSites)
      disp(['Specified STIM channel: ',num2str(stimChNumber1),' not found on TXT file. Exiting'])
      EEGStimTrialMATfile= '';
 %     EEGContinouslMATfile= '';
      return;
      %stimChNumber1 = allStimSites; %Possible site for electrode 1 (assumes unique)
  end
end


disp(['Stimulation sites - from TXT/MAT file'])
disp([stimSiteNames])
if numel(allChNames)>=stimNumber2InNSX
    stimSiteNamesFromNSX{1}  = allChNames{stimNumber1InNSX};
    stimSiteNamesFromNSX{2}  = allChNames{stimNumber2InNSX};
    stimSiteNamesFromNSX = regexprep(stimSiteNamesFromNSX,'\W',''); %remove extra spaces & / and get contacts names
    disp(['Stimulation sites - from NSX'])
    disp([stimSiteNamesFromNSX])
else
        disp(['Stimulation ch number - larger than NSX channels - probably other NSP'])
end
disp(['NOTE: it might not correspond to each other if we are not on the same NSP - it''s ok it is only to check'])


%% Keep only useful channels (remove scalp, bipolar of different shafts, AINPs)
% Asumes only 1 stim site is analysed
iChToAnalyse=1;
dataPerCh = [];%zeros([size(dataPerAllCh,1),1]);
chNamesSelectedWithScalp = [];
for iCh=1:nAllChannels
    contacts = split(chNamesAll{iCh},'-');
    indContactName = regexp(upper(contacts),'[A-Z]','start');
    
    keepChannel =1;
    % Decide if keeping this channel
%     % remove outside of shaft
%     if useBipolar==1  && ((length(contacts)< 2) || (length(indContactName{1})~=length(indContactName{2})) || ~(strcmpi(contacts{1}(indContactName{1}),contacts{2}(indContactName{2})))) % To ONLY consider Bipolar channels within shaft
%         keepChannel=0;
%     end
    % remove stim channels
    if ~isempty(stimSiteNames) && any([strcmpi(contacts, stimSiteNames{1});strcmpi(contacts, stimSiteNames{2})]) % Exclude Stimulation channels
        keepChannel=0;
    end
    % remove specific channels
    for iChExclude=1:numel(chNamesToExclude)
        if  any((strncmpi(contacts, chNamesToExclude{iChExclude},length(chNamesToExclude{iChExclude}))))
            keepChannel=0;
        end
    end
    
    if keepChannel
        dataPerCh(:,iChToAnalyse) = dataPerAllCh(:,iCh);
        chNamesSelectedWithScalp{iChToAnalyse} = chNamesAll{iCh};
        iChToAnalyse =iChToAnalyse+1;
    end
end

nChannels = size(dataPerCh,2);


%% Convert data to Epochs around STIM  - Organize data for Plots
EEGStimTrialsAll=cell(length(stimChNumber1),nChannels);
for iSite=1:length(stimChNumber1)
    indPerSite{iSite} = find(stimSitesFromLog(:,2)==stimChNumber1(iSite));    
    indTimePerStimPerSite{iSite} = indTimeSTIM(indPerSite{iSite});
    [EEGStim, timePerTrialSec] = convertNSXDataToEpochs(dataPerCh, indTimePerStimPerSite{iSite}, tBeforeStimSec, tAfterStimSec, hdr.Fs);
    EEGStimTrialsAll(iSite,:) = EEGStim;
end

%% Compute Baseline as mean of 1min before the very first stim (assuming we are well before Anesthesia starts).
switch upper(computeBaselineFrom)
    case 'START'
        indBaselineStart=  max(1,round(tBaselineStartSec*hdr.Fs));
        indBaselineEnd= min(round((tBaselineStartSec+ tBaselineDurationSec)*hdr.Fs), indTimeFirstSTIM(1)-1);        
    case 'BEFOREFIRSTSTIM'
        indBaselineStart= max(1,round(indTimeFirstSTIM(1)-(tBaselineStartSec+ tBaselineDurationSec)*hdr.Fs));
        indBaselineEnd=   round(indTimeFirstSTIM(1)- tBaselineStartSec*hdr.Fs);
    otherwise
        indBaselineStart=  max(1,round(tBaselineStartSec*hdr.Fs)); %default is from the begining of the file
        indBaselineEnd=  round((tBaselineStartSec+ tBaselineDurationSec)*hdr.Fs);
end
[meanBaseline,  q25, q75, stdBaseline,stdErrorVal,medianVal] = meanQuantiles(dataPerCh(indBaselineStart:indBaselineEnd,:),1);
infoBaseline.meanBaseline=meanBaseline;
infoBaseline.stdBaseline=stdBaseline;
infoBaseline.tBaselineSec=tBaselineStartSec;
infoBaseline.tBaselineDurationSec=tBaselineDurationSec;
infoBaseline.computeBaselineFrom=computeBaselineFrom;
infoBaseline.q25Baseline=q25;
infoBaseline.q75Baseline=q75;
infoBaseline.stdErrorBaseline=stdErrorVal;
infoBaseline.medianBaseline=medianVal;

%Trial per trial Normalization
indBaselinePerTrial = intersect(find(timePerTrialSec <= -tBaselineBeforeStimPerTrialSec(1)),find(timePerTrialSec >= -tBaselineBeforeStimPerTrialSec(2)));
infoBaseline.tBaselinePerTrialStartSec = tBaselineBeforeStimPerTrialSec(1);
infoBaseline.tBaselinePerTrialEndSec = tBaselineBeforeStimPerTrialSec(2);
infoBaseline.indBaselinePerTrial = indBaselinePerTrial;

%%  Z- score Normalization
zNormEEGStim=cell(length(stimChNumber1),nChannels);
perTrialNormEEGStimAll=cell(length(stimChNumber1),nChannels);
zNormZeroMeanEEGStim=cell(length(stimChNumber1),nChannels);
for iSite=1:length(stimChNumber1)
    for iCh=1:nChannels
        allTrialsBaselinePerCh = EEGStimTrialsAll{iSite,iCh}(indBaselinePerTrial,:);
        %       zNormEEGStim{iSite,iCh} = (EEGStimTrials{iSite,iCh} - meanBaseline(iCh)) / stdBaseline(iCh);
        perTrialNormEEGStimAll{iSite,iCh} = (EEGStimTrialsAll{iSite,iCh} - mean(allTrialsBaselinePerCh(:))) ./ std(allTrialsBaselinePerCh(:)) ;
        %       zNormZeroMeanEEGStim{iSite,iCh} = zNormEEGStim{iSite,iCh} -  mean(zNormEEGStim{iSite,iCh}(indBaselinePerTrial,:),1); % remove the mean of the baseline for each trial to bring to zero mean
    end
end

%% separate Scalp from iEEG
indScalpCh=[];
indIEEGCh=[];
for iCh=1:nChannels    % remove scalp channels - keep separate
    contacts = split(chNamesSelectedWithScalp{iCh},'-');
    if any(strcmpi(contacts{1},chNamesScalp)) || any(strcmpi(contacts{2},chNamesScalp))
        indScalpCh = [indScalpCh, iCh];
    else
        indIEEGCh = [indIEEGCh, iCh];
    end
end

% Separate Scalp
[chNamesSelectedScalp, indUniqueScalp] = unique(chNamesSelectedWithScalp(indScalpCh));
% Only keep one per channel (could be repeated if bipolar scalp were in same order as channel list
scalpEEGStimTrials = EEGStimTrialsAll(:,indScalpCh(indUniqueScalp));
scalpPerTrialNormEEGStim = perTrialNormEEGStimAll(:,indScalpCh(indUniqueScalp));

%  from iEEG
EEGStimTrials = EEGStimTrialsAll(:,indIEEGCh);
perTrialNormEEGStim= perTrialNormEEGStimAll(:,indIEEGCh);
chNamesSelected = chNamesSelectedWithScalp(indIEEGCh);
    
%% Save results and organized data
if ~exist(dirResults,'dir'), mkdir(dirResults); end
EEGStimTrialMATfile = [dirResults, filesep, pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],'_bipEEG_StimTrials.mat'];
save(EEGStimTrialMATfile,'EEGStimTrials','zNormEEGStim','perTrialNormEEGStim','zNormZeroMeanEEGStim',...
    'chNamesSelected','allChNamesBipolar','allChNamesReferential','allChNames','stimSiteNames','stimChannInfo','useBipolar','useAbsolute','REMOVESTIM','REMOVE60Hz',...
    'indTimeSTIM','indPerSite','indTimePerStimPerSite','indTimeAllSTIM','stimSitesFromLog','stWithStimInfo','stimSiteNSP',...
    'firstLossConscTrial','timeLOCSec', 'stAudioTask',...
    'chNamesSelectedWithScalp','scalpEEGStimTrials','scalpPerTrialNormEEGStim','chNamesSelectedScalp',...
    'titName','tBeforeStimSec','tAfterStimSec','timePerTrialSec','stimChannInfo','indStim','infoBaseline','meanBaseline','stdBaseline','hdr','pName');

disp([pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],' with ',num2str(length(indTimePerStimPerSite{1})), 'STIM - done!'])
% Save also contiuous data without STIM artifact
% EEGContinouslMATfile = [dirResults, filesep, pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],'_bipEEG_Continuous.mat'];
% save(EEGContinouslMATfile,'noSTimDataPerCh',...
%     'chNamesSelected','allChNamesBipolar','allChNamesReferential','stimSiteNames','stimChannInfo','useBipolar','useAbsolute','REMOVESTIM',...
%     'indTimeSTIM','indPerSite','indTimePerStimPerSite','stimSitesFromLog',...
%     'isAudioResponse','firstLossConscTrial',...
%     'titName','tBeforeStimSec','tAfterStimSec','stimChannInfo','indStim','infoBaseline','tBeforeToInterpolateSec','tAfterToInterpolateSec','chNamesToExclude','hdr','pName');
% 



%% Plot Directly NSX Data - plot bipolar data 
% if ~isempty(dirImages)
dirImages= [dirResults,filesep,'imagesPERTRIAL'];
plotAllCCEPPerElectrode(EEGStimTrialMATfile, dirImages, 'PERTRIAL' )
%     plotAnesthesiaData(EEGStimTrialMATfile, dirImages, titName, 1);
% end


