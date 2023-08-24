function script_PooledComparisonAnesthesia_RespKeller2011(dirGral, pNames, posFixDir, channInfoInput, strDate)

%posFixDir = '_LOCCCEP'; %'_raw'; 

%% GENERAL CONFIG
if ~exist('channInfoInput','var'), channInfoInput=[]; end %if excludedChannelsSOZ -> remove STIM SOZ channels from analysis
if ~exist('strDate','var'), strDate=date; end

whatToUseRespCh =  'PERTRIALKeller';%'PERTRIALnonSOZMEDIAN'; %'PERTRIAL_Clean20'; %'PERTRIAL_Strict3';%'ZEROMEANZNORM'; %;
stateNames = {'WakeEMU', 'Sleep', 'WakeOR', 'Anesthesia'};
timeIntervalMs = [0 600]; % [50 500]; %[tN1(1) tN2(2)]; %
timeIntervalMsResp =  [50 500]; %[0 600]; %[tN1(1) tN2(2)]; %

cfgStats.minNumberRespCh = 5; %  minimum number of responsive channels in ANY state
cfgStats.titName = '';

cfgStats.useParam = 0; % 0=non parametric / 1=ttest - no reason to expect normal distribution for PCI or Resp - changed for Variability
cfgStats.trialsAnesthesia = 20; %15;
cfgStats.trialsWakeOR = 20; %15;
cfgStats.trialsWakeEMU = 20; %15;
cfgStats.trialsSleep = 20; %15;
cfgStats.tBaselineForZeroMean  =  -[50 25]/1000;

cfgInfoPeaks.tCCEPAmp = [5 250]/1000; % time (sec) to compute CCEP amplitude AFTER stimulation
cfgInfoPeaks.tBaselineCCEPAmp = [10 100]/1000; % time (sec) to compute Baseline CCEP amplitude BEFORE stimulation
cfgInfoPeaks.tN1 = [5 60]/1000; % time (sec) to compute N1 peak amplitude
cfgInfoPeaks.tN2 = [50 250]/1000; % time (sec) to compute N1 peak amplitude
cfgInfoPeaks.tLong = [200 1000]/1000; % time (sec) to compute N1 peak amplitude
cfgInfoPeaks.CCEP = [5 600]/1000; % time (sec) to compute the same as for PCI and Resp channels
cfgInfoPeaks.tBaseline = -[500 50]/1000; % as in keller 2011  / original: -[600 100]/1000; %  per trial - in sec before - USED on Variability calculation!
cfgInfoPeaks.minNumberTrials = 5;

originalDir = dirGral; 
thisPCDir = dirGral; 


%% ************** RESPONSIVE CHANNELS *********************
tLimitsSec = timeIntervalMs/1000; %[10 600]/1000; %[tN1(1) tN2(2)]; %
tLimitsSecResp = timeIntervalMsResp/1000; %[10 600]/1000; %[tN1(1) tN2(2)]; %
strtLimitsSec = strcat(num2str(tLimitsSecResp(1)),'_',num2str(tLimitsSecResp(2)));

%% Files and Directories
nPatients = length(pNames);
fileNamesPerState.Anesthesia= cell(1,nPatients);
fileNamesPerState.WakeOR= cell(1,nPatients); 
fileNamesPerState.WakeEMU= cell(1,nPatients); 
fileNamesPerState.Sleep= cell(1,nPatients); 
for iP=1:nPatients
    pName = pNames{iP};
    dirData =  [thisPCDir, filesep, pName, filesep, 'ResultsAnalysisAllCh',posFixDir]; 
    fileNameMATfiles = [dirData,filesep,'dataPerStimAllChannels_',pName,'_Clean','.mat'];
    %Files
    [fileNamesPerState.Anesthesia{iP}, fileNamesPerState.WakeOR{iP}, fileNamesPerState.WakeEMU{iP}, fileNamesPerState.Sleep{iP}] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameMATfiles,originalDir,thisPCDir);
end

dirGralResults = [dirGral, filesep, 'AnesthesiaAnalysis', filesep, num2str(length(pNames)),'pat_', strDate, filesep,cfgStats.titName, posFixDir,'KellerDet'];%

%% Get responsive channels duringANY state
selResponsiveStates = stateNames; %{'WakeOR','Anesthesia','WakeEMU','Sleep'};%selResponsiveState = 'WakeOR';
channInfoAllPat = cell(1,nPatients);
channInfoAllPatNoStimShaft = cell(1,nPatients);
for iP=1:nPatients
    pName = pNames{iP};
    channInfoPerPatient.pNames = pName;
    channInfoPerPatient.minNumberRespCh = cfgStats.minNumberRespCh;
    dirGralData=  [thisPCDir, filesep, pName, filesep, 'ResultsAnalysisAllCh',posFixDir];
    dirData = [dirGralData,filesep, 'ResponsiveChannelsAllStates',whatToUseRespCh];
    lstResponsiveChannelMATfiles=cell(1,length(selResponsiveStates));
    for iState=1:length(selResponsiveStates)
        lstResponsiveChannelMATfiles{iState} = [dirData,filesep, 'lstResponsiveChannel',pName,'_',selResponsiveStates{iState},'_P2P2std',strtLimitsSec,'.mat']; 
    end
    %  [channInfoAllPat{iP}] = assignRespChannelsToChannInfo (lstResponsiveChannelMATfile, channInfoAllPat{iP});
    % Remove STIM channels in SOZ
    if ~isempty(channInfoInput) && isfield(channInfoInput,'perPatient') && isfield(channInfoInput.perPatient,pName)
        channInfoPerPatient.excludedChannels = channInfoInput.perPatient.(pName).excludedChannelsSOZ;
    end
    channInfoPerPatient.removeChannelsInStimShaft = 0; % select whether to remove channels in shaft (1) for variability analysis
    [channInfoAllPat{iP}] = assignRespChannelsAnyStateToChannInfo (lstResponsiveChannelMATfiles, channInfoPerPatient);
    clear channInfoPerPatient;
    
    disp([num2str(iP),' ' ,pName,' included StimCh= ',num2str(length(channInfoAllPat{iP}.stimBipChNames)),...
        ' included RespCh= ', num2str(length(unique([channInfoAllPat{iP}.recBipolarChPerStim{:}]))),...
        ' out of SelCh= ', num2str(length(channInfoAllPat{iP}.chNamesSelected))]);
