%input dirGral = ''; 
useOrganizeData=1;
useExcludeTrials=1;
usePlotLocal=0;
usePlotAll=0;
useResponsive=0;
usePlotResponsive=0;
useAuditory=0;
useRespNonSOZchannels=1;
useComputePCI =1;

posFixDir = '_CCEPLOC'; %'_LP30Hz'; %  '_LP4Hz'; %'Auditory'; % %'_noSTIM'; 

%% SOZ info
channInfoAllPat.perPatient.pXX.excludedChannelsOnlySOZ ={'RHT01','RHT02','RHT03','RHT04','RAMY01','RAMY02','RAMY03','RAMY04'}; % Clinical SOZ
channInfoAllPat.perPatient.pXX.excludedChannelsClinicalIIDs ={'LHT01','LHT02','LHT03','LHT04','LHH01','LHH02','LHH03','LHH04'}; %Active SEEG interictal discharges (R>L)
channInfoAllPat.perPatient.pXX.excludedChannelsSOZ = [channInfoAllPat.perPatient.pXX.excludedChannelsOnlySOZ, channInfoAllPat.perPatient.pXX.excludedChannelsClinicalIIDs];

channInfoAllPat.perPatient.pZZZ.excludedChannelsOnlySOZ ={'RHT01','RHT02','RHT03','RHT04','RAMY01','RAMY02','RAMY03','RAMY04'}; % Clinical SOZ
channInfoAllPat.perPatient.pZZZ.excludedChannelsClinicalIIDs ={'LHT01','LHT02','LHT03','LHT04','LHH01','LHH02','LHH03','LHH04'}; %Active SEEG interictal discharges (R>L)
channInfoAllPat.perPatient.pZZZ.excludedChannelsSOZ = [channInfoAllPat.perPatient.pZZZ.excludedChannelsOnlySOZ, channInfoAllPat.perPatient.pZZZ.excludedChannelsClinicalIIDs];

%% more options
%channInfo.perPatient.pXX.trialsToExclude.WakeEMU = [1,2]; % huge IIDs all over the place
%channInfoAllPat.perPatient.pXX.trialsToExclude.WakeOR = [1,6,7]; % 1- huge IIDs all over the place / 6,7 artifacts
%channInfo.perPatient.pXX.trialsToExclude.Anesthesia = []; % 

%% PNames
pNamesPropofol = {'pXX'}; 
pNamesSleep = {'pZZZ'};
pNames = [pNamesPropofol,pNamesSleep];

%% RUN pipelines
pipeline_anesthesia (dirGral, pNamesPropofol, channInfoAllPat, useOrganizeData, useExcludeTrials, usePlotLocal, usePlotAll, useResponsive, usePlotResponsive, useAuditory, useRespNonSOZchannels, useComputePCI); 

pipeline_sleepNetwork (dirGral, pNamesSleep, channInfoAllPat, useOrganizeData, useExcludeTrials, usePlotLocal, usePlotAll, useResponsive, usePlotResponsive, useRespNonSOZchannels, useComputePCI);

%% Write xls for Circro plots
whatToUseRespCh = 'PERTRIALnonSOZMEDIAN';
timeIntervalMs = [0 600];
script_WriteXlsForCircroPlotsAllPatients(dirGral, pNames, timeIntervalMs, whatToUseRespCh, posFixDir);

%% Compute stats and save in xls
script_PooledComparisonAnesthesia_RespFeat(dirGral, pNames, posFixDir, channInfoAllPat);

%% Plot on Atlas 
strDate=date;
script_LOCpaper_plotMeasuresInAtlas (dirGral, strDate, pNames)


