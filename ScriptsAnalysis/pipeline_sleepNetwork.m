function pipeline_sleepNetwork (dirGral,  pNames, channInfoAllPat, useOrganizeData, useExcludeTrials, usePlotLocal, usePlotAll, useResponsive, usePlotResponsive, useRespNonSOZchannels, useComputePCI)

if nargin<4
    useOrganizeData=1;
    useExcludeTrials=1;
    usePlotLocal=1;
    usePlotAll=1;
    useResponsive=1;
    usePlotResponsive=1;
    useRespNonSOZchannels=1;
    useComputePCI=1;
end
%% PIPELINE - GENERIC - for all patients in pNames
if ~exist('dirGral','var')
    dirGral = 'D:\DATA\Anesthesia\Patients';
end
%% CONFIG
%cfgInfoPlot.tBaselineForZeroMean  = -[150 50]/1000; %-[250 200]/1000;% with filter data it has to come before! 100ms before / in original: 25 ms right before stim
posFixDir ='_CCEPLOC'; % '_LP30Hz';% %'_LP4Hz'; %

parfor iP=1:numel(pNames)
    %% Patient Name and Directories
    pName = pNames{iP};
    dirGralResults =  [dirGral, filesep, pName, filesep, 'ResultsAnalysisAllCh', posFixDir];
    dirGralData = [dirGral, filesep, pName]; %'SleepNetwork',filesep,
    
    if isfield(channInfoAllPat,'perPatient') && isfield(channInfoAllPat.perPatient,pName)
        chInfoThisPatient = channInfoAllPat.perPatient.(pName);
    end
    chInfoThisPatient.pName=pName;
    chInfoThisPatient.REMOVESTIM = 1;
    chInfoThisPatient.REMOVE60Hz = 0;
    chInfoThisPatient.FILTERTYPE = { 'filterLP100_IIR','filterNotch60_IIR','filterHP03_IIR'} ;% 
 %   chInfoThisPatient.FILTERTYPE = { 'filterLP30_IIR','filterHP03_IIR'} ;% For Corey's detector 
%    chInfoThisPatient.FILTERTYPE = { 'filterLP4_IIR','filterHP03_IIR'} ;% 4 for amplitude during sleep 
    chInfoThisPatient.useBipolar = 1;

       
    %% ***************** PROCESS PIPELINE - *****************
    %% Organize data
    if useOrganizeData
        fAnesthesiaAnalysis = str2func(strcat('scriptAnesthesiaAnalysis',pName,'_AllCh'));
        fileNameAllChMATfiles = fAnesthesiaAnalysis(dirGralData, dirGralResults, chInfoThisPatient);
    else
        fileNameAllChMATfiles = [dirGralResults,filesep,'dataPerStimAllChannels_',pName,'.mat'];
    end
    
    %% Remove trials with artifacts
  %  channInfo.trialsAnesthesia=20;
    if useExcludeTrials
        %    channInfo.trialsToExcludeWakeEMU ={[],[],[1,3,5],[1,6],[]};
        [fileNameAllChMATfiles, chInfoThisPatient] = script_ExcludeTrialsWithArtifactsAnesthesia(fileNameAllChMATfiles, chInfoThisPatient);
        script_checkAmplitudesStimResp(fileNameAllChMATfiles, pName, chInfoThisPatient) % check amplitudes
    else
        fileNameAllChMATfiles = [dirGralResults,filesep,'dataPerStimAllChannels_',pName,'_Clean.mat'];
    end
    
    %% Local CHANNELS (removed those used for STIM during WAKE Network)
    if usePlotLocal
        dirResults = [dirGralResults,filesep,'AnesthesiaAnalysis',filesep,'LocalChannels'];
        
        % Plots and Comparisons
        plotWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, chInfoThisPatient); %% MUST specify which channels to plot
     %   compareEvaluateWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, channInfo) 
    end
    
%% Plot all channels
     if usePlotAll
         whatToUse = 'PERTRIAL'; %'ZEROMEANZNORM';
         chInfoThisPatient.excludedChannels = chInfoThisPatient.excludedChannelsSOZ;
         chInfoThisPatient.posFixDir = 'nonSOZ';
         plotAllCCEPPerPatientAnesthesia(fileNameAllChMATfiles, [dirGralResults,filesep,'imagesAllCCEP'],  whatToUse, chInfoThisPatient);
     end
    
    %% Find Responsive Channels (show them in a plot)
    if useResponsive
        %% plot for each the STIM that was found
        chInfoThisPatient.excludedChannels = []; % to make sure we are not passing the nonSoz ones
        [lstResponsiveChannel_AllStates, lstResponsiveChannelMATfileAllStates] = script_FindResponsiveChannels_AnesthesiaAllStates(fileNameAllChMATfiles, chInfoThisPatient);
        close all;
    end
    
    %% Responsive CHANNELS
    if usePlotResponsive
        dirResults = [dirGralResults,filesep,'AnesthesiaAnalysis',filesep,'ResponsiveChannels'];
        
        % Plots and Comparisons of the channels found responsive
        plotWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, chInfoThisPatient);
        compareEvaluateWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, chInfoThisPatient)
    end
    
    %% Responsive channels excluding SOZ - similar to PCI calculation
    if useRespNonSOZchannels
        chInfoThisPatient.excludedChannels = chInfoThisPatient.excludedChannelsSOZ;
        chInfoThisPatient.posFixDir = 'nonSOZ';
        [lstResponsiveChannel_AllStates, lstResponsiveChannelMATfileAllStates] = script_FindResponsiveChannels_AnesthesiaAllStates(fileNameAllChMATfiles, chInfoThisPatient);
 %          chInfoThisPatient.posFixDir = 'Keller';
 %          script_FindResponsiveChannels_Keller2011(fileNameAllChMATfiles, chInfoThisPatient);
         close all;        
    end
    
    %% Compute PCI
    if useComputePCI
        chInfoThisPatient.excludedChannels = chInfoThisPatient.excludedChannelsSOZ;
        chInfoThisPatient.posFixDir = 'nonSOZ';
        [PCIstAllStates, PCIValsMATfileAllStates] = script_computePCI_AnesthesiaAllStates(fileNameAllChMATfiles, chInfoThisPatient);
        
    end
end

