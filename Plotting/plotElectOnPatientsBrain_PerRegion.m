function plotElectOnPatientsBrain_PerRegion(pNames, reconDataDir, dirGral, posFixDir, dirImages, titNameFig, TargetLabelAccr, allStates)

%titNameFig = 'Ch location all Patients';
% Generic files
pNameGeneric = 'pIDXXXXX';
stateGeneric = 'BRAINSTATE';
fileRespGeneric = [dirGral,filesep,pNameGeneric,filesep,'ResultsAnalysisAllCh',posFixDir,filesep,'ResponsiveChannelsAllStatesPERTRIALMEDIAN',filesep,'lstResponsiveChannel',pNameGeneric,'_',stateGeneric,'.mat'];
fileReconGeneric =[reconDataDir, filesep,pNameGeneric,filesep,pNameGeneric,'MappedRegionsClosest.mat'];

% Config
nPatients= length(pNames);
COLORPATCH=[.8 .8 .8];
%allStates = {'WakeEMU','Sleep','WakeOR','Anesthesia'};
nStates = numel(allStates);
thStimResp=5;% at least 5 trials in ANY state


% colorcoded by region
nLabels = length(TargetLabelAccr);
COL2=colormap(hsv(nLabels))*.8;

% Plot per patient - ALL STATES
pNumber = strcat('p',cellfun(@num2str, num2cell(1:nPatients), 'UniformOutput', false));

