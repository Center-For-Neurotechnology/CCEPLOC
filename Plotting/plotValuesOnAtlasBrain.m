function plotValuesOnAtlasBrain(plotVar, anatLocationsToGroup, titName, CategoriesInBrainStr, FaceLabels,VertexLabel, COLVar, valSteps, faceAlphaVal)
% To plot (Left / Right / Subcortical) - call separately

% faceAlphaVal makes it more transparent - useful to show sub-cortical
% regions  with cortical in background

%1.  Compute mean/ SEM grouping per anatomical region or assign directly the value of the input
if length(unique(anatLocationsToGroup))< length(anatLocationsToGroup) % repeated anat locations -> need to compute stats
    [medianVal, meanVal, SE,nPerGroup, gname]=   grpstats(plotVar,[anatLocationsToGroup(1:length(plotVar)) ],{'nanmedian','nanmean','sem','numel','gname'});
    ME=meanVal; %medianVal; %
else % already value to plot
    ME=plotVar; 
    gname=anatLocationsToGroup;
end

%2. Plot (Left / Right / Subcortical)
indFoundRegions=[];
for simwe=1:length(gname)
   % CL=find(CategoryLeft(:,2)==gname(simwe));
    CL=find(strcmpi(CategoriesInBrainStr, gname{simwe}));
    indFoundRegions = unique([indFoundRegions; CL]);
    if isempty(CL)==0
        for LCD=1:length(CL)
            COLORPATCH=[];
            for hn=1:length(valSteps)
                if ME(simwe)>=valSteps(hn) && ME(simwe)<valSteps(min(hn+1,length(valSteps)))
                    COLORPATCH= COLVar(hn,:);
                end
            end
            if isempty(COLORPATCH)==1
                COLORPATCH=[.8 .8 .8];
            end
            
            patch('Faces',FaceLabels{CL(LCD)},'Vertices',...
                VertexLabel{CL(LCD)},'FaceColor',...
                COLORPATCH,'FaceAlpha',faceAlphaVal,'EdgeColor','none')

        end
    end
end



indRegionNotFound = find(~cellfun(@isempty,CategoriesInBrainStr));
indRegionNotFound(ismember(indRegionNotFound, indFoundRegions))=[];
for iRegion=1:length(indRegionNotFound)
    patch('Faces',FaceLabels{indRegionNotFound(iRegion)},'Vertices',...
        VertexLabel{indRegionNotFound(iRegion)},'FaceColor',...
        [.9 .9 .9],'FaceAlpha',faceAlphaVal,...
        'EdgeColor','none')
end
% indRegionNotFoundRight = 1:length(FaceLabelRight);
% indRegionNotFoundRight(indFoundRegionsRight)=[];
% for iRegion=1:length(indRegionNotFoundRight)
%     patch('Faces',FaceLabelRight{iRegion},'Vertices',...
%         VertexLabelRight{iRegion},'FaceColor',...
%         [.8 .8 .8],'FaceAlpha',.7,...
%         'EdgeColor','none')
% end
% indRegionNotFoundSubCort = find(~cellfun(@isempty,CategorySubcortStr));
% indRegionNotFoundSubCort(ismember(indRegionNotFoundSubCort, indFoundRegionsSubcort))=[];
% 
% for iRegion=1:length(indRegionNotFoundSubCort)
%     patch('Faces',FaceLabelSubcort{iRegion},'Vertices',...
%         VertexLabelSubcort{iRegion},'FaceColor',...
%         [.8 .8 .8],'FaceAlpha',.7,...
%         'EdgeColor','none')
% end

% change view
view(90,0)
camlight headlight
lighting gouraud
axis off
daspect([1 1 1])

title(titName,'FontSize',12)

