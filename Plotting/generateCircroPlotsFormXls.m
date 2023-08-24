function generateCircroPlotsFormXls(dirCircroPlots, pName, stimChannels, timeStr, gralCircroInfoFile)

dirCircroPlotsXls = [dirCircroPlots, filesep, 'xlsFiles'];
dirCircroPlotsImages = [dirCircroPlots, filesep, 'images', filesep, pName];
if ~isdir(dirCircroPlotsImages), mkdir(dirCircroPlotsImages); end

%stimChannels = {'LFO10-LFO09'    'LA_5-LA_4'           'RPI6-RPI5' 'RMI08-RMI07'}; %'RFC3-RFC4' 
%timeStr = '10-600';
%varNames = {'chNamesPerStim', 'anatRegions', 'isChResp', 'ampRespCh','ampOnlyRespCh', 'distRecToStimCh','colorPerCh','latencyOnlyRespCh'};

chNameStr = 'chNamesPerStim';
anatRegionsStr = 'anatRegions';
lobeRegionsStr = 'lobeRegions'; %'anatRegions'; %
latencyStr = 'latencyOnlyRespCh';
colorStr1 = 'indRegionPerCh'; %'indGralRegionPerCh'; % 'indLobeRegionPerCh' %index region per channel (to use as color)

colorStr2 = 'distRecToStimCh'; % use dist to stim as color coding

edgesStr ='ampOnlyRespCh_Max10_';% 'ampOnlyRespCh'; %'isChResp'; % 'ampRespCh'; %'ampRespCh'; %

if exist(gralCircroInfoFile,'file')
    load(gralCircroInfoFile,'TargetLabels','TargetLabelsAccr','allStates','lobeRegionNames','gralRegionNames','minmaxVals')
else
    disp([gralCircroInfoFile,' does not exist!'])
    lobeRegionNames = {'dmvPFC','OF','ACC','central','insula', 'MTL','latTemp','PCC','parietal','occipital','subcortical','thalCaud','WM'};
    gralRegionNames = {'prefrontal','ACC','central','temporal','posterior','subcortical','thalCaud','WM'};
    allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
    minmaxVals.Amplitude = [-200 200];
    minmaxVals.LatencyFirstPeak = [0 300];
   minmaxVals.EucDistance =[0 120]; 
end

colorBarNames1 = TargetLabelsAccr;


for iState=1:length(allStates)
    thisState = allStates{iState};
    for iStr=1:length(stimChannels)
        strTitName = ['respCh',timeStr,'_',pName,'_',thisState,'_',stimChannels{iStr}];
        fileLabels = [dirCircroPlotsXls, filesep, pName, filesep, strTitName,'_',anatRegionsStr, '_perStimCh','.xlsx']; %chNameStr
        fileRegions = [dirCircroPlotsXls, filesep, pName, filesep, strTitName,'_',lobeRegionsStr, '_perStimCh','.xlsx'];
        fileLatency = [dirCircroPlotsXls, filesep, pName, filesep, strTitName,'_',latencyStr, '_perStimCh','.xlsx'];
        fileColors1 = [dirCircroPlotsXls, filesep, pName, filesep, strTitName,'_', colorStr1, '_perStimCh','.xlsx'];
        fileColors2 = [dirCircroPlotsXls, filesep, pName, filesep, strTitName,'_', colorStr2, '_perStimCh','.xlsx'];
        
        fileEdges = [dirCircroPlotsXls, filesep, pName, filesep, 'respCh',timeStr,'_',pName,'_',thisState,'_mEdges_',stimChannels{iStr},'_',edgesStr, '_perStimCh','.xlsx'];

        if exist(fileLabels,'file')
        strTitNameToSave = ['respCh',timeStr,'_',pName,'_',stimChannels{iStr},'_',thisState];
            % Level 1 - Regions
            Circro('circro.setNodeLabels',fileLabels,1);
            Circro('circro.setNodeColors',fileColors1,'hsv',1,minmaxVals.AnatomicalRegions,1);
            % Level 2 ch names / distances
            Circro('circro.setNodeLabels',fileLabels,2);
            Circro('circro.setDimensions',0.9,0.95,1.5708,2);
            Circro('circro.setNodeColors',fileColors2,'bone',1,minmaxVals.EucDistance,2);
            Circro('circro.setNodeLabels',fileLabels,3);
            Circro('circro.setDimensions',0.8,0.8,1.5708,3);
            Circro('circro.toggleLabels',3);
            Circro('circro.toggleLabels',2);
          %  Circro('circro.toggleLabels',1);
            
            % Add Edges
            h = Circro('circro.setEdgeMatrix',fileEdges,2,'copper',1,minmaxVals.Amplitude,3);
        % Set node colors AFTER edges - otherwise it changes the colormap or at least the size of it.
            Circro('circro.setNodeColors',fileLatency,'cool',1,minmaxVals.LatencyFirstPeak,3);
        
        %Circro('circro.setEdgeThreshold',2.33,2); % Threshold to only show responsive
%             ax1 = h.Children(1);
%             caxis(ax1, [minmaxColors1(1) minmaxColors1(2)]);
%             ax2 = h.Children(5);
%             caxis(ax2, [minmaxColors2(1) minmaxColors2(2)]);
%             ax3 = h.Children(2);
%             caxis(ax3, [minmaxColorsEdges(1) minmaxColorsEdges(2)]);
            suptitle([pName,' ',stimChannels{iStr},' ',thisState])

            objColorBar = findobj(gcf,'Type','ColorBar');
            nColorBar = numel(objColorBar);
            objColorBar(nColorBar).Ticks= [1:max(length(colorBarNames1)-1,objColorBar(nColorBar).Limits(2))];% objColorBar(nColorBar).Limits(1):objColorBar(nColorBar).Limits(2);
            objColorBar(nColorBar).TickLabels = colorBarNames1;
            saveas(gcf, [dirCircroPlotsImages, filesep, 'circro_',strTitNameToSave],'png')
            saveas(gcf, [dirCircroPlotsImages, filesep, 'circro_',strTitNameToSave],'svg')
            close(gcf)
        end
    end
end
titNameComplete = ['CircroPlotsRespCh',timeStr,'_',pName];
pptFileName = createReportBasedOnPlots(dirCircroPlotsImages, titNameComplete);
disp(['Circro plots saved in PPT file: ', pptFileName]);

