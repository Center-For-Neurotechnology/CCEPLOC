function plotAllCCEPAllStim(EEGStimTrialMATfiles, dirImages, whatToUse, cfgInfoPlot)
% Plot one line per electrode - 
% Uses different colors for different stim
% Assume first letters (not numbers) define the electrode name

%% CONFIG
if ~exist('cfgInfoPlot','var'), cfgInfoPlot=[]; end
if ~isfield(cfgInfoPlot,'tPlotSec') || isempty(cfgInfoPlot.tPlotSec)
    cfgInfoPlot.tPlotSec = [-250 500]/1000; % time to plot
end
if ~isfield(cfgInfoPlot,'minNumberTrials') || isempty(cfgInfoPlot.minNumberTrials)
    cfgInfoPlot.minNumberTrials = 5; % at least minNumberTrials trials to display/compute responsive chanels
end
if isempty(EEGStimTrialMATfiles)
    disp(['File ', EEGStimTrialMATfiles,' is empty'])
    return;
end
maxNContactsPerElect=16; % added 16 because that is a typical number of contacts 

if ~iscell(EEGStimTrialMATfiles), EEGStimTrialMATfiles = {EEGStimTrialMATfiles}; end

titName = '';
if isfield(cfgInfoPlot,'titName')
    titName = cfgInfoPlot.titName;
end

%% Load Data from all files
stimSiteNames=[];
allChNames=[];
avEEGToPlot=struct();
colorStimChannels=[];
for iFile =1:numel(EEGStimTrialMATfiles)
    stData = load(EEGStimTrialMATfiles{iFile});
%    titName = stData.titName;
    stimSiteNames = unique([stimSiteNames; {[stData.stimSiteNames{2},'-',stData.stimSiteNames{1}]}]);
    pName = stData.pName; % assume pName is the same
    allChNames = unique([allChNames, stData.chNamesSelected]);
    strChNames = regexprep(stData.chNamesSelected,'-','');
    nChannels = numel(strChNames);
    timeVals = stData.timePerTrialSec;
    Fs = stData.hdr.Fs;
    %indTrialsToExcludePerCh = stData.indTrialsToExcludePerCh;
    %% Select time to plot and compute median
    indStim = find(timeVals>=0,1);
    cfgInfoPlot.tPlotSamples = round(cfgInfoPlot.tPlotSec * Fs + indStim);
    timeValsToPlot = timeVals(cfgInfoPlot.tPlotSamples(1):cfgInfoPlot.tPlotSamples(2));
    
    
    %% Select WHAT to plot
    [EEGtoPlot, indSelCh, cfgInfoPlot] = selectWhatSignalToUse(stData, whatToUse, [], cfgInfoPlot);
    
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
    %% Compute mean, median
    for iCh=1:nChannels
        if size(EEGtoPlot{iCh}, 2) >= cfgInfoPlot.minNumberTrials
            [meanStim, q25DetStim, q75DetStim, stdDetStim, stdErrorDetStim, medianVal,coeffVar]= meanQuantiles(EEGtoPlot{iCh}, 2, 1);
            % avEEGToPlot{iCh} = meanStim(cfgInfoPlot.tPlotSamples(1):cfgInfoPlot.tPlotSamples(2)); %mean instead of median to get a smooth plot)
            avEEGToPlot.(strChNames{iCh})(:,iFile) = medianVal(cfgInfoPlot.tPlotSamples(1):cfgInfoPlot.tPlotSamples(2)); % use median to remove outliers
        else
            avEEGToPlot.(strChNames{iCh})(:,iFile) = NaN(diff(cfgInfoPlot.tPlotSamples),1);
        end
    end
end
strAllChNames = regexprep(allChNames,'-','');

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

%% Get electrodes information
[uniqueElect, indElecPerCh, nContactsPerElectrode] = getElectrodeNames(allChNames);
maxContacts = max([nContactsPerElectrode,maxNContactsPerElect]) +1; % add extra column to show labels and scales 
nElectrodes = numel(uniqueElect);

%% Plot massive figure with all responses
titNameForFile = [pName,' All Stim ch ', whatToUse,' ', titName];
%titNameForPlot = [pName,' All Stim ch ','\bf\color[rgb]{',num2str(colorStimChannel),'} ', stimSiteNames{:}, '\rm\color{black} ', whatToUse,' ', titName, ' (',num2str(cfgInfoPlot.tPlotSec(1)),' ',num2str(cfgInfoPlot.tPlotSec(2)),'s)'];
titNameForPlot = [pName,' All Stim ch ', whatToUse,' ', titName, ' (',num2str(cfgInfoPlot.tPlotSec(1)),' ',num2str(cfgInfoPlot.tPlotSec(2)),'s)'];
titNameForPlot = regexprep(titNameForPlot,'_',' ');
scrsz = get(groot,'ScreenSize');
figure('Name', titName, 'Position',[1 1 scrsz(3) scrsz(4)]);
iRow=0;
for iElec=1:nElectrodes
    addTitle=1;
    if ~isempty(indElecPerCh{iElec}), iRow=iRow+1;end  % to remove electrodes without data
    for iCh=1:length(indElecPerCh{iElec})
        chName = allChNames{indElecPerCh{iElec}(iCh)};
        strChName = strAllChNames{indElecPerCh{iElec}(iCh)};
        contacts = split(chName,'-');
        if  ~isempty(avEEGToPlot.(strChName))%all(contains(contacts,uniqueElect{iElec})) && only if all are within SHAFT! (Might want to change this if other than bipolar is used)!!
            chPosFromName = min(str2double(split(regexprep(chName,uniqueElect{iElec},''),'-'))); % assumes 2 values after electrode name is contact position within electrode
            subplot(nElectrodes, maxContacts,(iRow-1)*maxContacts+chPosFromName);
            hold on;
            line([0, 0], [cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal],'Color',[1 0.5 0],'LineWidth',3); %'Color',colorPerChannel{indElecPerCh{iElec}(iCh)},
            plot(timeValsToPlot, avEEGToPlot.(strChName)); % colors represent stim value
            ylim([cfgInfoPlot.minAmpVal cfgInfoPlot.maxAmpVal]);
            if ~isempty(respChNames) && any(contains(respChNames, chName)) % this is one of the responsive channels
                scatter(-0.1, 0.75*cfgInfoPlot.minAmpVal, [],'filled','r')
            end
            if ~isempty(SOZChNames) && any(contains(SOZChNames, chName)) % this is one of the SOZ channels
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
nRegions = length(nElectrodes);
subplot(nElectrodes, maxContacts,[(1:nElectrodes-1)*maxContacts]);
hold on;
for iRegion=1:nElectrodes
    plot(timeValsToPlot, iRegion*ones(1,length(timeValsToPlot)),'LineWidth',3)
end
ax=gca;
ax.Visible = 'off';
% Add legend with stim sites names
legend(stimSiteNames,'FontSize',16)

% Add supper title
suptitle(titNameForPlot);

% Save Figure
if ~exist(dirImages,'dir'), mkdir(dirImages); end
titNameForFile = regexprep(titNameForFile,'\W','_');
savefig(gcf,[dirImages, filesep,titNameForFile,'fig'],'compact');
saveas(gcf,[dirImages,filesep, titNameForFile],'png');
