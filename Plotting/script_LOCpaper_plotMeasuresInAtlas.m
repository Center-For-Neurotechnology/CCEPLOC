function script_LOCpaper_plotMeasuresInAtlas (dirGral, strDate, pNames, MRIDirectory)

nPatients = length(pNames);
posFixDir = '_CCEPLOC'; %'_Neuron2023KellerDet'; %'_LP4Hz'; %'_noSTIM';

dirGralResults = [dirGral,filesep,'AnesthesiaAnalysis',filesep,num2str(nPatients),'pat_',strDate,filesep,posFixDir];
%posFixDir = '_Neuron2023'; 
% MRIDirectory: where the plia files of the template brain are

% combine RAS for all patients in an atlas brain (Colin27) using morphing from MMVT (non-linear)
script_CombineAtlasRASAllPatients (dirGral, sort(pNames), strDate, posFixDir)

% Plot relative measures in atlas
%script_plotResultsAsAveragePerRegionInAtlas(dirGralResults, MRIDirectory, strDate,'_CombinedReg') % use this one to create 1 figure per measure with all states
close all;
script_plotResultsAsAveragePerRegionInAtlas_separateFigs(dirGralResults, MRIDirectory, strDate,'_CombinedReg') % use this one to create 1 figure per measure and state and view 
close all;
% Plot difference in brain atlas Anesthesia/WakeOR vs. Sleep/WakeEMU considering average regions
 script_plotResultsAsDifferencePerRegionInAtlas(dirGralResults, MRIDirectory, strDate,'_CombinedReg')
close all;

% Plot Complexity and Connectivity as "bubbles" 
script_plotResultsAsBubblesInAtlas_separateFigs(dirGralResults,MRIDirectory, strDate)
close all;


 % Plot location of channels in each patient's brain
script_plotResultsInPatientBrain(dirGral, gralMRIDirectory, strDate, sort(pNames))
close all;

% Plot Stim and recording contacts in atlas
script_plotStimRecLocationsInAtlas(dirGralResults, strDate, sort(pNames));
close all;
