function [fileNameRespChAllPatAllStates, cfgStats] = script_CompareRespChannelsPerRegion(dirGral,dirGralResults, channInfoAllPat, timeAnalysis, whatToUse, posFixDir, cfgStats)

% % MAC
% dirGral = '/Users/rzelmann/Dropbox (Partners HealthCare)/Rina/DATA/MG'; %'C:\DARPA\DATA\ClosedLoopPhysiology\MG51b'; %'H:\DATA\Patients\MG51b';
% % LAB PC
% dirGral = 'D:\DATA\Anesthesia\Patients'; %dirGral = 'C:\Users\Rina\Dropbox (Partners HealthCare)\Rina\DATA\Anesthesia\Patients';
if ~exist('channInfoAllPat','var'), channInfoAllPat{1}.pNames = {'BW46'};end %,'MG51b','MG120','MG123','MG124'}; end
if ~exist('timeAnalysis','var'), timeAnalysis = [10 150]; end % in ms
if ~exist('whatToUse','var'), whatToUse = 'PERTRIAL'; end % 'PERTRIAL'
if ~exist('posFixDir','var'), posFixDir = []; end % both for data dir and for results dir
if ~exist('cfgStats','var'), cfgStats = []; end 

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
allStatesTitName = {'WakeEMU', 'Sleep', 'WakeOR','Anest'}; % USe Anest instead of Anesthesia because we are using this to remove from title and compare channels!! - poor hack!

posFixTimeAnalysisForTitle = [num2str(timeAnalysis(1)),'-',num2str(timeAnalysis(2))];
posFixTimeAnalysisForFile = [num2str(timeAnalysis(1)/1000),'_',num2str(timeAnalysis(2)/1000)];

titNameGRal = ['t',posFixTimeAnalysisForTitle,posFixDir];

%cfgStats.regionsToCompare = {'anterior','posTemp','allButAnt','all','PFC','posterior', 'temporal'};
%cfgStats.regionsToCompare = {'all','anterior','frontal','PFC','OF','allButAnt','posTemp','posterior', 'temporal','central','cingulate','latTemp','posCentral','subcorMTL'}; %,'thalCaud'
cfgStats.regionsToCompare = {'all','anterior','frontal','allButAnt','posterior', 'temporal','central','cingulate','posCentral','antCentral',...
                            'latTemp','dlPFC','vlPFC','dmPFC','OF','ACC'}; %,'thalCaud'

%% Organize files
nPatients = numel(channInfoAllPat);
fileNameRespChAllPatAllStates = cell(nPatients, numel(allStates));
for iP=1:nPatients
    pName = channInfoAllPat{iP}.pNames;
    dirData =  [dirGral, filesep, pName, filesep, 'ResultsAnalysisAllCh',posFixDir,filesep,'ResponsiveChannelsAllStates',whatToUse]; 
    for iState=1:numel(allStates)
        fileNameRespChAllPatAllStates{iP,iState} = [dirData,filesep,'lstResponsiveChannel',pName,'_',allStates{iState},'_P2P2std',posFixTimeAnalysisForFile,'.mat'];
    end
    pNames{iP}=pName;
    stimChPerPat{iP} = channInfoAllPat{iP}.stimBipChNames;
    respChAnyStaChPerPat{iP} = channInfoAllPat{iP}.recBipolarChPerStim;
end

dirRespResults = [dirGralResults, filesep,'ConnectivityResults',filesep, titNameGRal, filesep, whatToUse];

% Start Diary
%if ~exist(dirGralResults,'dir'),mkdir(dirGralResults); end
%diary([dirGralResults,filesep,'log','CompareRespChannelsPerRegion.log'])

%% Run comparisons
cfgStats.pNames = pNames;
cfgStats.allStates = allStates;
cfgStats.allStatesTitName = allStatesTitName;
%cfgStats.sheetName = 'nRespCh';
cfgStats.posRegionFor = {'StimCh', 'OnlyRespCh', 'StimRespCh'};
cfgStats.stimChPerPat = stimChPerPat;
cfgStats.respChAnyStaChPerPat = respChAnyStaChPerPat;
cfgStats.channInfoAllPat = channInfoAllPat;

%% 1. nResponses
cfgStats.useParam = 0; % 0 = non parametric / 1=ttest - no reason to expect normal distribution
compTitName = 'nResp';
if isfield(cfgStats,'titName') && ~isempty(cfgStats.titName)
    compTitName = [compTitName,' ' ,cfgStats.titName];
