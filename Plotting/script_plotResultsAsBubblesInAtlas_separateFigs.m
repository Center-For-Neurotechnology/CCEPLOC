function script_plotResultsAsBubblesInAtlas_separateFigs(dirGralResults,MRIDirectory, strDate)
% Plot variability, features,
% strDate is the date as it apppears in directory and xls files: 


xlsTablesDir = dirGralResults; %[gralPaperDir, filesep,'TablesForPlots'];

fileNameRASInAtlas =  [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'atlasColin27_Neuron2023_AllRAS_20.mat'];

warning('off')

maxVal = 0.7;
thVal = 0.15;

dirImages = [dirGralResults, filesep,'plotsLOCpaper_Neuron2023',filesep,'plotsPerStimCh_OnAtlas_ManyFigs',num2str(thVal),'to',num2str(maxVal),'_',date]; %MaxAt05'];
if ~exist(dirImages,'dir'),mkdir(dirImages); end
diary ([dirImages,filesep,'logDistributionMeanOnAtlas',num2str(thVal),'to',num2str(maxVal)])


%% Combine regions with few events
regionsToCombine=cell(0,0);


%% Plot Gral info
%COL=colormap(hsv(length(Patients)));
% COL2=colormap(colorcube(27));
%% Plot Measures on brain surface
%COLVar2=colormap(hsv(100))*.8;
% Colormaps
COLVar2=(colormap(bipolar2(200,0.49))+.5)/1.5;

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
figure;imagesc(valSteps,valSteps,valSteps);colormap(COLVar);

print(gcf,'-dpng','-r300',[dirImages, filesep,'ColorMap'])
saveas(gcf,[dirImages,filesep, 'ColorMap','.fig'])
saveas(gcf,[dirImages,filesep, 'ColorMap','.svg'])

%COLBASE=[.9 .9 .9];
faceAlphaVal = 1; %0.7
faceAlphaValBkg = 0.7; % use this for cortical region in the background to highlight subcortical regions
bubbleSize = 600; % size of bubbles in plot

[verticesrh, facesrh] = read_ply([MRIDirectory,'rh.pial.ply']);
[verticeslh, faceslh] = read_ply([MRIDirectory,'lh.pial.ply']);
LeftHemisDir=[MRIDirectory,filesep,'aparc.DKTatlas40.pial.lh\'];
RightHemisDir= [MRIDirectory,filesep,'aparc.DKTatlas40.pial.rh\'];
SubcorticalDir= [MRIDirectory,filesep,'subcortical\'];

%% relate Plia values with regions used in this project - for this ONLY the classification - we could remove and add the target names back
[CategoryLeftStr, FaceLabelLeft, VertexLabelLeft, CombinedRegionAccr] = configAtlasForMeasPlots(LeftHemisDir, regionsToCombine); % Left Plia

%[CategoryRightStr, FaceLabelRight, VertexLabelRight, CombinedRegionAccr] = configAtlasForMeasPlots(RightHemisDir, regionsToCombine); % Right Plia

%[CategorySubcortStr, FaceLabelSubcort, VertexLabelSubcort, CombinedRegionAccr] = configAtlasForMeasPlots(SubcorticalDir, regionsToCombine); % Subcortical Regions

nCombRegions = length(CombinedRegionAccr);


disp(['Possible Regions: ',num2str(nCombRegions)])
disp(unique(CombinedRegionAccr,'stable'))



%% ----------------------------------------------------------
%% UNTIL NOW CONFIGURATION - HERE the REAL PLOTTING starts
%% ----------------------------------------------------------

%% STIM based averages Relative measures (Complexity, CCEP connectivity, stim averaged variability)
titNameFig = 'RelStim';
fileNameWithVals = [xlsTablesDir, filesep,'summaryDetailsRelStimInfo_StimCh_20pat_',strDate,'.xlsx'];
SheetList={'WakeORWakeEMU','SleepWakeEMU','AnesthesiaWakeOR'};
measNames = {'relPCI','rel%Resp','meanRelVar'};
condColFeat{1} = 'E'; % 'Relative PCI'
condColFeat{2} = 'G'; % 'Relative % resp channels'
condColFeat{3} = 'J'; % 'Relative mean Variability'
firstRow=4;
colWithAnat = 3; % which column has the anatomical information
colChName = 1; % the column with the channel names
nCompPlots =length(SheetList);

scrsz = get(groot,'ScreenSize');
for iFeat=1:length(condColFeat)
    
 %   figure('Name', [titNameFig, measNames{iFeat}], 'Position',[1 1 scrsz(3) scrsz(4)]);
    
    for iSheet=1:nCompPlots
        %A. Read text information
        C=readtable(fileNameWithVals,'Sheet',SheetList{iSheet});
        %         chNamesStim = table2cell(C(firstRow:end,1));
        %         pNames = table2cell(C(firstRow:end,2));
        anatLocation = table2cell(C(firstRow:end,colWithAnat));
        chNamesToPlot = table2cell(C(firstRow:end,colChName));
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
        [medianVal,meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,[anatLocationsToGroup ],{'nanmedian','nanmean','sem','numel','gname'});
        disp([SheetList{iSheet}, measNames{iFeat}])
        disp([{'AnatRegion','n','Median','Mean','SEM'}])
        disp([gname, num2cell(nPerGroup),num2cell(medianVal),num2cell(meanVal), num2cell(SE)])
        
        %C. Plot
        titName = [measNames{iFeat}, SheetList{iSheet}];
        figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
        plotValuesOnAtlasBrainAsBubbles(plotVar, fileNameRASInAtlas, chNamesToPlot, titName, {facesrh;faceslh}, {verticesrh;verticeslh}, COLVar, valSteps, bubbleSize);
        print(gcf,'-dpng','-r300',[dirImages,filesep, 'StimElectrodes', [titNameFig, titName],'_sagital'])
        saveas(gcf,[dirImages,filesep, 'StimElectrodes',[titNameFig,titName],'.fig'])
        % change view and save again
            view(0,90)
        print(gcf,'-dpng','-r300',[dirImages,filesep, 'StimElectrodes', [titNameFig, titName],'_axial'])
        
    end
    
    % Save in 1 figure
    %     print(gcf,'-dpng','-r300',[dirImages,filesep, 'StimElectrodes', [titNameFig, measNames{iFeat}]])
    %     saveas(gcf,[dirImages,filesep, 'StimElectrodes',[titNameFig, measNames{iFeat}],'.fig'])
end




diary off;