function plotAllCCEPPerElectrode(EEGStimTrialMATfile, dirImages, whatToUse, cfgInfoPlot)
% Plot one line  per electrode
% Assume first letters (not numbers) define the electrode name

%% CONFIG
if ~exist('cfgInfoPlot','var'), cfgInfoPlot=[]; end
if ~isfield(cfgInfoPlot,'tPlotSec') || isempty(cfgInfoPlot.tPlotSec)
    cfgInfoPlot.tPlotSec = [-250 500]/1000; % time to plot
end
if ~isfield(cfgInfoPlot,'minNumberTrials') || isempty(cfgInfoPlot.minNumberTrials)
    cfgInfoPlot.minNumberTrials = 5; % at least minNumberTrials trials to display/compute responsive chanels
end
if isempty(EEGStimTrialMATfile)
    disp(['File ', EEGStimTrialMATfile,' is empty'])
    return;
end
maxNContactsPerElect=16; % added 16 because that is a typical number of contacts 

%% Load Data
stData = load(EEGStimTrialMATfile);
titName = stData.titName;
stimSiteNames = stData.stimSiteNames;
pName = stData.pName;
chNames = stData.chNamesSelected;
nChannels = numel(chNames);
timeVals = stData.timePerTrialSec;
Fs = stData.hdr.Fs;
%indTrialsToExcludePerCh = stData.indTrialsToExcludePerCh;

if isfield(cfgInfoPlot,'titName')
    titName = cfgInfoPlot.titName;
end

%% Select WHAT to plot
[EEGtoPlot, indSelCh, cfgInfoPlot] = selectWhatSignalToUse(stData, whatToUse, [], cfgInfoPlot);

%% Select time to plot and compute median
indStim = find(timeVals>=0,1); 
cfgInfoPlot.tPlotSamples = round(cfgInfoPlot.tPlotSec * Fs + indStim);
timeValsToPlot = timeVals(cfgInfoPlot.tPlotSamples(1):cfgInfoPlot.tPlotSamples(2));

%% Select WHICH Trials to plot
if isfield(cfgInfoPlot,'trialsToPlot') && ~isempty(cfgInfoPlot.trialsToPlot)
    for iCh=1:nChannels
        nTrials =  size(stData.EEGStimTrials{iCh},2); 
        if length(cfgInfoPlot.trialsToPlot)==1 % If only 1 number is specified -> use LAST trials
            cfgInfoPlot.trialsToPlot= nTrials - cfgInfoPlot.trialsToPlot + 1 : nTrials;
        end
        
        indStimThisCh = 1:nTrials;
        %  indStimThisCh(indTrialsToExcludePerCh{iCh})=[];
        [origTrialNumbers, indTrialsToPlot] = intersect(indStimThisCh, cfgInfoPlot.trialsToPlot);
        indTrialsToPlot = intersect(indTrialsToPlot, 1:size(EEGtoPlot{iCh},2));
        EEGtoPlot{iCh}=EEGtoPlot{iCh}(:,indTrialsToPlot);
    end
    
end