scrsz = get(groot,'ScreenSize');
figure('Name', titNameFig, 'Position',[1 1 scrsz(3) scrsz(4)]);
for iP=1:nPatients
    pName=pNames{iP};
    stBrainLoc =  load(regexprep(fileReconGeneric,pNameGeneric,pName));
    h(iP) = subplot(5,4,iP);
    indStimChRespAnyState=[];
    stimChNamesAllStates=cell(0,0);
    nRespChAllStates=[];
    for iState=1:nStates % plot one state on top of the other (include ALL channels in ALL states per patient)
        thisState = allStates{iState};
        fileNameResp = regexprep(regexprep(fileRespGeneric,pNameGeneric,pName),stateGeneric,thisState);
        if exist(fileNameResp,'file')
            stRespCh = load(fileNameResp);
            respAllStimPerState = cell2mat(stRespCh.channInfoRespCh');
            if ~isempty(respAllStimPerState) % otherwise NO response at all / probably no experiment in this state
                % stim channels
                stimChAnat = [respAllStimPerState.anatRegionsStimCh];
                stimChRAS = cell2mat({respAllStimPerState.RASCoordPerChStimCh}');
                [~,stimIndAnatRegion] = strmatchAll(stimChAnat, TargetLabelAccr);
                % identify excluded stim channels
                stimSiteNames = [respAllStimPerState.stimSiteNames];
                stimChNames = strcat(stimSiteNames(2,:),'-',stimSiteNames(1,:));
                origCh = [respAllStimPerState.chNamesSelectedOrig];
                indStimExcluded = find([respAllStimPerState.isChExcluded]);
                origCh(indStimExcluded)=[];
                indIncStim = strmatchAll(stimChNames, unique(origCh));
                % only include if in more than 1 state
                stimChNamesAllStates = [stimChNames, stimChNamesAllStates]; % this order ensures that the ones from this file are first and therefore indIncStim and indStimIn2States correspond to the same channels
                nRespChAllStates = [stRespCh.nRespCh', nRespChAllStates];
                
                [unStim, ~, k] =unique(stimChNamesAllStates,'stable');
                indStimIn2States = find(histc(k,1:numel(unStim))>=floor(nStates/2)); % keep histc - hitscount changes the edges and removes the last
                
                
                % recording channels - it gets repeated by stim site - it will overlap in the plot
                recChAnat = [respAllStimPerState.anatRegionsPerCh];
                recChRAS = cell2mat({respAllStimPerState.RASCoordPerCh}');
                [~,recIndAnatRegion] = strmatchAll(recChAnat, TargetLabelAccr);
                
                % responsive  channels
                indChResponsive = find([respAllStimPerState.isChResponsive]);
                nameRespCh = unique([respAllStimPerState.lstResponsiveChannel]);
                chRecNames = unique([respAllStimPerState.chNamesSelected]);
                
                % stim channels with response
                indStimChRespAnyState = unique(k(find([nRespChAllStates]>=thStimResp)));
                
                
                % Plots per patient
                patch('Faces',stBrainLoc.faceslh,'Vertices',stBrainLoc.verticeslh,'FaceColor',COLORPATCH,'FaceAlpha',.1,'EdgeColor','none')
                hold on
                patch('Faces',stBrainLoc.facesrh,'Vertices',stBrainLoc.verticesrh,'FaceColor',COLORPATCH,'FaceAlpha',.1,'EdgeColor','none')
                set(gcf,'color','w')
                
                % recording channels
                scatter3(recChRAS(:,1),recChRAS(:,2), recChRAS(:,3),... % recording channels
                    10,COL2(recIndAnatRegion,:),'filled')
                % if channel has a response indicate in black around
                scatter3(recChRAS(indChResponsive,1),recChRAS(indChResponsive,2), recChRAS(indChResponsive,3),...
                    5,zeros(length(indChResponsive),3),'filled')

                % stim channels
                incStimToPlot = intersect(indIncStim, indStimIn2States);
                scatter3( stimChRAS(incStimToPlot,1),stimChRAS(incStimToPlot,2), stimChRAS(incStimToPlot,3),... % stim channels
                    96,zeros(length(incStimToPlot),3),'filled')
                scatter3( stimChRAS(incStimToPlot,1),stimChRAS(incStimToPlot,2), stimChRAS(incStimToPlot,3),...
                    56,COL2(stimIndAnatRegion(incStimToPlot),:),'filled')
                
            end
        else
            disp([thisState,' ',pName,'does not exist'])
        end
        % if no responses (less than 5) in ANY state - indicate in gray
        indStimChNoResp = setdiff(incStimToPlot, indStimChRespAnyState);
        scatter3( stimChRAS(indStimChNoResp,1),stimChRAS(indStimChNoResp,2), stimChRAS(indStimChNoResp,3),...
            56,0.8*ones(length(indStimChNoResp),3),'filled')
        disp([pNumber{iP},' ',pName, ' ' , thisState, ...
            ' #StimChWithRespAnyState=  ', num2str(length(indStimChRespAnyState)), ' #StimChIncluded=  ', num2str(length(incStimToPlot)),...
            ' #RespCh= ',num2str(length(nameRespCh)),' outOf RecCh= ', num2str(length(chRecNames))])
    end
    % change view
    daspect([1 1 1])
    view(90,0)
    axis off
    axis tight
    title([pNumber{iP}],'fontsize',14)
end

% Save in 1 figure
print(gcf,'-dpng','-r300',[dirImages, filesep,'ElectrodesAnatLoc', titNameFig,'_sagital'])
%saveas(gcf,[dirImages,filesep, 'ElectrodesAnatLoc',titNameFig,'_sagital','.fig'])

% change view save again
for iP=1:nPatients
    view(h(iP), 180,0)
end
print(gcf,'-dpng','-r300',[dirImages, filesep,'ElectrodesAnatLoc', titNameFig,'_coronal'])
%saveas(gcf,[dirImages,filesep, 'ElectrodesAnatLoc',titNameFig,'_coronal','.fig'])

% change view save again
for iP=1:nPatients
    view(h(iP), 180,90)
    title(h(iP),[pNames{iP}],'fontsize',14)
end
print(gcf,'-dpng','-r300',[dirImages, filesep,'ElectrodesAnatLoc', titNameFig,'_axial'])
%saveas(gcf,[dirImages,filesep, 'ElectrodesAnatLoc',titNameFig,'_axial','.fig'])



