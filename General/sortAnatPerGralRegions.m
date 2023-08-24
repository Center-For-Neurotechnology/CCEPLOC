function [sortedAnatRegions, indInAnatRegions, nChPerRegion] = sortAnatPerGralRegions(anatRegionsPerStim, targetRegionOrder)
% this function orders anatomical regions per general region 
% e.g. rACC next to dAAC / all PFC together

sortedAnatRegions=cell(0,0);
indInAnatRegions=[];
nChPerRegion=zeros(1,numel(targetRegionOrder));

for iRegion=1:numel(targetRegionOrder)
    indRegionPerCh = find(strcmpi(anatRegionsPerStim, targetRegionOrder{iRegion}));
    sortedAnatRegions = [sortedAnatRegions,anatRegionsPerStim(indRegionPerCh)];
    indInAnatRegions = [indInAnatRegions, indRegionPerCh];
    nChPerRegion(iRegion) = length(indRegionPerCh);
end
