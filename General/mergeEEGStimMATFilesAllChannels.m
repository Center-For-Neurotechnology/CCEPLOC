function newMATFileName = mergeEEGStimMATFilesAllChannels(fileNameEEGStimTrial, newMATFileName, whatToMerge, newTitName, trialsToExclude)

if ~exist('whatToMerge','var') || isempty(whatToMerge)
    whatToMerge={'DETSTIM','RANDOMSTIM','DETNOSTIM','ALL'};
end
    
if ~exist('trialsToExclude','var')
    trialsToExclude =[];
end

%load first file to get all the common variables
load(fileNameEEGStimTrial{1});
nChannels = length(chNamesSelected);

if exist('newTitName','var') && ~isempty(newTitName)
    titName = newTitName;
end
hdr.allFiles{1} = hdr;
infoBaseline.allFiles{1} = infoBaseline;
fileNameEEGStimAllTrials = fileNameEEGStimTrial; % save under a different name to store at the end

delayStimAfterDetSec1 = cfgInfoPeaks.delayStimAfterDetSec; % this is the time difference between detections and stim. needs to be taken into account when adding detNoStim
% store information of where each event is coming from
indFileDetStimEv = ones(1,size(EEGDetStimTrials{1},2));
indFileDetNoStimEv = ones(1,size(EEGDetNOStimTrials{1},2));
indFileRandStimEv = ones(1,size(EEGRandomStimTrials{1},2));
indFileAllEv = ones(1,size(EEGStimTrials{1},2));


% Add trials from all other files - ASSUME SAME CHANNELS
for iFile =2:numel(fileNameEEGStimTrial) %First one is already loaded
    %indStimFile = find(~cellfun(@isempty,strfind(fileNameEEGStimTrial, channInfo.stimBipChNames{iStim})));
    stEEGStim = load(fileNameEEGStimTrial{iFile});
    delayStimAfterDetSec2 = stEEGStim.cfgInfoPeaks.delayStimAfterDetSec; % this is the time difference between detections and stim. needs to be taken into account when adding detNoStim
    delayDifferenceSamples = (delayStimAfterDetSec2-delayStimAfterDetSec1)*hdr.Fs;
    %  stimSiteNames = stEEGStim.stimSiteNames;
    chNamesSelectedInFile = stEEGStim.chNamesSelected;
    if ~strcmp(chNamesSelectedInFile, chNamesSelected) %compare to names of first file
        disp('WARNING:: channel names are different!')
    end
    % ASUME that channels are the same - USE ALL
    indSelCh = 1:length(chNamesSelectedInFile);
    
    for iCh=1:length(indSelCh)
        % Select WHAT to Merge ---- RIZ FALTA!!!!!
        for iType=1:length(whatToMerge)
            switch upper(whatToMerge{iType})
                case 'DETSTIM'
                    EEGDetStimTrials{iCh} = [EEGDetStimTrials{iCh}, stEEGStim.EEGDetStimTrials{indSelCh(iCh)}];
                    zNormEEGDetStim{iCh} = [zNormEEGDetStim{iCh}, stEEGStim.zNormEEGDetStim{indSelCh(iCh)}];
                    perTrialNormDetStim{iCh} = [perTrialNormDetStim{iCh}, stEEGStim.perTrialNormDetStim{indSelCh(iCh)}]; 
                    if isfield()
                        perTrialNormDetStim{iCh} = [perTrialNormDetStim{iCh}, stEEGStim.perTrialNormDetStim{indSelCh(iCh)}];
                    end
                    if iCh==2, indFileDetStimEv = [indFileDetStimEv, iFile*ones(1,size(stEEGStim.EEGDetStimTrials{indSelCh(iCh)},2))]; end
                case 'RANDOMSTIM'
                    EEGRandomStimTrials{iCh} = [EEGRandomStimTrials{iCh}, stEEGStim.EEGRandomStimTrials{indSelCh(iCh)}];
                    zNormEEGRandomStim{iCh} = [zNormEEGRandomStim{iCh}, stEEGStim.zNormEEGRandomStim{indSelCh(iCh)}];
                    perTrialNormEEGRandomStim{iCh} = [perTrialNormEEGRandomStim{iCh}, stEEGStim.perTrialNormEEGRandomStim{indSelCh(iCh)}];
                     if iCh==2, indFileRandStimEv = [indFileRandStimEv, iFile*ones(1,size(stEEGStim.EEGRandomStimTrials{indSelCh(iCh)},2))];end
                case 'DETNOSTIM'
                    zerosToPad = zeros(abs(delayDifferenceSamples), size(stEEGStim.EEGDetNOStimTrials{indSelCh(iCh)},2));
                    if delayDifferenceSamples>0 % move to the right
                        EEGDetNOStimTrials{iCh} = [EEGDetNOStimTrials{iCh}, [zerosToPad; stEEGStim.EEGDetNOStimTrials{indSelCh(iCh)}(1:end-delayDifferenceSamples,:)]];
                        zNormEEGDetNOStim{iCh} = [zNormEEGDetNOStim{iCh}, [zerosToPad; stEEGStim.zNormEEGDetNOStim{indSelCh(iCh)}(1:end-delayDifferenceSamples,:)]];
                        perTrialNormEEGDetNOStim{iCh} = [perTrialNormEEGDetNOStim{iCh}, [zerosToPad; stEEGStim.perTrialNormEEGDetNOStim{indSelCh(iCh)}(1:end-delayDifferenceSamples,:)]];
                    else
                        EEGDetNOStimTrials{iCh} = [EEGDetNOStimTrials{iCh}, [stEEGStim.EEGDetNOStimTrials{indSelCh(iCh)}(-delayDifferenceSamples+1:end,:); zerosToPad]];
                        zNormEEGDetNOStim{iCh} = [zNormEEGDetNOStim{iCh}, [stEEGStim.zNormEEGDetNOStim{indSelCh(iCh)}(-delayDifferenceSamples+1:end,:); zerosToPad]];
                        perTrialNormEEGDetNOStim{iCh} = [perTrialNormEEGDetNOStim{iCh}, [stEEGStim.perTrialNormEEGDetNOStim{indSelCh(iCh)}(-delayDifferenceSamples+1:end,:); zerosToPad]];
                    end
                     if iCh==2, indFileDetNoStimEv = [indFileDetNoStimEv, iFile*ones(1,size(stEEGStim.EEGDetNOStimTrials{indSelCh(iCh)},2))]; end
                   case 'ALL'
                    EEGStimTrials{iCh} = [EEGStimTrials{iCh}, stEEGStim.EEGStimTrials{indSelCh(iCh)}];
                    zNormEEGStim{iCh} = [zNormEEGStim{iCh}, stEEGStim.zNormEEGStim{indSelCh(iCh)}];
                    perTrialNormEEGStim{iCh} = [perTrialNormEEGStim{iCh}, stEEGStim.perTrialNormEEGStim{indSelCh(iCh)}];
                    if iCh==2, indFileAllEv = [indFileAllEv, iFile*ones(1,size(stEEGStim.EEGStimTrials{indSelCh(iCh)},2))];end
            end
        end
    end
    hdr.allFiles{iFile} = hdr;
    infoBaseline.allFiles{iFile} = infoBaseline;
