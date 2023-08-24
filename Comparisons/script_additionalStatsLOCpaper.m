function script_additionalStatsLOCpaper(dirGralResults, regionName, whichVariability)
% regionName is usually regionName='all';
% dirGralResults = 'D:\DATA\Anesthesia\Patients\AnesthesiaAnalysis\20pat_12-May-2022\min5NoSOZ';


% additional Var stats
additionalStatsPaperVar(dirGralResults, regionName, whichVariability);

% additional Feature stats
featureNames = {'ptpResponsiveCh', 'locFirstPeakRespCh'};%,'ampResponsiveCh','locMaxPeakRespCh'};%   
additionalStatsPaperCCEPfeatures(dirGralResults, featureNames, regionName, 'RespCh')

% options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCh'=All recording channels
featureNames = {'dataMaxMinAmp', 'avPeakAreaPerCh'};%,'peakAmp'};
additionalStatsPaperCCEPfeatures(dirGralResults, featureNames, regionName, 'ANYState')
% options: 'RespCh'=resp channels in all states / 'ANYState'=resp channels in all states / 'ALLCh'=All recording channels
featureNames = {'dataMaxMinAmp', 'avPeakAreaPerCh'};%,'peakAmp'};
additionalStatsPaperCCEPfeatures(dirGralResults, featureNames, regionName, 'ALLCh')

% Similar for Centrality measures (for now outdegree)
featureNames = {'outdegree'};
additionalStatsPaperCentrality(dirGralResults, featureNames, regionName, 'ANYState')

% PCI per patient plots and Max values
plotsForLOCpaperPCI(dirGralResults)


