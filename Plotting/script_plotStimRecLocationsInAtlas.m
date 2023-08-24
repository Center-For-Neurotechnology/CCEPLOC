function script_plotStimRecLocationsInAtlas(dirGralResults, MRIDirectory, strDate, pNames)
% Plot variability, features,
% strDate is the date as it apppears in directory and xls files


xlsTablesDir = dirGralResults; %[gralPaperDir, filesep,'TablesForPlots'];

fileNameRASInAtlas =  [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'atlasColin27_Neuron2023_AllRAS_20.mat'];

warning('off')

dirImages = [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'StimRecLocationsInAtlas_',num2str(length(pNames)),'_',strDate];
if ~exist(dirImages,'dir'),mkdir(dirImages); end
diary ([dirImages,filesep,'plotStimRecLocationsInAtlas',date,'.log'])


%% Configuration
COLVar = colormap(hsv(32))*.8; % ORIGINAL colorcube(nRegions);
valSteps = linspace(-1,1,size(COLVar,1));
bubbleSizeRecCh = 30;
bubbleSizeStimCh = 300;

%COLBASE=[.9 .9 .9];
faceAlphaVal = 1; %0.7
faceAlphaValBkg = 0.7; % use this for cortical region in the background to highlight subcortical regions

[verticesrh, facesrh] = read_ply([MRIDirectory,'rh.pial.ply']);
[verticeslh, faceslh] = read_ply([MRIDirectory,'lh.pial.ply']);
LeftHemisDir=[MRIDirectory, filesep,'aparc.DKTatlas40.pial.lh\'];
RightHemisDir= [MRIDirectory, filesep,'aparc.DKTatlas40.pial.rh\'];
Subcortical= [MRIDirectory, filesep,'subcortical\'];
LeftPly=dir([LeftHemisDir,'*.ply']);

%% relate Plia values with regions used in this project - for this ONLY the classification - we could remove and add the target names back
regionsToCombine=cell(0,0);
[CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, CombinedRegionAccr] = configAtlasForMeasPlots(LeftHemisDir, regionsToCombine); % Left Plia
nCombRegions = length(CombinedRegionAccr);
scrsz = get(groot,'ScreenSize');

%% ----------------------------------------------------------
%% UNTIL NOW CONFIGURATION - HERE the REAL PLOTTING starts
%% ----------------------------------------------------------
%COLVar=(colormap(hsv(length(TargetLabelAccr))));
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPFeatures_ALLCh_all.xlsx']; % take from features ALL CHANNLES
SheetList={'RelFeat WakeORWakeEMU','RelFeat SleepWakeEMU','RelFeat AnesthesiaWakeOR'};
clear condColFeat;
condColFeat{1} = 'F'; % 'Relative PTP' // ReldataMaxMinAmp
firstRow=3;
colChName = 1; % which column has the Recording channels names information
colWithStimCh = 2; % which column has the Recording channels names information
colWithPName = 3; % which column has the Recording channels names information
colWithAnat = 4; % which column has the anatomical information
colWithStimAnat = 5; % which column has the anatomical information
nCompPlots =length(SheetList);

%% Plot color coded per location 
titNameFig = 'ColorPerLoc';

for iSheet=1:nCompPlots
    %A. Read text information
    C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
    %         chNamesStim = table2cell(C(firstRow:end,1));
    %         pNames = table2cell(C(firstRow:end,2));
    anatLocationAll = table2cell(C(firstRow:end,colWithAnat));
    chNamesToPlotAll = table2cell(C(firstRow:end,colChName));
    stimChNamesToPlotAll = table2cell(C(firstRow:end,colWithStimCh));
    pNamesToPlotAll = table2cell(C(firstRow:end,colWithPName));
    anatStimLocationAll = table2cell(C(firstRow:end,colWithStimAnat));
    % only keep unique rec channels
    [unRecChPName, indUn] = unique(strcat(chNamesToPlotAll,'_',pNamesToPlotAll),'stable');
    pNamesToPlot = pNamesToPlotAll(indUn);
    chNamesToPlot = chNamesToPlotAll(indUn);
    anatLocation = anatLocationAll(indUn);
    % get index of rec  anat regions
    indAnat=zeros(1,length(anatLocation));
    for iCh=1:length(anatLocation)
        indAnat(iCh) = find(strcmp(CombinedRegionAccr, anatLocation{iCh}));
    end

   
    %C. Plot Recording channels
    titName = ['AnatRegion', SheetList{iSheet}];
    figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
    % plot recording channels
    plotVar= valSteps(indAnat);
    plotValuesOnAtlasBrainAsBubbles(plotVar, fileNameRASInAtlas, strcat(chNamesToPlot,pNamesToPlot), titName, {facesrh;faceslh}, {verticesrh;verticeslh}, COLVar, valSteps, bubbleSizeRecCh);
    % plot Stim channels - no face/vertex to plot on top of the other one

    % only keep stim channels
    [unStimChPName, indUn] = unique(strcat(stimChNamesToPlotAll,'_',pNamesToPlotAll),'stable');
    indContact2 = cell2mat(regexp(unStimChPName, '\d\D','once'))+1;
    stimContactsToPlot=cell(0,0);
    for iCh=1:length(unStimChPName)
        stimContactsToPlot{iCh,1} = strcat(unStimChPName{iCh}(1:indContact2(iCh)-1),'-',unStimChPName{iCh}(indContact2(iCh):end));
    end
    % get index of rec  anat regions
    anatStimLocation = anatStimLocationAll(indUn);
    indStimAnat=zeros(1,length(anatStimLocation));
    for iCh=1:length(anatStimLocation)
        indStimAnat(iCh) = find(strcmp(CombinedRegionAccr, anatStimLocation{iCh}));
    end
    plotVar= valSteps(indStimAnat);
    plotValuesOnAtlasBrainAsBubbles(plotVar, fileNameRASInAtlas, stimContactsToPlot, titName, [], [], COLVar, valSteps, bubbleSizeStimCh);
   
    
    % save
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecStimElectrodes', [titNameFig, titName],'_sagital'])
    saveas(gcf,[dirImages,filesep, 'RecStimElectrodes',[titNameFig,titName],'.fig'])
    % change view and save again
    view(0,90)
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecStimElectrodes', [titNameFig, titName],'_axial'])
end

%% Plot color coded per PATIENT 
%COLVar=(colormap(hsv(length(TargetLabelAccr))));
%% 20 different colors... same as for max PCI
posColors = {'#e6194b', '#3cb44b', '#ffe119', '#4363d8', '#f58231', '#911eb4', '#46f0f0', '#f032e6', '#bcf60c', '#fabebe', '#008080', ...
             '#e6beff', '#9a6324', '#fffac8', '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000075', '#808080'};
COLVar = zeros(length(posColors),3);%colorcube(length(pNames));
for iCol=1:length(posColors)
    COLVar(iCol,:) = sscanf(posColors{iCol}(2:end),'%2x%2x%2x',[1 3])/255;
end
valSteps = linspace(-1,1,size(COLVar, 1));
titNameFig = 'ColorPerPat';

for iSheet=1:nCompPlots
    %A. Read text information
    C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
    %    anatLocation = table2cell(C(firstRow:end,colWithAnat));
    chNamesToPlotAll = table2cell(C(firstRow:end,colChName));
    stimChNamesToPlotAll = table2cell(C(firstRow:end,colWithStimCh));
    pNamesToPlotAll = table2cell(C(firstRow:end,colWithPName));
    %    anatStimLocation = table2cell(C(firstRow:end,colWithStimAnat));
    % only keep unique rec channels
    [unRecChPName, indUn] = unique(strcat(chNamesToPlotAll,'_',pNamesToPlotAll),'stable');
    pNamesToPlot = pNamesToPlotAll(indUn);
    chNamesToPlot = chNamesToPlotAll(indUn);
    
    indPat=zeros(1,length(pNamesToPlot));
    for iP=1:length(pNamesToPlot)
        indPat(iP) = find(strcmp(pNames, pNamesToPlot{iP}));
    end
    plotVar= valSteps(indPat);
   
    %C. Plot Recording channels
    titName = ['AnatRegion', SheetList{iSheet}];
    figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
    % plot recording channels
    plotValuesOnAtlasBrainAsBubbles(plotVar, fileNameRASInAtlas, strcat(chNamesToPlot,pNamesToPlot), titName, {facesrh;faceslh}, {verticesrh;verticeslh}, COLVar, valSteps, bubbleSizeRecCh);
    % plot Stim channels - no face/vertex to plot on top of the other one

    % only keep stim channels
    [unStimChPName, indUn] = unique(strcat(stimChNamesToPlotAll,'_',pNamesToPlotAll),'stable');
    indContact2 = cell2mat(regexp(unStimChPName, '\d\D','once'))+1;
    stimContactsToPlot=cell(0,0);
    for iCh=1:length(unStimChPName)
        stimContactsToPlot{iCh,1} = strcat(unStimChPName{iCh}(1:indContact2(iCh)-1),'-',unStimChPName{iCh}(indContact2(iCh):end));
    end
    pNamesToPlot = pNamesToPlotAll(indUn);
    indPat=zeros(1,length(pNamesToPlot));
    for iP=1:length(pNamesToPlot)
        indPat(iP) = find(strcmp(pNames, pNamesToPlot{iP}));
    end
    plotVar= valSteps(indPat);

    plotValuesOnAtlasBrainAsBubbles(plotVar, fileNameRASInAtlas, stimContactsToPlot, titName, [], [], COLVar, valSteps, bubbleSizeStimCh);
    
    % save
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecStimElectrodes', [titNameFig, titName],'_sagital'])
    saveas(gcf,[dirImages,filesep, 'RecStimElectrodes',[titNameFig,titName],'.fig'])
    % change view and save again
    view(0,90)
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecStimElectrodes', [titNameFig, titName],'_axial'])
end

diary off;