end

%% Compare PCI
whatToUsePCI = 'PERTRIALnonSOZ'; %'PERTRIALnonSOZ'; %'EEG0MEAN';%'ZEROMEANZNORM'; %;
script_ComparePCIPerRegion(dirGral, dirGralResults, channInfoAllPat, timeIntervalMs, whatToUsePCI, posFixDir)
close all;
% 
%% Compare # responsive channels
script_CompareRespChannelsAllPatients(dirGral, dirGralResults, pNames, timeIntervalMsResp, whatToUseRespCh, posFixDir)
close all
% Compare # responsive channels per Region
script_CompareRespChannelsPerRegion(dirGral, dirGralResults, channInfoAllPat, timeIntervalMsResp, whatToUseRespCh, posFixDir, cfgStats)
close all

% Connectivity meassures
script_runConnectivityMeasures(dirGral,dirGralResults, channInfoAllPat, timeIntervalMsResp, whatToUseRespCh, posFixDir, cfgStats)
close all

%% RUN comparison of variability for resp channels in any state

cfgStats.useParam = 2; % 2=use permutation trst. Most appropriate since data is not independent.  1= a simple non-paired ttest given the large number of datapoints
cfgStats.whatToUse = 'EEG0MEAN'; %'ZEROMEANZNORM'; %
cfgStats.strDate = strDate; %date; %'06-Jul-2021'; %date
cfgStats.whichVariability= 'STD'; %'TRIALMAD'; %'MAD'; %'2575RANGE'; % 'VARERR'; %- changed to 25-75 range to make it more robust to outliers - original: 'STD'
cfgStats.stateNames = stateNames;
cfgStats.useLog =0;

% CCEP
cfgStats.whatIntervalToUse = 'CCEP'; 
cfgStats.titName = ['poolResp',cfgStats.whatToUse,cfgStats.whichVariability,cfgStats.whatIntervalToUse]; %'min10tr'strtLimitsSec,'Ch', 
dirResultsVar = [dirGralResults, filesep,'VariabilityRespAnyState',posFixDir,filesep, cfgStats.titName];
fileNameComparisonResults = [dirResultsVar,filesep,cfgStats.titName,num2str(length(pNames)),'pat.mat'];
compareVariabilityPooledData(fileNamesPerState, fileNameComparisonResults,channInfoAllPat , cfgStats, cfgInfoPeaks);%channInfoAllPat to include  recordings within shaft
script_CompareVariabilityPerRegion(dirResultsVar, pNames, cfgStats, [cfgStats.strDate])  %,'_Clean50'
close all;

% Repeat stats for Baseline
cfgStats.whatIntervalToUse = 'Baseline'; 
cfgStats.titName = ['poolResp',cfgStats.whatToUse,cfgStats.whichVariability,cfgStats.whatIntervalToUse]; %'min10tr'strtLimitsSec,'Ch', 
script_CompareVariabilityPerRegion(dirResultsVar, pNames, cfgStats, [cfgStats.strDate])  %,'_Clean50'

close all;

%% Save summary in xls
script_createTableWithStimInfoAnesthesia(dirGralResults, pNames, posFixDir, whatToUseRespCh)

summaryOfAnesthesiaMeassures(dirGralResults, pNames, posFixDir,whatToUseRespCh, 'StimCh'); %'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 

whichRecChannels = 'RespCh';  % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCh'=All recording channels
summaryOfAnesthesiaCCEPFeatures(dirGralResults, pNames, posFixDir,whatToUseRespCh, 'OnlyRespCh',whichRecChannels); %'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 

whichRecChannels = 'ANYState';  % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCh'=All recording channels
summaryOfAnesthesiaCCEPFeatures(dirGralResults, pNames, posFixDir,whatToUseRespCh, 'OnlyRespCh',whichRecChannels); %'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 
whichRecChannels = 'ALLCh';  % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCh'=All recording channels
summaryOfAnesthesiaCCEPFeatures(dirGralResults, pNames, posFixDir,whatToUseRespCh, 'OnlyRespCh',whichRecChannels); %'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 

whichRecChannels = 'ANYState';  % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCclch'=All recording channels
summaryOfAnesthesiaCCEPCentrality(dirGralResults, pNames, posFixDir,whatToUseRespCh, 'OnlyRespCh',whichRecChannels); %'StimRespCh'; end %'StimCh'; %'OnlyRespCh'; 



%% Additional stats and plots
script_additionalStatsLOCpaper(dirGralResults, 'all', cfgStats.whichVariability)

%% LMM for Variability and Features

%Variability
script_runLMEMVariability(dirGralResults, pNames, cfgStats.whichVariability);

% Features
whichRecChannels = 'RespCh';  % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCclch'=All recording channels
script_runLMEMFeatures(dirGralResults, pNames, whichRecChannels, 'ptpResponsiveCh');
script_runLMEMFeatures(dirGralResults, pNames, whichRecChannels, 'locFirstPeakRespCh');

whichRecChannels = 'ANYState';  % options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCclch'=All recording channels
script_runLMEMFeatures(dirGralResults, pNames, whichRecChannels, 'dataMaxMinAmp');

