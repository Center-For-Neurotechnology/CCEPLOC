function [anatRegionsPerCh, RASCoordPerCh, anatRegionsStimCh, RASCoordPerChStimCh, chNamesSelected, stimSiteNames,  cfgInfoPlot] = getRegionRASPerChannel(stData, cfgInfoPlot, chNamesSelected)
% return parcellation information and RAS coordinates as obtained from getBrainRegionFromMMTV
% chNamesSelected allows to get anat/RAS info for a subset of channels

if ~exist('cfgInfoPlot','var'), cfgInfoPlot=[]; end
if ~exist('chNamesSelected','var'), chNamesSelected=stData.chNamesSelected; end
posColors = colormap(hsv(32))*.8; % ORIGINAL colorcube(nRegions);

stimSiteNames = stData.stimSiteNames;
chNamesSelectedOrig= stData.chNamesSelected;

indChSelected = strmatchAll(chNamesSelectedOrig, chNamesSelected);

anatRegionsPerCh = cell(size(chNamesSelected));
RASCoordPerCh = zeros(size(chNamesSelected,2),3);
anatRegionsStimCh = cell(size(stimSiteNames,2));
RASCoordPerChStimCh = zeros(size(stimSiteNames,2),3);
parcelationLabels = cell(size(chNamesSelected));
probMaxLabel = zeros(size(stimSiteNames,2),1);
probWM = zeros(size(stimSiteNames,2),1);

if isfield(stData, 'anatRegionsPerCh') % if anatRegionsPerCh exist is because we have parcellation information
    anatRegionsPerCh = stData.anatRegionsPerCh(indChSelected); % This variable corresponds to only a few Target regions
    RASCoordPerCh = stData.RASCoordPerCh(indChSelected,:);
    anatRegionsStimCh = stData.anatRegionsStimCh;
    RASCoordPerChStimCh = stData.RASCoordPerChStimCh;
    parcelationLabels = stData.stSelChannelInfo.parcelationLabelPerCh(indChSelected);  % This variable corresponds to all possible parcelation labels
    probMaxLabel = stData.stSelChannelInfo.ProbabilityMapping(indChSelected,2);  % 2nd column is probability of being in the assign parcelation label
    probWM = stData.stSelChannelInfo.ProbabilityMapping(indChSelected,3);  % 3rd column is probability of being in white matter - we might want to use as threshold
end

nChannels = numel(anatRegionsPerCh);
targetLabels = stData.TargetLabelsAccr;
nRegions = length(targetLabels);

indRegions=[];
for iCh=1:nChannels
    indTarget = find(strcmp(targetLabels, anatRegionsPerCh{iCh}),1);
    colorPerCh{iCh} = posColors(indTarget,:);
    indRegions = unique([indRegions,indTarget]);
end

for iCh=1:length(anatRegionsStimCh)
    indTargetStim = find(strcmp(targetLabels, anatRegionsStimCh{iCh}),1);
    colorStimCh{iCh} = posColors(indTargetStim,:);
    indRegions = unique([indRegions,indTarget]);
end

% Add info to cfgInfoPlot
cfgInfoPlot.targetLabels = targetLabels;
cfgInfoPlot.colorPerRegion = posColors;
cfgInfoPlot.colorPerCh = colorPerCh;
cfgInfoPlot.colorStimCh =colorStimCh;
cfgInfoPlot.regionLabels = targetLabels(indRegions);
cfgInfoPlot.indRegionsLabels = indRegions;
cfgInfoPlot.parcelationLabels = parcelationLabels;
cfgInfoPlot.probMaxLabel = probMaxLabel;
cfgInfoPlot.probWM = probWM;