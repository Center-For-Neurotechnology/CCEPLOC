function script_plotResultsAsDifferencePerRegionInAtlas(dirGralResults, MRIDirectory, strDate, posFixDir)
% Plot variability, features,
if ~exist('posFixDir','var'),posFixDir='';end

xlsTablesDir = dirGralResults; %[gralPaperDir, filesep,'TablesForPlots'];

warning('off')

maxVal = 0.7;
thVal = 0;

dirImages = [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'plotsDiffMeanOnAtlas',num2str(thVal),'to',num2str(maxVal),'_',date, posFixDir]; %MaxAt05'];
if ~exist(dirImages,'dir'),mkdir(dirImages); end
diary ([dirImages,filesep,'logDistributionDiffOnAtlas',num2str(thVal),'to',num2str(maxVal)])


%% Combine regions with few events
% Combine Calcarine/Cuneus SupMarg/PreCun / etc.
regionsToCombine=cell(0,0);
regionsToCombine{1} = {'Cun','Occ'}; % has to be in pairs to combine more add another line
regionsToCombine{2} = {'Calcar','Occ'}; % has to be in pairs to combine more add another line
regionsToCombine{3} = {'SupMar','Pari'};
regionsToCombine{4} = {'mOFC','lOFC'};
regionsToCombine{5} = {'rACC','cACC'};
regionsToCombine{6} = {'isCC','pCC'};
regionsToCombine{7} = {'Caud','Putam'};
regionsToCombine{8} = {'preC','Pari'};
regionsToCombine{9} = {'Ling','Occ'}; % has to be in pairs to combine more add another line

%% Plot Gral info
%COL=colormap(hsv(length(Patients)));
% COL2=colormap(colorcube(27));
%% Plot Measures on brain surface
% Colormaps
COLVar2=(colormap(bipolar2(200,0.49))+.5)/1.5;

durWithPadding= round(size(COLVar2,1)/maxVal); % e.g. for 0.8 100/0.8 
perSideMaxExtraPadding = round(durWithPadding*((1-maxVal)/2)); % e.g. (100/0.8)*(0.2/2)
perSideThGraying = floor(durWithPadding*(thVal)/2); % e.g. (100/0.8)*(0.2/2)
halfPt = round(durWithPadding/2);
COLVar1=[repmat(COLVar2(1,:),perSideMaxExtraPadding,1);COLVar2;repmat(COLVar2(end,:),perSideMaxExtraPadding,1)]; % 0.8 and above is yellow / -0.8 and below is cyan -> this is just to expand the colorbar
if thVal>0
    COLVar =[COLVar1(1:halfPt-perSideThGraying-1,:); repmat(COLVar1(halfPt,:),2*perSideThGraying,1); COLVar1(halfPt+perSideThGraying:end,:)]; % to make -0.2 to +0.2 in gray
else
    COLVar =COLVar1;
end
valSteps = linspace(-1,1,size(COLVar, 1));

%COLBASE=[.9 .9 .9];
faceAlphaVal = 1; %0.7
faceAlphaValBkg = 0.7; % use this for cortical region in the background to highlight subcortical regions
figure;imagesc(valSteps,valSteps,valSteps);colormap(COLVar);
print(gcf,'-dpng','-r300',[dirImages, filesep,'ColorMap'])
saveas(gcf,[dirImages,filesep, 'ColorMap','.fig'])
saveas(gcf,[dirImages,filesep, 'ColorMap','.svg'])

