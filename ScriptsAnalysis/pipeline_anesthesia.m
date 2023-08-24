function pipeline_anesthesia (dirGral, pNames, channInfoAllPat, useOrganizeData, useExcludeTrials, usePlotLocal, usePlotAll, useResponsive, usePlotResponsive, useAuditory, useRespNonSOZchannels, useComputePCI)

if nargin<4
    useOrganizeData=1;
    useExcludeTrials=1;
    usePlotLocal=1;
    usePlotAll=1;
    useResponsive=1;
    usePlotResponsive=1;
    useAuditory=0;
    useRespNonSOZchannels=0;
    useComputePCI=1;
end
%% PIPELINE - GENERIC - for all patients in pNames
if ~exist('dirGral','var')
    dirGral = 'D:\DATA\Anesthesia\Patients'; 
end

%% CONFIG
posFixDir = '_CCEPLOC'; %'_LP30Hz'; %'_LP4Hz';%'Auditory'; %

parfor iP=1:numel(pNames)
    %% Patient Name and Directories - strange organization to make it work with parfor
    pName = pNames{iP};
    dirGralResults =  [dirGral, filesep, pName, filesep, 'ResultsAnalysisAllCh', posFixDir]; 
    dirGralData = [dirGral, filesep, pName];
        
    if isfield(channInfoAllPat,'perPatient') && isfield(channInfoAllPat.perPatient,pName)
        chInfoThisPatient = channInfoAllPat.perPatient.(pName);
    end
    chInfoThisPatient.pName=pName;
    chInfoThisPatient.REMOVESTIM = 1;
    chInfoThisPatient.REMOVE60Hz = 0;
 %   chInfoThisPatient.FILTERTYPE = { 'filterLP30_IIR','filterHP03_IIR'} ;% For Corey's detector 
    chInfoThisPatient.FILTERTYPE = { 'filterLP100_IIR','filterNotch60_IIR','filterHP03_IIR'} ;% CCEP LOC paper
%    chInfoThisPatient.FILTERTYPE = { 'filterLP4_IIR','filterHP03_IIR'} ;% LP 4 Hz for amplitude during sleep 
    chInfoThisPatient.useBipolar = 1;


    %% ***************** PROCESS PIPELINE - *****************
    %% Organize data
    if useOrganizeData
      %  fAnesthesiaAnalysis = str2func(strcat('scriptAnesthesiaAnalysis',pName,'_AllCh'));
        fAnesthesiaAnalysis = str2func(strcat('scriptAnesthesiaAnalysis',pName,'_AllCh_LOCSpectrum')); % use spectral analysis to inditify LOC time for propofol and 5min (time until induction starts for MAC)
        fileNameAllChMATfiles = fAnesthesiaAnalysis(dirGralData, dirGralResults, chInfoThisPatient);
    else
        fileNameAllChMATfiles = [dirGralResults,filesep,'dataPerStimAllChannels_',pName,'.mat'];
    end
    
    %% Remove trials with artifacts
    if useExcludeTrials
        [fileNameAllChMATfiles, chInfoThisPatient] = script_ExcludeTrialsWithArtifactsAnesthesia(fileNameAllChMATfiles, chInfoThisPatient);
        script_checkAmplitudesStimResp(fileNameAllChMATfiles, pName, chInfoThisPatient) % check amplitudes
    else
        fileNameAllChMATfiles = [dirGralResults,filesep,'dataPerStimAllChannels_',pName,'_Clean.mat'];
    end

    %% Local CHANNELS - Plots and Comparisons of SPECIFIC Channels
    if usePlotLocal
        dirResults = [dirGralResults,filesep,'AnesthesiaAnalysis',filesep,'LocalChannels'];
        % Plots and Comparisons
        plotWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, chInfoThisPatient); % MUST specify which channels to plot
     %   compareEvaluateWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, channInfo) 
    end
    
%% Plot all channels - not used as it is plot in useResponsive
     if usePlotAll
         whatToUse = 'PERTRIAL'; %'ZEROMEANZNORM';
         chInfoThisPatient.excludedChannels = chInfoThisPatient.excludedChannelsSOZ;
         chInfoThisPatient.posFixDir = 'nonSOZ';
         plotAllCCEPPerPatientAnesthesia(fileNameAllChMATfiles, [dirGralResults,filesep,'imagesAllCCEP'],  whatToUse, chInfoThisPatient);
     end
     
    %% Find Responsive Channels (show them in a plot)
    if useResponsive
        % plot for each the STIM that was found
        chInfoThisPatient.excludedChannels = []; % to make sure we are not passing the nonSoz ones
        script_FindResponsiveChannels_AnesthesiaAllStates(fileNameAllChMATfiles, chInfoThisPatient);
        close all
    end
    
    %% SELECTED CHANNELS - USE Responsive channels from each stim during Wake EMU (10-250ms)
    if usePlotResponsive
        dirResults = [dirGralResults,filesep,'AnesthesiaAnalysis',filesep,'ResponsiveChannels'];
        
        % Plots and Comparison
        plotWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, chInfoThisPatient); %
        compareEvaluateWakeSleepAnesthesia(fileNameAllChMATfiles, dirResults, chInfoThisPatient) 
    end
    
    %% ***************** AUDITORY Stim Analysis ***************** %% ONLY IN A FEW PATIENTS!
    if useAuditory
        fAuditoryAnalysis = str2func(strcat('scriptAnesthesiaAnalysis',pName,'_AllCh_Auditory'));
        fileNameAllChMATfilesAuditory = fAuditoryAnalysis(dirGralData, dirGralResults, chInfoThisPatient);
        
        % Remove trials with artifacts
    %    [fileNameAllChMATfilesAuditory, chInfoThisPatient] = script_ExcludeTrialsWithArtifactsAnesthesia(fileNameAllChMATfilesAuditory, chInfoThisPatient);
        
        % Plot all channels - AUDITORY
        whatToUse = 'PERTRIAL';
        chInfoThisPatient.trialsAnesthesia=50;
        chInfoThisPatient.trialsWakeOR=1:50;
        plotAllCCEPPerPatientAnesthesia(fileNameAllChMATfilesAuditory, [dirGralResults,filesep,'imagesAllCCEP','_Auditory'],  whatToUse, chInfoThisPatient)
    end
    
    %% Responsive channels excluding SOZ - similar to PCI calculation - MISSING!
    if useRespNonSOZchannels
        chInfoThisPatient.excludedChannels = chInfoThisPatient.excludedChannelsSOZ;
        chInfoThisPatient.posFixDir = 'nonSOZ';
        script_FindResponsiveChannels_AnesthesiaAllStates(fileNameAllChMATfiles, chInfoThisPatient);
 %          chInfoThisPatient.posFixDir = 'Keller';
 %          script_FindResponsiveChannels_Keller2011(fileNameAllChMATfiles, chInfoThisPatient);
       close all;
    end
    
    %% Compute PCI
    if useComputePCI
        chInfoThisPatient.excludedChannels = chInfoThisPatient.excludedChannelsSOZ;
        chInfoThisPatient.posFixDir = 'nonSOZ';
        script_computePCI_AnesthesiaAllStates(fileNameAllChMATfiles, chInfoThisPatient);
        
    end
end
%% NOTES
%% From Notes: 
