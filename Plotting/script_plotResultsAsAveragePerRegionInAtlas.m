function script_plotResultsAsAveragePerRegionInAtlas(dirGralResults, MRIDirectory, strDate, posFixDir)
% Plot variability, features,
% strDate is the date as it apppears in directory and xls files: 22-Aug-2022
if ~exist('posFixDir','var'),posFixDir='';end
xlsTablesDir = dirGralResults; %[gralPaperDir, filesep,'TablesForPlots'];

warning('off')

maxVal = 0.6;
thVal = 0.15;

dirImages = [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'plotsAllRegionsMeanOnAtlas_',num2str(thVal),'to',num2str(maxVal),'_',date,posFixDir]; %MaxAt05'];
if ~exist(dirImages,'dir'),mkdir(dirImages); end
diary ([dirImages,filesep,'logDistributionMeanOnAtlas',num2str(thVal),'to',num2str(maxVal)])


%% Combine regions with few events
% Combine Calcarine/Cuneus SupMarg/PreCun etc.
regionsToCombine=cell(0,0);
regionsToCombine{1} = {'Cun','Occ'}; % has to be in pairs to combine more add another line
regionsToCombine{2} = {'Calcar','Occ'}; % has to be in pairs to combine more add another line
regionsToCombine{3} = {'SupMar','Pari'};
regionsToCombine{4} = {'mOFC','lOFC'};
regionsToCombine{5} = {'rACC','cACC'};
regionsToCombine{6} = {'isCC','pCC'};
regionsToCombine{7} = {'preC','Pari'};
regionsToCombine{8} = {'Caud','Putam'};
regionsToCombine{9} = {'Ling','Occ'}; % has to be in pairs to combine more add another line
% 

%% Plot Gral info
%COL=colormap(hsv(length(Patients)));
% COL2=colormap(colorcube(27));
%% Plot Measures on brain surface
%COLVar2=colormap(hsv(100))*.8;
% Colormaps
COLVar2=(colormap(bipolar2(100,0.49))+.5)/1.5;

% values -0.15 to 0.15 are thresholded (gray) / values above 0.6 are maxed out
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
colormap(COLVar);

%COLBASE=[.9 .9 .9];
faceAlphaVal = 1; %0.7
faceAlphaValBkg = 0.7; % use this for cortical region in the background to highlight subcortical regions

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


disp(['Possible Regions: ',num2str(nCombRegions)])
disp(unique(CombinedRegionAccr,'stable'))


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

scrsz = get(groot,'ScreenSize');
for iVar=1:length(condColVar)
    figure('Name', [titNameFig,VarNames{iVar}], 'Position',[1 1 scrsz(3) scrsz(4)]);
    
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
        plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,anatLocationsToGroup(1:length(plotVar)),{'nanmedian','nanmean','sem','numel','gname'});
        disp(SheetList{iSheet})
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        
        %C. Plot
        titName = [SheetList{iSheet},' ', VarNames{iVar}, ' r=', num2str(sum(nPerGroup))];
        % Plot Left, Right and subcortical together
        subplot(2,nCompPlots,iSheet); % top row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
        % print(gcf,'-dpng','-r300',[dirImages, filesep,'RecordingElectrodes', titNameFig, ])
        % saveas(gcf,[dirImages,filesep, 'RecordingElectrodes',titNameFig,'.fig'])
        
        % Plot  subcortical and Left with lower alphaVal to highlight subcortical
        subplot(2,nCompPlots,iSheet+nCompPlots); % bottom row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    end
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages, filesep,'RecordingElectrodes', titNameFig,VarNames{iVar}])
    saveas(gcf,[dirImages,filesep, 'RecordingElectrodes',titNameFig,VarNames{iVar},'.fig'])
    
end
    
