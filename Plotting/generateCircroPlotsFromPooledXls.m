function generateCircroPlotsFromPooledXls(dirCircroPlots, regionName, timeStr, posFixFile, gralCircroInfoFile)

dirCircroPlotsXls = [dirCircroPlots, filesep, 'xlsFiles'];
dirCircroPlotsImages = [dirCircroPlots, filesep, 'images', filesep, regionName];
if ~isdir(dirCircroPlotsImages), mkdir(dirCircroPlotsImages); end

%stimChannels = {'LFO10-LFO09'    'LA_5-LA_4'           'RPI6-RPI5' 'RMI08-RMI07'}; %'RFC3-RFC4' 
%timeStr = '10-600';
%varNames = {'chNamesPerStim', 'anatRegions', 'isChResp', 'ampRespCh','ampOnlyRespCh', 'distRecToStimCh','colorPerCh','latencyOnlyRespCh'};
if ~exist('posFixFile','var')
    posFixFile = '_perLobeStimCh';%'_perStimCh' %'_perGralRegionStimCh'
end

chNameStr = 'chNamesPerStim';
anatRegionsStr = 'anatRegions';
lobeRegionsStr = 'lobeRegions'; %'anatRegions';
gralRegionsStr = 'gralRegions'; %'anatRegions';
latencyStr = 'latencyOnlyRespCh';

colorStr1 = 'indGralRegionPerCh'; % Gral region % other options: %'distRecToStimCh'; % use dist to stim as color coding
colorStr2 = 'indLobeRegionPerCh'; % lobe region index (to use as color)
% colorStr2 = 'indRegionPerCh'; % % index region per channel (to use as color)

edgesStr = 'indStimOnlyRespPerStim'; %'indStimPerStim'; %'isChResp'; %'ampOnlyRespCh_Max10_';% 'ampOnlyRespCh'; %'isChResp'; % 'ampRespCh'; %'ampRespCh'; %

if exist(gralCircroInfoFile,'file')
    load(gralCircroInfoFile,'TargetLabels','TargetLabelsAccr','allStates','lobeRegionNames','gralRegionNames','minmaxVals');
else
    lobeRegionNames = {'dmvPFC','OF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};
    gralRegionNames = {'prefrontal','ACC','central','temporal','posterior','subcortical','thalCaud','WM'};
    allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
    minmaxVals.nStimChannels = [0 64];
end

colorBarNames1 = gralRegionNames;
colorBarNames2 = lobeRegionNames; % Could use TargetLabelsAccr - but need to save info in XLS first!!!!

for iState=1:length(allStates)
    thisState = allStates{iState};
    strTitName = ['PooledrespCh',timeStr,'_',thisState,'_',regionName];
    fileAnatLabels = [dirCircroPlotsXls, filesep, thisState, filesep, strTitName,'_',anatRegionsStr, posFixFile,'.xlsx']; %chNameStr
    fileRegions = [dirCircroPlotsXls, filesep, thisState,filesep, strTitName,'_',lobeRegionsStr, posFixFile,'.xlsx'];
    fileGralRegions = [dirCircroPlotsXls, filesep, thisState,filesep, strTitName,'_',gralRegionsStr, posFixFile,'.xlsx'];
    fileLatency = [dirCircroPlotsXls, filesep, thisState,filesep, strTitName,'_',latencyStr, posFixFile,'.xlsx'];
    fileColors1 = [dirCircroPlotsXls, filesep, thisState,filesep, strTitName,'_', colorStr1, posFixFile,'.xlsx'];
    fileColors2 = [dirCircroPlotsXls, filesep, thisState,filesep, strTitName,'_', colorStr2, posFixFile,'.xlsx'];
    
    fileEdges = [dirCircroPlotsXls, filesep, thisState,filesep, strTitName,'_mEdges_',edgesStr, posFixFile,'.xlsx'];
    
    if exist(fileEdges,'file')
        strTitNameToSave = [strTitName,'_',edgesStr, '_',posFixFile]; %['respCh',timeStr,'_',regionName,'_',thisState];

        % Level 1 - Regions
         Circro('circro.setNodeLabels',fileGralRegions,1);
         Circro('circro.setNodeColors',fileColors1,'hsv',1,minmaxVals.GralRegions, 1); %hsv
      %  Circro('circro.toggleLabels',1);
        % Level 2 ch names / distances
        Circro('circro.setNodeLabels',fileRegions,2); % fileAnatLabels
        Circro('circro.setDimensions',0.9,0.95,1.5708,2);
        % Add Edges
        h = Circro('circro.setEdgeMatrix',fileEdges,0.5,'parula',1,minmaxVals.nStimChannels,2); %before 'jet'
        % Set node colors AFTER edges - otherwise it changes the colormap or at least the size of it.
        Circro('circro.setNodeColors',fileColors2,'hsv',1,minmaxVals.LobeRegions, 2);

        %         Circro('circro.setNodeLabels',fileLabels,3);
%         Circro('circro.setDimensions',0.8,0.8,1.5708,3);
%         Circro('circro.setNodeColors',fileLatency,'cool',1,3);
%        Circro('circro.toggleLabels',3);
        Circro('circro.toggleLabels',2);
        Circro('circro.toggleLabels',1);
        
        %Circro('circro.setEdgeThreshold',2.33,2); % Threshold to only show responsive
        %             ax1 = h.Children(1);
        %             caxis(ax1, [minmaxColors1(1) minmaxColors1(2)]);
        %             ax2 = h.Children(5);
        %             caxis(ax2, [minmaxColors2(1) minmaxColors2(2)]);
        %             ax3 = h.Children(2);
        %             caxis(ax3, [minmaxColorsEdges(1) minmaxColorsEdges(2)]);
        % Add name of regions to colorbar 
        objColorBar = findobj(gcf,'Type','ColorBar');
        nColorBar = numel(objColorBar);
      %  objColorBar(1).Limits= [minmaxVals.nStimChannels];% objColorBar(nColorBar).Limits(1):objColorBar(nColorBar).Limits(2);
        objColorBar(nColorBar).Ticks=1:length(colorBarNames1);%objColorBar(nColorBar).Limits(1):objColorBar(nColorBar).Limits(2);
        objColorBar(nColorBar).TickLabels = colorBarNames1;
        objColorBar(nColorBar-1).Ticks= [1:max(length(colorBarNames2)-1,objColorBar(nColorBar-1).Limits(2))];% objColorBar(nColorBar).Limits(1):objColorBar(nColorBar).Limits(2);
        objColorBar(nColorBar-1).TickLabels = colorBarNames2;

        suptitle([regionName,' ',thisState])
        saveas(gcf, [dirCircroPlotsImages, filesep, 'circro_',strTitNameToSave],'png')
        saveas(gcf, [dirCircroPlotsImages, filesep, 'circro_',strTitNameToSave],'svg')
        close(gcf)
        
    end
end
titNameComplete = ['CircroPlotsRespCh',timeStr,'_',regionName];
pptFileName = createReportBasedOnPlots(dirCircroPlotsImages, titNameComplete);
disp(['Circro plots saved in PPT file: ', pptFileName]);