%[verticesrh, facesrh] = read_ply([MRIDirectory,'rh.pial.ply']);
%[verticeslh, faceslh] = read_ply([MRIDirectory,'lh.pial.ply']);
LeftHemisDir=[MRIDirectory,filesep,'aparc.DKTatlas40.pial.lh\'];
RightHemisDir= [MRIDirectory,filesep,'aparc.DKTatlas40.pial.rh\'];
SubcorticalDir= [MRIDirectory,filesep,'subcortical\'];


%% relate Plia values with regions used in this project
[CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, CombinedRegionAccr] = configAtlasForMeasPlots(LeftHemisDir, regionsToCombine); % Left Plia

[CategoryRightStr, FaceLabelRight, VertexLabelRight, CombinedRegionAccr] = configAtlasForMeasPlots(RightHemisDir, regionsToCombine); % Right Plia

[CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, CombinedRegionAccr] = configAtlasForMeasPlots(SubcorticalDir, regionsToCombine); % Subcortical Regions

nCombRegions = length(CombinedRegionAccr);

%% ----------------------------------------------------------
%% UNTIL NOW CONFIGURATION - HERE the REAL PLOTTING starts
%% ----------------------------------------------------------

%% Variability
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelVar'; %'RelCCEPVar';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesVariability_all.xlsx'];
SheetList={'RelCCEPVar WakeORWakeEMU','RelCCEPVar SleepWakeEMU','RelCCEPVar AnesthesiaWakeOR'};
VarNames = {'CCEPVar', 'BASELINEVar'};
condColVar{1} = 'E'; % 'RelCCEPVar' - 'E'; %
condColVar{2} = 'F'; % 'RelBASELINEVar' - 'E'; %
firstRow=3;
colWithAnat = 4; % which column in the xls has the anatomical info
nCompPlots =length(SheetList);
 
indCompPairs = [2 3];

for iVar=1:length(condColVar)
    compStr = [titNameFig,' ', VarNames{iVar},' Diff Anest - Sleep'];
    disp(compStr)
    % get values
    medianVals = zeros(nCompPlots, nCombRegions);
    meanVals = zeros(nCompPlots, nCombRegions);
    seVals = zeros(nCompPlots, nCombRegions);
    nPerGroups = zeros(nCompPlots, nCombRegions);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
        %     chNamesRec = table2cell(C(firstRow:end,1));
        %     chNamesStim = table2cell(C(firstRow:end,2));
        %     pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        % Combine anat regions
        anatLocationsToGroup = anatLocation;
        for iReg=1:numel(regionsToCombine)
            anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
        end
        
        %B.  Read Values information
        condXlsCol = [condColVar{iVar},num2str(firstRow),':',condColVar{iVar},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
        %plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(featVals,[anatLocationsToGroup ],{'nanmedian','nanmean','sem','numel','gname'});
        disp(SheetList{iSheet})
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        for iRegion=1:length(gname)
            indInRegion=find(strcmpi(CombinedRegionAccr, gname{iRegion}));
            medianVals(iSheet,indInRegion) = medianVal(iRegion);
            meanVals(iSheet,indInRegion) = meanVal(iRegion);
            seVals(iSheet,indInRegion) = SE(iRegion);
            nPerGroups(iSheet,indInRegion) = nPerGroup(iRegion);
        end
    end
    %C. Compute differences
    DiffMean = meanVals(indCompPairs(2),:) -  meanVals(indCompPairs(1),:);
    DiffMedian = medianVals(indCompPairs(2),:) -  medianVals(indCompPairs(1),:);
    % remove empty groups
    emptyRegion = find((nPerGroups(indCompPairs(1),:)==0) + (nPerGroups(indCompPairs(2),:)==0));
    anatLocationsToPlot =CombinedRegionAccr;
    anatLocationsToPlot(emptyRegion)={'empty'};
    disp([{'AnatRegion','Mean','Median'}])
    disp([anatLocationsToPlot, num2cell(DiffMean'), num2cell(DiffMedian')])
    plotVar = DiffMean;
    
    %D. Plot Difference!
    titName = [compStr]; % SheetList{iSheet};
    % Plot Left, Right and subcortical together
    scrsz = get(groot,'ScreenSize');
    figure('Name', [titNameFig,VarNames{iVar}], 'Position',[1 1 scrsz(3) scrsz(4)]);
    %subplot(2,nCompPlots,iSheet); % top row
    subplot(2,1,1); % top row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Plot  subcortical and Left with lower alphaVal to highlight subcortical
    subplot(2,1,2); % bottom row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages, filesep,'Diff_RecElect', titNameFig,VarNames{iVar}])
    saveas(gcf,[dirImages,filesep, 'Diff_RecElect',titNameFig,VarNames{iVar},'.fig'])
    
end
    
%% Features - channels with responses in ANY STATE
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelFeatANY';%'RelFeat';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPFeatures_ANYSTATE_all.xlsx'];
SheetList={'RelFeat WakeORWakeEMU','RelFeat SleepWakeEMU','RelFeat AnesthesiaWakeOR'};
%featNames = {'RelP2PAmp','RelLat1stPeak','RellocMaxPeakRespCh'};
%featNames = {'RelP2PAmp'}; %,'RelLat1stPeak','RellocMaxPeakRespCh'};
clear condColFeat;
condColFeat{1} = 'F'; % 'Relative PTP' // ReldataMaxMinAmp
%condColFeat{2} = 'G'; % 'Relative Latency 1st peak' //RelavPeakAreaPerCh
%condColFeat{3} = 'H'; % 'Relative Latency MsAX peak' //RelpeakAmp
firstRow=3;
colWithAnat = 4; % which column has the anatomical information
colWith1Feat=6;
nCompPlots =length(SheetList);

