function newMATFileName = mergeEEGStimFrom2NSPs(fileNameEEGStimTrial, newMATFileName, newTitName, trialsToExclude)


if ~exist('newMATFileName','var'), newMATFileName=[]; end % newMATFileName could be a filename or a directory
if ~exist('newTitName','var'), newTitName=[]; end
if ~exist('trialsToExclude','var'), trialsToExclude =[]; end

indTrialsToExcludePerCh=[];
trialsToExcludePerCh=[];

%% load first file to get all the common variables
if isempty(fileNameEEGStimTrial{1})
    disp(['Exiting - Empty file: ', fileNameEEGStimTrial{1}]);
    if isfolder(newMATFileName)
        newMATFileName=[];
    end
    return;
end
load(fileNameEEGStimTrial{1});
nChannels = length(chNamesSelected);
if ~isempty(newTitName)
    titName = newTitName;
else
    titName = [titName,'_AllCh'];
end

hdr.allFiles{1} = hdr;
infoBaseline.allFiles{1} = infoBaseline;
fileNameEEGStimAllTrials = fileNameEEGStimTrial; % save under a different name to store at the end

indTimeSTIMPerFile{1} = indTimeSTIM;

% store information of where each event is coming from
indFileAllEv = ones(1,size(EEGStimTrials{1},2));


%% Add trials from all other files - ASSUME SAME STIM CHANNELS
for iFile =2:numel(fileNameEEGStimTrial) %First one is already loaded
    stEEGStim = load(fileNameEEGStimTrial{iFile});
     if ~strcmp([stimSiteNames{:}], [stEEGStim.stimSiteNames{:}])
         disp(['Warning! different STIM channels!',[stimSiteNames{:}], [stEEGStim.stimSiteNames{:}]])
     end
    EEGStimTrials = [EEGStimTrials, stEEGStim.EEGStimTrials];
    zNormEEGStim = [zNormEEGStim, stEEGStim.zNormEEGStim];
    perTrialNormEEGStim = [perTrialNormEEGStim, stEEGStim.perTrialNormEEGStim];
    zNormZeroMeanEEGStim = [zNormZeroMeanEEGStim, stEEGStim.zNormZeroMeanEEGStim];
    
    allChNames = [allChNames; stEEGStim.allChNames];
    allChNamesBipolar = [allChNamesBipolar; stEEGStim.allChNamesBipolar];
    allChNamesReferential = [allChNamesReferential; stEEGStim.allChNamesReferential];
    chNamesSelected = [chNamesSelected, stEEGStim.chNamesSelected];
    if isfield(stEEGStim,'indTrialsToExcludePerCh'), indTrialsToExcludePerCh =[indTrialsToExcludePerCh, stEEGStim.indTrialsToExcludePerCh]; end
    if isfield(stEEGStim,'trialsToExcludePerCh'), trialsToExcludePerCh =[trialsToExcludePerCh, stEEGStim.trialsToExcludePerCh]; end

    hdr.allFiles{iFile} = hdr;
    stdBaseline =[stdBaseline, stEEGStim.stdBaseline];
    meanBaseline =[meanBaseline, stEEGStim.meanBaseline];
    infoBaseline.allFiles{iFile} = infoBaseline;
    indTimeSTIMPerFile{iFile} = indTimeSTIM;
end
infoBaseline.meanBaseline = meanBaseline;
infoBaseline.stdBaseline = stdBaseline;

%% Exclude indicated trials
if ~isempty(trialsToExclude)
    for iCh=1:length(EEGStimTrials)
        EEGStimTrials{iCh}(:,trialsToExclude) = [];
        zNormEEGStim{iCh}(:,trialsToExclude) = [];
%        zNormZeroMeanEEGStim{iCh}(:,trialsToExclude) = [];
        perTrialNormEEGStim{iCh}(:,trialsToExclude) = [];
    end
end

%% Save in new file
if isempty(newMATFileName)
    dirResults = fileparts(fileNameEEGStimTrial{1});
    newMATFileName = [dirResults, filesep, pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],'_bipEEG_StimTrials.mat']; % if nothing changed - at least titName SHOULD BE NEW 
end
if isfolder(newMATFileName)
    dirResults = newMATFileName;
    newMATFileName = [dirResults, filesep, pName,'_',titName,'_',[stimSiteNames{1},'-',stimSiteNames{2}],'_bipEEG_StimTrials.mat']; % if nothing changed - at least titName SHOULD BE NEW 
end  
copyfile(fileNameEEGStimTrial{1}, newMATFileName)
newPath = fileparts(newMATFileName);
if ~exist(newPath,'dir'), mkdir(newPath); end
save(newMATFileName, 'EEGStimTrials','zNormEEGStim','perTrialNormEEGStim','zNormZeroMeanEEGStim', ...
                     'allChNames','allChNamesBipolar','allChNamesReferential','chNamesSelected',...
                     'indTrialsToExcludePerCh','trialsToExcludePerCh','stdBaseline','meanBaseline',...
                     'hdr', 'trialsToExclude','titName','infoBaseline','-append');
 
% From AnesthesiaAnalysis:
%   save(EEGStimTrialMATfile,'EEGStimTrials','zNormEEGStim','perTrialNormEEGStim','zNormZeroMeanEEGStim',...
%     'chNamesSelected','allChNamesBipolar','allChNamesReferential','allChNames','stimSiteNames','stimChannInfo','useBipolar','useAbsolute','REMOVESTIM','REMOVE60Hz',...
%     'indTimeSTIM','indPerSite','indTimePerStimPerSite','stimSitesFromLog','stWithStimInfo','cellWithStimInfo','stimSiteNSP',...
%     'isAudioResponse','firstLossConscTrial','audioRespRT','stAudioTask',...
%     'titName','tBeforeStimSec','tAfterStimSec','timePerTrialSec','stimChannInfo','indStim','infoBaseline','meanBaseline','stdBaseline','hdr','pName');

                    