end

%% Exclude indicated trials
if ~isempty(trialsToExclude)
    for iCh=1:length(indSelCh)
        if isfield(trialsToExclude, 'DetStim') % indicate trials to exclude
            EEGDetStimTrials{iCh}(:,trialsToExclude.DetStim) = [];
            zNormEEGDetStim{iCh}(:,trialsToExclude.DetStim) = [];
            perTrialNormDetStim{iCh}(:,trialsToExclude.DetStim) = [];
        end
        if isfield(trialsToExclude, 'RandomStim') % indicate trials to exclude
            EEGRandomStimTrials{iCh}(:,trialsToExclude.RandomStim) = [];
            zNormEEGRandomStim{iCh}(:,trialsToExclude.RandomStim) = [];
            perTrialNormEEGRandomStim{iCh}(:,trialsToExclude.RandomStim) = [];
        end
        if isfield(trialsToExclude, 'DetNoStim') % indicate trials to exclude
            EEGDetNOStimTrials{iCh}(:,trialsToExclude.DetNoStim) = [];
            zNormEEGDetNOStim{iCh}(:,trialsToExclude.DetNoStim) = [];
            perTrialNormEEGDetNOStim{iCh}(:,trialsToExclude.DetNoStim) = [];
        end
        if isfield(trialsToExclude, 'All') % indicate trials to exclude
            EEGStimTrials{iCh}(:,trialsToExclude.All) = [];
            zNormEEGStim{iCh}(:,trialsToExclude.All) = [];
            perTrialNormEEGStim{iCh}(:,trialsToExclude.All) = [];
        end
    end
end

%% Save in new file
newPath = fileparts(newMATFileName);
if ~exist(newPath,'dir'), mkdir(newPath); end
save(newMATFileName,'EEGStimTrials','EEGRandomStimTrials','EEGDetStimTrials','EEGDetNOStimTrials',...
    'zNormEEGStim','perTrialNormEEGStim','zNormEEGDetStim','perTrialNormDetStim','zNormEEGRandomStim','perTrialNormEEGRandomStim','zNormEEGDetNOStim','perTrialNormEEGDetNOStim',...
    'chNamesSelected','chNamesBipolar','chNamesReferential','useBipolar','titName',...
    'indFileDetStimEv','indFileRandStimEv','indFileDetNoStimEv','indFileAllEv','fileNameEEGStimAllTrials',...
    'tBeforeStimSec','tAfterStimSec','timePerTrialSec','hdr','allChNames','cfgInfoPeaks','stimAINP', 'startNSxSec', 'endNSxSec','infoBaseline','stimSiteNames','stimChannInfo');

