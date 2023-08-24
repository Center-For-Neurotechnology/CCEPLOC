function script_GenerateCircroPlotsPerRegion(dirGral, pNames, timeAnalysis, whatToUse, posFixDir, posFixFileLobeOrRegion)
% if we run inside pooled comparison script, we could use the
% channInfoAllAPt struct directly
if ~exist('posFixDir','var'), posFixDir = []; end % both for data dir and for results dir
if ~exist('posFixFileLobeOrRegion','var'), posFixFileLobeOrRegion = '_perGralRegionStimCh'; end % options: _perGralRegionStimCh or _perLobeStimCh
%regionNames = {'PFC','OF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};
regionNames = {'dlPFC','dmPFC','vlPFC','OF','ACC'};%,'latTemp','PCC','parietal','occipital'};
gralRegionNames = {'frontal','posterior','temporal'};

dirCircroPlots = [dirGral, filesep,'circroPlots',filesep, whatToUse, posFixDir, filesep, num2str(length(pNames)),'pat'];
dirCircroPlotsCommon = [dirGral, filesep,'circroPlotsCommon',filesep, whatToUse, posFixDir, filesep, num2str(length(pNames)),'pat'];
timeStr = [num2str(timeAnalysis(1)),'-',num2str(timeAnalysis(2))];

%gralCircroInfoFile = [dirGral, filesep,'circroPlots',filesep,'gralInfoCircroPlots.mat'];
gralCircroInfoFile = [dirGral, filesep,'circroPlots',filesep,'gralInfoCircroPlotsSubRegionsPFC.mat'];

% % %% Pooled plots per GRal Region
parfor iRegion=1:numel(gralRegionNames)
    generateCircroPlotsFromPooledXls(dirCircroPlots, gralRegionNames{iRegion}, timeStr, posFixFileLobeOrRegion, gralCircroInfoFile);
end
%% Pooled plots per subRegion
parfor iRegion=1:numel(regionNames)
    generateCircroPlotsFromPooledXls(dirCircroPlots, regionNames{iRegion}, timeStr, posFixFileLobeOrRegion, gralCircroInfoFile);
end

%% Plot ONLY STIM channels that correspond to 2 states
%% Sleep-WakeEMU or Anesthesia-WakeOR or WakeEMU-WakeOR or ALL 4 states
% read files for each state, find corresponding STIM channels and save on another XLS
% In addition, save similarities (same resp channels) and differences (diff resp channels/amplitude) between states

%posFixFileLobeOrRegion = ['_perGralRegionStimCh'];
% save xls
for iRegion=1:numel(gralRegionNames)   
    selStates = {'WakeEMU','Sleep'};
    dirCircroPlotsPaired{1, iRegion} = getCommonStimSitesSaveinXlsForCircro(dirCircroPlots, gralRegionNames{iRegion}, timeStr, selStates, posFixFileLobeOrRegion);
    selStates = {'WakeOR','Anesthesia'};
    dirCircroPlotsPaired{2, iRegion} = getCommonStimSitesSaveinXlsForCircro(dirCircroPlots, gralRegionNames{iRegion}, timeStr, selStates, posFixFileLobeOrRegion);
end
% plot Circro with differences

selStates = {'WakeEMU','Sleep'};
posFixFileEdge = [posFixFileLobeOrRegion,'_Diff',selStates{1}, selStates{2}];
parfor iRegion=1:numel(gralRegionNames)
    generateCircroPlotsDifferenceFromPooledXls(dirCircroPlots, dirCircroPlotsPaired{1, iRegion}, gralRegionNames{iRegion}, timeStr, posFixFileLobeOrRegion, posFixFileEdge, gralCircroInfoFile);
end

selStates = {'WakeOR','Anesthesia'};
posFixFileEdge = [posFixFileLobeOrRegion,'_Diff',selStates{1}, selStates{2}];
parfor iRegion=1:numel(gralRegionNames)
    generateCircroPlotsDifferenceFromPooledXls(dirCircroPlots, dirCircroPlotsPaired{2, iRegion}, gralRegionNames{iRegion}, timeStr, posFixFileLobeOrRegion, posFixFileEdge, gralCircroInfoFile);
end