indCompPairs = [2 3];
compStr = [titNameFig,' Diff Anest - Sleep'];

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    medianVals = zeros(nCompPlots, nCombRegions);
    meanVals = zeros(nCompPlots, nCombRegions);
    seVals = zeros(nCompPlots, nCombRegions);
    nPerGroups = zeros(nCompPlots, nCombRegions);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
%         chNamesRec = table2cell(C(firstRow:end,1));
%         chNamesStim = table2cell(C(firstRow:end,2));
%         pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        featName = table2cell(C(firstRow-1,colWith1Feat-1+iFeat));
        featName = [featName{:}];
    % Combine anat regions
    anatLocationsToGroup = anatLocation;
    for iReg=1:numel(regionsToCombine)
        anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
    end
        
        %B.  Read Values information
        condXlsCol = [condColFeat{iFeat},num2str(firstRow),':',condColFeat{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
       % plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(featVals,[anatLocationsToGroup(1:length(featVals)) ],{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet},featName])
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        for iRegion=1:length(gname)
            indInRegion=find(strcmpi(CombinedRegionAccr, gname{iRegion}));
            medianVals(iSheet,indInRegion) = medianVal(iRegion);
            meanVals(iSheet,indInRegion) = meanVal(iRegion);
            seVals(iSheet,indInRegion) = SE(iRegion);
            nPerGroups(iSheet,indInRegion) = nPerGroup(iRegion);
        end
    end
    %C. Compute differences
    DiffMean = meanVals(indCompPairs(2),:) -  meanVals(indCompPairs(1),:);
    DiffMedian = medianVals(indCompPairs(2),:) -  medianVals(indCompPairs(1),:);
    % remove empty groups
    emptyRegion = find((nPerGroups(indCompPairs(1),:)==0) + (nPerGroups(indCompPairs(2),:)==0));
    anatLocationsToPlot =CombinedRegionAccr;
    anatLocationsToPlot(emptyRegion)={'empty'};
    disp([{'AnatRegion','Mean','Median'}])
    disp([anatLocationsToPlot, num2cell(DiffMean'), num2cell(DiffMedian')])
    plotVar = DiffMean;

    %D. Plot
    titName = [featName, compStr];
    figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
    %subplot(2,nCompPlots,iSheet); % top row
    subplot(2,1,1); % top row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Plot  subcortical and Left with lower alphaVal to highlight subcortical
    subplot(2,1,2); % bottom row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'Diff_RecElect', [titNameFig, featName]])
    saveas(gcf,[dirImages,filesep, 'Diff_RecElect',[titNameFig, featName],'.fig'])
end

%% Features - channels with responses in ALL STATES
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelFeat';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPFeatures_RespCh_all.xlsx'];
SheetList={'RelFeat WakeORWakeEMU','RelFeat SleepWakeEMU','RelFeat AnesthesiaWakeOR'};
%featNames = {'RelP2PAmp','RelLat1stPeak','RellocMaxPeakRespCh'};
%featNames = {'RelP2PAmp'}; %,'RelLat1stPeak','RellocMaxPeakRespCh'};
clear condColVar;
condColFeat{1} = 'F'; % 'Relative PTP' // ReldataMaxMinAmp
%condColFeat{2} = 'G'; % 'Relative Latency 1st peak' //RelpeakAmp
%condColFeat{3} = 'G'; % 'Relative Latency MsAX peak' //RelavPeakAreaPerCh
firstRow=3;
colWithAnat = 4; % which column has the anatomical information
colWith1Feat = 6;
nCompPlots =length(SheetList);

indCompPairs = [2 3];
compStr = [titNameFig,' Diff Anest - Sleep'];

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    medianVals = zeros(nCompPlots, nCombRegions);
    meanVals = zeros(nCompPlots, nCombRegions);
    seVals = zeros(nCompPlots, nCombRegions);
    nPerGroups = zeros(nCompPlots, nCombRegions);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
