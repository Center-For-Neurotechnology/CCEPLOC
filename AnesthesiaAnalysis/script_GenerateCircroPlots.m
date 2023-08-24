function script_GenerateCircroPlots(dirGral, channInfoAllPat, timeAnalysis, whatToUse, posFixDir)
% if we run inside pooled comparison script, we could use the
% channInfoAllAPt struct directly
if ~exist('posFixDir','var'), posFixDir = []; end % both for data dir and for results dir
% regionNames = {'PFC','OF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};

%dirCircroPlots = [dirGral, filesep,'circroPlots'];
dirCircroPlots = [dirGral, filesep,'circroPlots',filesep, whatToUse,posFixDir, filesep, num2str(length(channInfoAllPat)),'pat'];
timeStr = [num2str(timeAnalysis(1)),'-',num2str(timeAnalysis(2))];

%gralCircroInfoFile = [dirGral, filesep,'circroPlots',filesep,'gralInfoCircroPlots.mat'];
gralCircroInfoFile = [dirGral, filesep,'circroPlots',filesep,'gralInfoCircroPlotsSubRegionsPFC.mat']; % contains general divisions, including PFC subregions (dlPFC/vlPFC/dmPFC/OF) 

% %% Pooled plots
% for iRegion=1:numel(regionNames)
%     generateCircroPlotsFromPooledXls([dirCircroPlots, regionNames{iRegion}, timeStr);
% end
% 
%% Plots Per Patient
nPatients = length(channInfoAllPat);
parfor iP=1:nPatients
    pName = channInfoAllPat{iP}.pNames;
    stimChannels = channInfoAllPat{iP}.stimBipChNames;
    generateCircroPlotsFormXls(dirCircroPlots, pName, stimChannels, timeStr, gralCircroInfoFile);
end