%% Features with ch rresponsive in ANY state
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelFeatANYSTATE';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPFeatures_ANYSTATE_all.xlsx'];
SheetList={'RelFeat WakeEMUWakeOR','RelFeat WakeEMUSleep','RelFeat WakeORAnesthesia'};
%featNames = {'RelP2PAmp','RelLat1stPeak','RellocMaxPeakRespCh'};
%featNames = {'RelP2PAmp'}; %,'RelLat1stPeak','RellocMaxPeakRespCh'}; // ReldataMaxMinAmp	RelpeakAmp	RelavPeakAreaPerCh
clear condColVar;
condColFeat{1} = 'E'; % 'Relative PTP' // ReldataMaxMinAmp
condColFeat{2} = 'F'; % 'Relative Latency 1st peak' //RelpeakAmp
%condColFeat{3} = 'G'; % 'Relative Latency MsAX peak' //RelavPeakAreaPerCh
firstRow=3;
colWithAnat = 4; % which column has the anatomical information
nCompPlots =length(SheetList);

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    figure('Name', [titNameFig], 'Position',[1 1 scrsz(3) scrsz(4)]);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
        %         chNamesRec = table2cell(C(firstRow:end,1));
        %         chNamesStim = table2cell(C(firstRow:end,2));
        %         pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        featName = table2cell(C(firstRow-1,colWithAnat+iFeat));
        featName = [featName{:}];
        % Combine anat regions
        anatLocationsToGroup = anatLocation;
        for iReg=1:numel(regionsToCombine)
            anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
        end
        
        %B.  Read Values information
        condXlsCol = [condColFeat{iFeat},num2str(firstRow),':',condColFeat{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
        plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,anatLocationsToGroup(1:length(plotVar)),{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet}, featName])
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        
        %C. Plot
        titName = [featName, SheetList{iSheet}, ' r=', num2str(sum(nPerGroup))];
        % Plot Left, Right and subcortical together
        subplot(2,nCompPlots,iSheet); % top row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
        
        % Plot  subcortical and Left with lower alphaVal to highlight subcortical
        subplot(2,nCompPlots,iSheet+nCompPlots); % bottom row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    end
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecordingElectrodes', [titNameFig, featName]])
    saveas(gcf,[dirImages,filesep, 'RecordingElectrodes',[titNameFig, featName],'.fig'])
end

%% Features with ch rresponsive in BOTH states
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelFeat';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPFeatures_RespCh_all.xlsx'];
SheetList={'RelFeat WakeEMUWakeOR','RelFeat WakeEMUSleep','RelFeat WakeORAnesthesia'};
%featNames = {'RelP2PAmp','RelLat1stPeak','RellocMaxPeakRespCh'};
%featNames = {'RelP2PAmp'}; %,'RelLat1stPeak','RellocMaxPeakRespCh'}; // ReldataMaxMinAmp	RelpeakAmp	RelavPeakAreaPerCh
clear condColFeat;
condColFeat{1} = 'E'; % 'Relative PTP' // ReldataMaxMinAmp
%condColFeat{2} = 'F'; % 'Relative Latency 1st peak' //RelpeakAmp
%condColFeat{3} = 'H'; % 'Relative Latency MsAX peak' //RelavPeakAreaPerCh
firstRow=3;
colWithAnat = 4; % which column has the anatomical information
nCompPlots =length(SheetList);

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    figure('Name', [titNameFig], 'Position',[1 1 scrsz(3) scrsz(4)]);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
        %         chNamesRec = table2cell(C(firstRow:end,1));
        %         chNamesStim = table2cell(C(firstRow:end,2));
        %         pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        featName = table2cell(C(firstRow-1,colWithAnat+iFeat));
        featName = [featName{:}];
        % Combine anat regions
        anatLocationsToGroup = anatLocation;
        for iReg=1:numel(regionsToCombine)
            anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
        end
        
        %B.  Read Values information
        condXlsCol = [condColFeat{iFeat},num2str(firstRow),':',condColFeat{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
        plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,anatLocationsToGroup(1:length(plotVar)),{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet}, featName])
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        
        %C. Plot
        titName = [featName, SheetList{iSheet}, ' r=', num2str(sum(nPerGroup))];
        % Plot Left, Right and subcortical together
        subplot(2,nCompPlots,iSheet); % top row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
        
        % Plot  subcortical and Left with lower alphaVal to highlight subcortical
        subplot(2,nCompPlots,iSheet+nCompPlots); % bottom row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    end
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecordingElectrodes', [titNameFig, featName]])
    saveas(gcf,[dirImages,filesep, 'RecordingElectrodes',[titNameFig, featName],'.fig'])
end

