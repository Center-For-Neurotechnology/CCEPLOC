function [indChWithinRegion, nValsWithinRegion, chNamesWithinRegion] = findChannelsWithinRegion(stChannelPerRegion, regionNames, nVals, chNames) 
if ~exist('nVals','var'),nVals=[];end
if ~exist('chNames','var'),chNames=cell(0,0);end

if ~iscell(regionNames), regionNames = {regionNames};end

indChWithinRegion=cell(1,length(regionNames));
nValsWithinRegion=cell(1,length(regionNames));
chNamesWithinRegion=cell(1,length(regionNames));
for iRegion=1:length(regionNames)
    cChInRegion = [stChannelPerRegion.(regionNames{iRegion})];
    nChInRegion = length(cChInRegion);
    for iCh=1:nChInRegion
        if isempty(cChInRegion{iCh}), cChInRegion{iCh} = 0;end
        if iscell(cChInRegion{iCh}), chInRegion = cell2mat(cChInRegion{iCh});
        else, chInRegion = cChInRegion{iCh}; end
        if(chInRegion), indChWithinRegion{iRegion} = [indChWithinRegion{iRegion}, iCh];end
      %  nValsWithinRegion{iRegion}(iCh) = nVals(iCh);
    end
    if ~isempty(nVals) % return also numerical values (usually nResp) per region
        nValsWithinRegion{iRegion} = nan(1,nChInRegion);
        %indChResp = find(~cellfun(@isempty,indChWithinRegion(iRegion,:)));
        nValsWithinRegion{iRegion}(indChWithinRegion{iRegion}) = nVals(indChWithinRegion{iRegion});
    end
    if ~isempty(chNames) % return also Channel names per region
        chNamesWithinRegion{iRegion} = cell(1,nChInRegion);
        %indChResp = find(~cellfun(@isempty,indChWithinRegion(iRegion,:)));
        chNamesWithinRegion{iRegion}(indChWithinRegion{iRegion}) = chNames(indChWithinRegion{iRegion});
    end
    
end