end
parfor iRegionFor=1:length(cfgStats.posRegionFor)
    cfgStatsPerPat = cfgStats;
    cfgStatsPerPat.anatRegionFor= cfgStats.posRegionFor{iRegionFor};   % options: 'stimCh or respCh'or StimRespCh
    dirResults = [dirRespResults,filesep,compTitName,cfgStatsPerPat.anatRegionFor];
    cfgStatsPerPat.titName = [compTitName,' ', ' ',  num2str(length(pNames)),'pat'];
    fileNameComparisonResults = [dirResults,filesep,compTitName,'_',cfgStatsPerPat.anatRegionFor, num2str(length(pNames)),'pat'];
    cfgStatsPerPat.xlsFileName = [fileNameComparisonResults,'.xlsx'];
    compareResponsiveChannelsPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStatsPerPat);
    close all;
end

%% 2. Compare peak to peak Amplitude and other features for region by STIM/Resp or both channel
% featurenames are the fields of resp struct
% Features (p2p amplitude, area)
cfgStats.useParam = 2; % 0 = non parametric / 1=ttest - no reason to expect normal distribution
compTitName = 'FeatRespCh';
cfgStats.featureNames = {'ampResponsiveCh','ptpResponsiveCh', 'locFirstPeakRespCh','locMaxPeakRespCh','prominencePerCh','peakMaxMinAmpPerCh','areaP2PPerCh'}; %'rmsDataPerCh','relAreaPerCh','relP2PAreaPerCh',
parfor iRegionFor=1:length(cfgStats.posRegionFor)
    cfgStatsPerFor = cfgStats;
    cfgStatsPerFor.anatRegionFor= cfgStats.posRegionFor{iRegionFor};   % options: 'stimCh or respCh'or StimRespCh
    dirResults = [dirGralResults,filesep,compTitName,cfgStatsPerFor.anatRegionFor];
    cfgStatsPerFor.titName = [compTitName,' ',cfgStatsPerFor.anatRegionFor,' ', num2str(length(pNames)),'pat'];
    fileNameComparisonResults = [dirResults,filesep,compTitName,'_',cfgStatsPerFor.anatRegionFor,'_', num2str(length(pNames)),'pat'];
    cfgStatsPerFor.xlsFileName = [fileNameComparisonResults,'.xlsx'];
    compareFeaturesResponsiveChannelsPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStatsPerFor, 'RESPCH');
    close all;
end


%% 2. Compare peak to peak Amplitude and other features for region by STIM/Resp forResp in ANY STATE
% featurenames are the fields of resp struct
% Features (p2p amplitude, area)
cfgStats.useParam = 2; % 0 = non parametric / 1=ttest - no reason to expect normal distribution
compTitName = 'FeatANYState';
cfgStats.featureNames = {'dataMaxMinAmp','peakAmp', 'avPeakAreaPerCh'};
parfor iRegionFor=1:length(cfgStats.posRegionFor)
    cfgStatsPerFor = cfgStats;
    cfgStatsPerFor.anatRegionFor= cfgStats.posRegionFor{iRegionFor};   % options: 'stimCh or respCh'or StimRespCh
    dirResults = [dirGralResults,filesep,compTitName,cfgStatsPerFor.anatRegionFor];
    cfgStatsPerFor.titName = [compTitName,' ',cfgStatsPerFor.anatRegionFor,' ', num2str(length(pNames)),'pat'];
    fileNameComparisonResults = [dirResults,filesep,compTitName,'_',cfgStatsPerFor.anatRegionFor,'_', num2str(length(pNames)),'pat'];
    cfgStatsPerFor.xlsFileName = [fileNameComparisonResults,'.xlsx'];
    compareFeaturesResponsiveChannelsPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStatsPerFor, 'ANYSTATE');
    close all;
end

