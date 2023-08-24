function script_plotResultsInPatientBrain(dirGral, gralMRIDirectory, strDate, pNames)
% Plot location of all electrodes,
% strDate is the date as it apppears in directory and xls files

nPatients = length(pNames);
dirGralResults = [dirGral,filesep,'AnesthesiaAnalysis',filesep,num2str(nPatients),'pat_',strDate,filesep,'min5NoSOZ'];

posFixDir = '_Neuron2023'; 

reconDataDir=[gralMRIDirectory,filesep,'ReconLocs'];

warning('off')

maxVal = 0.6;
thVal = 0; 

dirImages = [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'plotsBrainPerPatient_',num2str(thVal),'to',num2str(maxVal),posFixDir,'_',date]; %MaxAt05'];
if ~exist(dirImages,'dir'),mkdir(dirImages); end
diary ([dirImages,filesep,'logDistributionMeanOnAtlas',num2str(thVal),'to',num2str(maxVal)])

%% General Labels config
TargetLabels={'middlefrontal' % caudalmiddlefrontal rostralmiddlefrontal
    'superiorfrontal'
    'pars' %= inferior frontal 'parstriangularis'     'parsopercularis'      'parsorbitalis'    % put together as inferior frontal 
    'medialorbitofrontal'
    'lateralorbitofrontal'
    'rostralanteriorcingulate'
    'caudalanteriorcingulate'
    'isthmuscingulate'
    'posteriorcingulate'
    'amygdala'
    'entorhinal'
    'hippocamp' %    'Hippocampus'    'parahippocampal'
    'insula'
    'accumbens'
    'caudate'
    'putamen'
    'temporal' %inferiortemporal transversetemporal middletemporal superiortemporal
    'fusiform'
    'central' %paracentral postcentral precentral
    'supramarginal'
    'precuneus'
    'parietal' % inferiorparietal superiorparietal
    'cuneus'
    'lingual' % put together with occipital
    'occipital' %lateraloccipital
    'calcarine' % put together with occipital
    'thalamus'
    'unk'};

TargetLabelAccr={'dlPFC' 
    'dmPFC'
    'vlPFC' %= inferior frontal 
    'mOFC'
    'lOFC'
    'rACC'
    'cACC'
    'isCC'
    'pCC'
    'Amyg'
    'Ent'
    'HC' %    'Hippocampus'    'parahippocampal'
    'Insu'
    'Accum'
    'Caud'
    'Putam'
    'Temp' %inferiortemporal transversetemporal middletemporal superiortemporal
    'Fusi'
    'Cent' %paracentral postcentral precentral
    'SupMar'
    'preC'
    'Pari' % inferiorparietal superiorparietal
    'Cun'
    'Ling' % put together with occipital?
    'Occ' %lateraloccipital
    'Calcar' % Calcarine put together with occipital
    'Thal'
    'unkwn'
    };


%% Plot Gral info
%COL=colormap(hsv(length(Patients)));
% COL2=colormap(colorcube(27));
% Colormaps
% COLVar=(colormap(bipolar2(100))+.5)/1.5;
% valSteps = linspace(-1,1,size(COLVar, 1));
% 
% faceAlphaVal = 1; %0.7
% faceAlphaValBkg = 0.7; % use this for cortical region in the background to highlight subcortical regions

%% ----------------------------------------------------------
%% UNTIL NOW CONFIGURATION - HERE the REAL PLOTTING starts
%% ----------------------------------------------------------
% plot electrode location color coded by anatomical location (for each patient)
titNameFig = 'AllStates';
allStates = {'WakeEMU','Sleep','WakeOR','Anesthesia'};
plotElectOnPatientsBrain_PerRegion(pNames,reconDataDir,dirGral,posFixDir, dirImages,titNameFig, TargetLabelAccr, allStates)

% only in WakeEMU and Sleep
selStates = {'WakeEMU','Sleep'};
plotElectOnPatientsBrain_PerRegion(pNames,reconDataDir,dirGral,posFixDir, dirImages,[selStates{:}], TargetLabelAccr, selStates)

% only in WakeOR and Anesthesia
selStates = {'WakeOR','Anesthesia'};
plotElectOnPatientsBrain_PerRegion(pNames,reconDataDir,dirGral,posFixDir, dirImages,[selStates{:}], TargetLabelAccr, selStates)




diary off;