%% Features with ch rresponsive in BOTH states
% SheetList={'CCEPVar all WakeEMU','CCEPVar all Sleep','CCEPVar all WakeOR','CCEPVar all Anesthesia'};
titNameFig = 'RelCentrality';
fileNameWithVals = [xlsTablesDir, filesep,'ChannelNamesCCEPCentrality_ANYState_all.xlsx'];
SheetList={'RelFeat WakeEMUWakeOR','RelFeat WakeEMUSleep','RelFeat WakeORAnesthesia'};
%featNames = {'RelP2PAmp','RelLat1stPeak','RellocMaxPeakRespCh'};
%featNames = {'RelP2PAmp'}; %,'RelLat1stPeak','RellocMaxPeakRespCh'}; // ReldataMaxMinAmp	RelpeakAmp	RelavPeakAreaPerCh
clear condColVar;
condColCent{1} = 'E'; % 'Relative PTP' // ReldataMaxMinAmp
%condColFeat{2} = 'F'; % 'Relative Latency 1st peak' //RelpeakAmp
%condColFeat{3} = 'H'; % 'Relative Latency MsAX peak' //RelavPeakAreaPerCh
firstRow=3;
colWithAnat = 4; % which column has the anatomical information
nCompPlots =length(SheetList);
valSteps2 = linspace(-1,1,size(COLVar2, 1));

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColCent)
    figure('Name', [titNameFig], 'Position',[1 1 scrsz(3) scrsz(4)]);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
        %         chNamesRec = table2cell(C(firstRow:end,1));
        %         chNamesStim = table2cell(C(firstRow:end,2));
        %         pNames = table2cell(C(firstRow:end,3));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        featName = table2cell(C(firstRow-1,colWithAnat+iFeat));
        featName = [featName{:}];
        % Combine anat regions
        anatLocationsToGroup = anatLocation;
        for iReg=1:numel(regionsToCombine)
            anatLocationsToGroup(find(strcmp(anatLocation,regionsToCombine{iReg}{1}))) = regionsToCombine{iReg}(2);
        end
        
        %B.  Read Values information
        condXlsCol = [condColCent{iFeat},num2str(firstRow),':',condColCent{iFeat},num2str(size(C,1)+1)];
        featVals = xlsread(fileNameWithVals, SheetList{iSheet}, condXlsCol);
        plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,anatLocationsToGroup(1:length(plotVar)),{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet}, featName])
        disp([{'AnatRegion','r','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        
        %C. Plot
        titName = [featName, SheetList{iSheet}, ' r=', num2str(sum(nPerGroup))];
        % Plot Left, Right and subcortical together
        subplot(2,nCompPlots,iSheet); % top row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar2, valSteps2, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar2, valSteps2, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar2, valSteps2, faceAlphaVal);
        
        % Plot  subcortical and Left with lower alphaVal to highlight subcortical
        subplot(2,nCompPlots,iSheet+nCompPlots); % bottom row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar2, valSteps2, faceAlphaValBkg);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    end
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'RecordingElectrodes', [titNameFig, featName]])
    saveas(gcf,[dirImages,filesep, 'RecordingElectrodes',[titNameFig, featName],'.fig'])
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

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    
    figure('Name', [titNameFig, measNames{iFeat}], 'Position',[1 1 scrsz(3) scrsz(4)]);
    
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
        plotVar=featVals;
        
        % show values
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,anatLocationsToGroup(1:length(plotVar)),{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet}, measNames{iFeat}])
        disp([{'AnatRegion','n','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        
        %C. Plot
        titName = [measNames{iFeat}, SheetList{iSheet}, ' s=', num2str(sum(nPerGroup))];
        % Plot Left, Right and subcortical together
        subplot(2,nCompPlots,iSheet); % top row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryRightStr, FaceLabelRight, VertexLabelRight, COLVar, valSteps, faceAlphaVal);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
        
        % Plot  subcortical and Left with lower alphaVal to highlight subcortical
        subplot(2,nCompPlots,iSheet+nCompPlots); % bottom row
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, COLVar, valSteps, faceAlphaValBkg);
        plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, COLVar, valSteps, faceAlphaVal);
    end
    
    % Save in 1 figure
    print(gcf,'-dpng','-r300',[dirImages,filesep, 'StimElectrodes', [titNameFig, measNames{iFeat}]])
    saveas(gcf,[dirImages,filesep, 'StimElectrodes',[titNameFig, measNames{iFeat}],'.fig'])
end

diary off;