%% if responsive info is present (and if selected in option in cfgInfoPlot -> add responsive channel information as a red dot
% these channels will have a red dot
respChNames=cell(0,0);
if isfield(cfgInfoPlot,'lstResponsiveChannel') && ~isempty(cfgInfoPlot.lstResponsiveChannel) 
    respChNames = cfgInfoPlot.lstResponsiveChannel; 
end

%% if SOZ info is present (and if selected in option in cfgInfoPlot -> add SOZ channel information as a blue dot
% these channels will have a blue dot
SOZChNames=cell(0,0);
if isfield(cfgInfoPlot,'lstSOZChNames') && ~isempty(cfgInfoPlot.lstSOZChNames) 
    SOZChNames = cfgInfoPlot.lstSOZChNames; 
end

%% if anatomical info is requested use a different color for each region
if isfield(cfgInfoPlot,'useColorPerRegion') && (cfgInfoPlot.useColorPerRegion==1) && isfield(stData,'TargetLabelsAccr')
    [anatRegionsPerCh, RASCoordPerCh, anatRegionsStimCh, RASCoordPerChStimCh, ~, ~, cfgInfoPlot] = getRegionRASPerChannel(stData, cfgInfoPlot);
    colorPerChannel = cfgInfoPlot.colorPerCh; 
    colorStimChannel = cfgInfoPlot.colorStimCh{1}; 
else
    colorPerChannel=cell(1,nChannels);
    for iCh=1:nChannels % black for all
        colorPerChannel{iCh} = zeros(1,3);
    end
    colorStimChannel=zeros(1,3);
    cfgInfoPlot.useColorPerRegion = 0;
end
%% Compute mean, median 
for iCh=1:nChannels
    if size(EEGtoPlot{iCh}, 2) >= cfgInfoPlot.minNumberTrials
        [meanStim, q25DetStim, q75DetStim, stdDetStim, stdErrorDetStim, medianVal,coeffVar]= meanQuantiles(EEGtoPlot{iCh}, 2, 1);
        % avEEGToPlot{iCh} = meanStim(cfgInfoPlot.tPlotSamples(1):cfgInfoPlot.tPlotSamples(2)); %mean instead of median to get a smooth plot)
        avEEGToPlot{iCh} = medianVal(cfgInfoPlot.tPlotSamples(1):cfgInfoPlot.tPlotSamples(2)); % use median to remove outliers
    else
         avEEGToPlot{iCh} = [];
    end
end

%% Get electrodes information
[uniqueElect, indElecPerCh, nContactsPerElectrode] = getElectrodeNames(chNames);
maxContacts = max([nContactsPerElectrode,maxNContactsPerElect]) +1; % add extra column to show labels and scales 
nElectrodes = numel(uniqueElect);

%% Is Stim in SOZ?
stimChIs='';
if ~isempty(SOZChNames) && (any(contains(SOZChNames, stimSiteNames)) || any(contains(stimSiteNames, SOZChNames))) % this STIM ch is in the SOZ
    stimChIs = 'SOZ ';
end

%% Plot massive figure with all responses
titNameForFile = [pName,stimChIs,' Stim ch ', stimSiteNames{:}, ' ', whatToUse,' ', titName];
titNameForPlot = [pName,' ',stimChIs,'Stim ch ','\bf\color[rgb]{',num2str(colorStimChannel),'} ', stimSiteNames{:}, '\rm\color{black} ', whatToUse,' ', titName, ' (',num2str(cfgInfoPlot.tPlotSec(1)),' ',num2str(cfgInfoPlot.tPlotSec(2)),'s)'];
titNameForPlot = regexprep(titNameForPlot,'_',' ');
scrsz = get(groot,'ScreenSize');
figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
iRow=0;
for iElec=1:nElectrodes
    addTitle=1;
    if ~isempty(indElecPerCh{iElec}), iRow=iRow+1;end  % to remove electrodes without data
    for iCh=1:length(indElecPerCh{iElec})
        chName = chNames{indElecPerCh{iElec}(iCh)};
        contacts = split(chName,'-');
        if  ~isempty(avEEGToPlot{indElecPerCh{iElec}(iCh)})%all(contains(contacts,uniqueElect{iElec})) && only if all are within SHAFT! (Might want to change this if other than bipolar is used)!!
            chPosFromName = min(str2double(split(regexprep(chName,uniqueElect{iElec},''),'-'))); % assumes 2 values after electrode name is contact position within electrode
            subplot(nElectrodes, maxContacts,(iRow-1)*maxContacts+chPosFromName);
            hold on;
            line([0, 0], [cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal], 'Color',colorPerChannel{indElecPerCh{iElec}(iCh)},'LineWidth',3); %'Color',[1 0.5 0]
            plot(timeValsToPlot, avEEGToPlot{indElecPerCh{iElec}(iCh)}, 'k' );
            ylim([cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal]);
            if ~isempty(respChNames) && any(contains(respChNames, chName)) % this is one of the responsive channels
                scatter(-0.1, 0.75*cfgInfoPlot.minAmpVal, [],'filled','r')
            end
            if ~isempty(SOZChNames) && (any(contains(SOZChNames, chName)) || any(contains(chName, SOZChNames))) % this is one of the SOZ channels
                scatter(-0.2, 0.75*cfgInfoPlot.maxAmpVal, [],'filled','b')
            end
            ax=gca;
            axis(ax,'off');
            if addTitle==1, title(uniqueElect{iElec});addTitle=0; end
            if iElec==nElectrodes % show contact number on last row;
                xlabel([num2str(iCh),'-',num2str(iCh+1)]);
                ax.XLabel.Visible= 'on';
            end
        end
    end
end
% Add labels information in last column
if cfgInfoPlot.useColorPerRegion
    nRegions = length(cfgInfoPlot.indRegionsLabels);
    subplot(nElectrodes, maxContacts,[(1:nElectrodes-1)*maxContacts]);
    hold on;
    for iRegion=1:nRegions
        plot(timeValsToPlot, iRegion*ones(1,length(timeValsToPlot)),'Color',cfgInfoPlot.colorPerRegion(cfgInfoPlot.indRegionsLabels(iRegion),:),'LineWidth',3)
    end
    ax=gca;
    ax.Visible = 'off';
    legend(cfgInfoPlot.regionLabels,'FontSize',16)
end
% Add supper title
suptitle(titNameForPlot);

% Save Figure
if ~exist(dirImages,'dir'), mkdir(dirImages); end
titNameForFile = regexprep(titNameForFile,'\W','_');
savefig(gcf,[dirImages, filesep,titNameForFile,'fig'],'compact');
saveas(gcf,[dirImages,filesep, titNameForFile],'png');