%% 2. Compare peak to peak Amplitude and other features for ALL recording channels
% featurenames are the fields of resp struct
% Features (p2p amplitude, area)
cfgStats.useParam = 2; % 0 = non parametric / 1=ttest - no reason to expect normal distribution
compTitName = 'FeatALLCh';
cfgStats.featureNames = {'dataMaxMinAmp','peakAmp', 'avPeakAreaPerCh'};
parfor iRegionFor=1:length(cfgStats.posRegionFor)
    cfgStatsPerFor = cfgStats;
    cfgStatsPerFor.anatRegionFor= cfgStats.posRegionFor{iRegionFor};   % options: 'stimCh or respCh'or StimRespCh
    dirResults = [dirGralResults,filesep,compTitName,cfgStatsPerFor.anatRegionFor];
    cfgStatsPerFor.titName = [compTitName,' ',cfgStatsPerFor.anatRegionFor,' ', num2str(length(pNames)),'pat'];
    fileNameComparisonResults = [dirResults,filesep,compTitName,'_',cfgStatsPerFor.anatRegionFor,'_', num2str(length(pNames)),'pat'];
    cfgStatsPerFor.xlsFileName = [fileNameComparisonResults,'.xlsx'];
    compareFeaturesResponsiveChannelsPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStatsPerFor, 'ALLCH');
    close all;
end


% %% 3. Compare Centrality measures for ALL recording channels
% % featurenames are the fields of resp struct
% % Features (p2p amplitude, area)
% compTitName = 'CentANYSTATE';
% cfgStats.useParam=2; % permutation test
% %cfgStats.featureNames = {'dataMaxMinAmp','peakAmp', 'avPeakAreaPerCh'};
% parfor iRegionFor=1:length(cfgStats.posRegionFor)
%     cfgStatsPerFor = cfgStats;
%     cfgStatsPerFor.anatRegionFor= cfgStats.posRegionFor{iRegionFor};   % options: 'stimCh or respCh'or StimRespCh
%     dirResults = [dirGralResults,filesep,compTitName,cfgStatsPerFor.anatRegionFor];
%     cfgStatsPerFor.titName = [compTitName,' ',cfgStatsPerFor.anatRegionFor,' ', num2str(length(pNames)),'pat'];
%     fileNameComparisonResults = [dirResults,filesep,titNameGRal,'_',compTitName,'_',cfgStatsPerFor.anatRegionFor,'_', num2str(length(pNames)),'pat'];
%     cfgStatsPerFor.xlsFileName = [fileNameComparisonResults,'.xlsx'];
%     compareCentralityMeasuresPerStatePerRegion(fileNameRespChAllPatAllStates, dirResults, cfgStatsPerFor, 'ANYSTATE');
%     close all;
% end



%diary off;
%% Possible features

% stState.channInfoRespCh{indStimChData(iStim)}
% 
% ans = 
% 
%   struct with fields:
% 
%     lstResponsiveChannel: {'RMI06-RMI05'  'RMI07-RMI06'  'RPI6-RPI5'}
%          ampResponsiveCh: {[4.8934]  [5.9021]  [5.1377]}
%          ptpResponsiveCh: {[6.2737]  [6.0168]  [2.7130]}
%          locResponsiveCh: {[216]  [240.5000]  [202.5000]}
%             rmsDataPerCh: {[3.0726]  [3.6749]  [2.7886]}
%          prominencePerCh: {[3.5576e+03]  [2.5355e+03]  [611.9304]}
%                 nPeaksCh: {[3]  [6]  [10]}
%          chNamesSelected: {1×42 cell}
%           isChResponsive: [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1]
%            stimSiteNames: {2×1 cell}
%                  titName: 'WakeEMU'
%                whatToUse: 'PERTRIAL'
%               useAverage: 1
%               tLimitsSec: [0.0100 0.6000]
%          anatRegionsResp: {'Putam'  'Caud'  'Temp'}
%             RASCoordResp: {[28.3100 -17.2750 8.9750]  [28.1300 -14.2800 13.9600]  [47.5000 -49.3150 2.6550]}
%        anatRegionsStimCh: {'vlPFC'}
%      RASCoordPerChStimCh: [-40.3500 35.2400 -9.1500]
%         anatRegionsPerCh: {1×42 cell}
%            RASCoordPerCh: [42×3 double]
%     avPeakToPeakAmpPerCh: [1×42 double]
%            p2P2PAmpPerCh: {[7.5047]  [7.3611]  [5.0526]}
%              cfgInfoPlot: [1×1 struct]
%             cfgInfoPeaks: [1×1 struct]
%              relAmpPerCh: {[6.0159]  [5.6558]  [4.1552]}
%              relP2PPerCh: {[3.9535]  [13.8962]  [1.1082]}
%            relP2P2PPerCh: {[2.4367]  [Inf]  [1.0862]}
%             relAreaPerCh: {[208.9791]  [26.2502]  [4.8214]}
%          relP2PAreaPerCh: {[151.8812]  [16.3663]  [0.3371]}
%        relP2P2PAreaPerCh: {[68.6709]  [Inf]  [0.5316]}