%         chNamesRec = table2cell(C(firstRow:end,1));
%         chNamesStim = table2cell(C(firstRow:end,2));
%         pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        featName = table2cell(C(firstRow-1,colWith1Feat-1+iFeat));
        featName = [featName{:}];
    % Combine anat regions
    anatLocationsToGroup = anatLocation;
    for iReg=1:numel(regionsToCombine)
        anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
    end
        
        %B.  Read Values information
        condXlsCol = [condColFeat{iFeat},num2str(firstRow),':',condColFeat{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
       % plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(featVals,[anatLocationsToGroup(1:length(featVals)) ],{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet},featName])
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        for iRegion=1:length(gname)
            indInRegion=find(strcmpi(CombinedRegionAccr, gname{iRegion}));
            medianVals(iSheet,indInRegion) = medianVal(iRegion);
            meanVals(iSheet,indInRegion) = meanVal(iRegion);
            seVals(iSheet,indInRegion) = SE(iRegion);
            nPerGroups(iSheet,indInRegion) = nPerGroup(iRegion);
        end
    end
    %C. Compute differences
    DiffMean = meanVals(indCompPairs(2),:) -  meanVals(indCompPairs(1),:);
    DiffMedian = medianVals(indCompPairs(2),:) -  medianVals(indCompPairs(1),:);
    % remove empty groups
    emptyRegion = find((nPerGroups(indCompPairs(1),:)==0) + (nPerGroups(indCompPairs(2),:)==0));
    anatLocationsToPlot =CombinedRegionAccr;
    anatLocationsToPlot(emptyRegion)={'empty'};
    disp([{'AnatRegion','Mean','Median'}])
    disp([anatLocationsToPlot, num2cell(DiffMean'), num2cell(DiffMedian')])
    plotVar = DiffMean;

    %D. Plot
    titName = [featName, compStr];
    figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
    %subplot(2,nCompPlots,iSheet); % top row
    subplot(2,1,1); % top row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Plot  subcortical and Left with lower alphaVal to highlight subcortical
    subplot(2,1,2); % bottom row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'Diff_RecElect', [titNameFig, featName]])
    saveas(gcf,[dirImages,filesep, 'Diff_RecElect',[titNameFig, featName],'.fig'])
end

%% Features - channels with responses in ANY STATE
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelCentr';%'RelFeat';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPCentrality_ANYState_all.xlsx'];
SheetList={'RelFeat WakeORWakeEMU','RelFeat SleepWakeEMU','RelFeat AnesthesiaWakeOR'};
%featNames = {'RelP2PAmp','RelLat1stPeak','RellocMaxPeakRespCh'};
%featNames = {'RelP2PAmp'}; %,'RelLat1stPeak','RellocMaxPeakRespCh'};
clear condColVar;
condColFeat{1} = 'E'; % 'Relative PTP' // ReldataMaxMinAmp
%condColFeat{2} = 'F'; % 'Relative Latency 1st peak' //RelpeakAmp
%condColFeat{3} = 'G'; % 'Relative Latency MsAX peak' //RelavPeakAreaPerCh
firstRow=3;
colWithAnat = 4; % which column has the anatomical information
colWith1Feat=5;
nCompPlots =length(SheetList);

indCompPairs = [2 3];
compStr = [titNameFig,' Diff Anest - Sleep'];

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    medianVals = zeros(nCompPlots, nCombRegions);
    meanVals = zeros(nCompPlots, nCombRegions);
    seVals = zeros(nCompPlots, nCombRegions);
    nPerGroups = zeros(nCompPlots, nCombRegions);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
%         chNamesRec = table2cell(C(firstRow:end,1));
%         chNamesStim = table2cell(C(firstRow:end,2));
%         pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
%        featName = table2cell(C(firstRow-1,colWithAnat+iFeat));
        featName = table2cell(C(firstRow-1,colWith1Feat-1+iFeat));
        featName = [featName{:}];
    % Combine anat regions
    anatLocationsToGroup = anatLocation;
    for iReg=1:numel(regionsToCombine)
        anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
    end
        
        %B.  Read Values information
        condXlsCol = [condColFeat{iFeat},num2str(firstRow),':',condColFeat{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
       % plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(featVals,[anatLocationsToGroup(1:length(featVals)) ],{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet},featName])
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        for iRegion=1:length(gname)
            indInRegion=find(strcmpi(CombinedRegionAccr, gname{iRegion}));
            medianVals(iSheet,indInRegion) = medianVal(iRegion);
            meanVals(iSheet,indInRegion) = meanVal(iRegion);
            seVals(iSheet,indInRegion) = SE(iRegion);
            nPerGroups(iSheet,indInRegion) = nPerGroup(iRegion);
        end
    end
    %C. Compute differences
    DiffMean = meanVals(indCompPairs(2),:) -  meanVals(indCompPairs(1),:);
    DiffMedian = medianVals(indCompPairs(2),:) -  medianVals(indCompPairs(1),:);
    % remove empty groups
    emptyRegion = find((nPerGroups(indCompPairs(1),:)==0) + (nPerGroups(indCompPairs(2),:)==0));
    anatLocationsToPlot =CombinedRegionAccr;
    anatLocationsToPlot(emptyRegion)={'empty'};
    disp([{'AnatRegion','Mean','Median'}])
    disp([anatLocationsToPlot, num2cell(DiffMean'), num2cell(DiffMedian')])
    plotVar = DiffMean;

    %D. Plot
    titName = [featName, compStr];
    figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
    %subplot(2,nCompPlots,iSheet); % top row
    subplot(2,1,1); % top row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Plot  subcortical and Left with lower alphaVal to highlight subcortical
    subplot(2,1,2); % bottom row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'Diff_RecElect', [titNameFig, featName]])
    saveas(gcf,[dirImages,filesep, 'Diff_RecElect',[titNameFig, featName],'.fig'])
end


%% STIM based averages Relative measures (Complexity, CCEP connectivity, stim averaged variability)
titNameFig = 'RelStim';
fileNameWithVals = [xlsTablesDir, filesep,'summaryDetailsRelStimInfo_StimCh_20pat_',strDate,'.xlsx'];
SheetList={'WakeORWakeEMU','SleepWakeEMU','AnesthesiaWakeOR'};
measNames = {'relPCI','rel%Resp','meanRelVar'};
clear condColVar;
condColFeat{1} = 'E'; % 'Relative PCI'
condColFeat{2} = 'G'; % 'Relative % resp channels'
condColFeat{3} = 'J'; % 'Relative mean Variability'
firstRow=4;
colWithAnat = 3; % which column has the anatomical information
nCompPlots =length(SheetList);

indCompPairs = [2 3];
compStr = [titNameFig,' Diff Anest - Sleep'];


scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    medianVals = zeros(nCompPlots, nCombRegions);
    meanVals = zeros(nCompPlots, nCombRegions);
    seVals = zeros(nCompPlots, nCombRegions);
    nPerGroups = zeros(nCompPlots, nCombRegions);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
        %         chNamesStim = table2cell(C(firstRow:end,1));
        %         pNames = table2cell(C(firstRow:end,2));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        % Combine anat regions
        anatLocationsToGroup = anatLocation;
        for iReg=1:numel(regionsToCombine)
            anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
        end
        
        %B.  Read Values information
        condXlsCol = [condColFeat{iFeat},num2str(firstRow),':',condColFeat{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
       % plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(featVals,[anatLocationsToGroup ],{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet}, measNames{iFeat}])
        disp([{'AnatRegion','n','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        for iRegion=1:length(gname)
            indInRegion=find(strcmpi(CombinedRegionAccr, gname{iRegion}));
            medianVals(iSheet,indInRegion) = medianVal(iRegion);
            meanVals(iSheet,indInRegion) = meanVal(iRegion);
            seVals(iSheet,indInRegion) = SE(iRegion);
            nPerGroups(iSheet,indInRegion) = nPerGroup(iRegion);
        end
    end
    %C. Compute differences
    DiffMean = meanVals(indCompPairs(2),:) -  meanVals(indCompPairs(1),:);
    DiffMedian = medianVals(indCompPairs(2),:) -  medianVals(indCompPairs(1),:);
    % remove empty groups
    emptyRegion = find((nPerGroups(indCompPairs(1),:)==0) + (nPerGroups(indCompPairs(2),:)==0));
    anatLocationsToPlot =CombinedRegionAccr;
    anatLocationsToPlot(emptyRegion)={'empty'};
    disp([{'AnatRegion','Mean','Median'}])
    disp([anatLocationsToPlot, num2cell(DiffMean'), num2cell(DiffMedian')])
    plotVar = DiffMean;
    
    %D. Plot
    titName = [measNames{iFeat}, compStr];
    % Plot Left, Right and subcortical together
    figure('Name', [titNameFig, measNames{iFeat}], 'Position',[1 1 scrsz(3) scrsz(4)]);
    %subplot(2,nCompPlots,iSheet); % top row
    subplot(2,1,1); % top row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Plot  subcortical and Left with lower alphaVal to highlight subcortical
    subplot(2,1,2); % bottom row
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
    plotValuesOnAtlasBrain(plotVar, anatLocationsToPlot, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'Diff_StimElect', [titNameFig, measNames{iFeat}]])
    saveas(gcf,[dirImages,filesep, 'Diff_StimElect',[titNameFig, measNames{iFeat}],'.fig'])
end

diary off;