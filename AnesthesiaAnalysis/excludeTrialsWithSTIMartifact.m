function [indTrialsToExcludePerCh, trialsToExcludeFromTotal] = excludeTrialsWithSTIMartifact(EEGStimTrialMATfile, distInSecFromSTIM, dirResults)

%% Trials to EXCLUDE - per Channel
% Find Trials to exclude for each recording channel that is also used for stimulation
% IF we run a small matrix with ONLY channels of interest - this step is not necessary

%% COnfig
% if ~exist('newEEGStimTrialMATfile','var') || isempty(newEEGStimTrialMATfile)
%     newEEGStimTrialMATfile= [EEGStimTrialMATfile(1:end-4),'_CleanStimArtif','.mat'];
% end 
[onlyPath, onlyFileName] = fileparts(EEGStimTrialMATfile);
if ~exist('dirResults','var')
    dirResults = [onlyPath,filesep,'trialsToExclude'];
end

if ~exist('distInSecFromSTIM','var') || isempty(distInSecFromSTIM), distInSecFromSTIM=5; end % exclude 10seconds following stim 

columnNSP =4;
columnStimCh1=5;
columnStimCh2=6;

%% Load data
stEEGStimTrial = load(EEGStimTrialMATfile);
stWithStimInfo = stEEGStimTrial.stWithStimInfo;
[allChNamesWithStim,indUnique] = unique([stWithStimInfo.chName],'stable'); %allChNames(allChNumbersWithStim);
allChNumbersWithStim = [stWithStimInfo.chNumberInNSX]; 
allChNumbersWithStim = allChNumbersWithStim(indUnique);
allNSPNumberWithStim = [stWithStimInfo.NSPnumber]; 
allNSPNumberWithStim = allNSPNumberWithStim(indUnique);
% stimChNumberCerestim = stEEGStimTrial.stimChannInfo.stimChNumber;
% stimChNumberNSX = stEEGStimTrial.stimChannInfo.stimChNumberInNSX;
% stimChNames = stEEGStimTrial.stimChannInfo.stimChNames;
% stimSiteNSPnumber = stEEGStimTrial.stimChannInfo.NSPnumber;
allChNames = stEEGStimTrial.allChNames;
chNamesSelected = stEEGStimTrial.chNamesSelected;
EEGStimTrialsOrig = stEEGStimTrial.EEGStimTrials;
perTrialNormEEGStimOrig = stEEGStimTrial.perTrialNormEEGStim;
zNormEEGStimOrig = stEEGStimTrial.zNormEEGStim;
zNormZeroMeanEEGStimOrig = stEEGStimTrial.zNormZeroMeanEEGStim;
trialStimPerSite = stEEGStimTrial.indPerSite{1}; %trial number that correspond to these data after removing those with general trial artifacts
stimSiteNSP = stEEGStimTrial.stimSiteNSP; % Which NSP is this data from
stimSitesFromLog = stEEGStimTrial.stimSitesFromLog; % stimSitesFromLog is #stim | Cerstim ch1 | Cerstim ch2 | NSP | NSX ch1 |NSX ch2
%indNSP = stEEGStimTrial.stimChannInfo.indNSP;

%% Find for each Channel that had STIM - from the TXT file!
% indChInThisNSP = find(stimSitesFromLog(:,4) == indNSP); %find([stWithStimInfo.NSPnumber] == stimSiteNSP);
% allChNumbersWithStim = unique(stimSitesFromLog(indChInThisNSP,5:6) ; % cols 5-6 have the NSX number 

%allChNamesWithStim = stimChNames(:); %allChNames(allChNumbersWithStim);
allChNamesWithStim = regexprep(allChNamesWithStim,'\W',''); %remove extra spaces & / and get contacts names
% Find mind distance in trials based on desiderd distance in sec and interstiminterval
interStimInterval = mean(diff(stEEGStimTrial.indTimeSTIM));
distInTrialsFromSTIM = round((distInSecFromSTIM * stEEGStimTrial.hdr.Fs) /interStimInterval);
indTrialsFromSTIM = 0:distInTrialsFromSTIM;

% Find trials to Exclude within the ones in this file
indTrialsToExcludePerCh= cell(1,numel(chNamesSelected));
trialsToExcludeFromTotal = cell(1,numel(chNamesSelected));
for iCh=1:numel(chNamesSelected)
    contactNames = split(chNamesSelected{iCh},'-');
    for iCont=1:length(contactNames)
        indChInStimCh = find(strcmpi(allChNamesWithStim, contactNames{iCont}));
        if ~isempty(indChInStimCh)
            % This channel has STIM -> exclude trials that are too close to STIM
            chNumber = allChNumbersWithStim(indChInStimCh);
            indNSP = allNSPNumberWithStim(indChInStimCh);
            indChInThisNSP = find(stimSitesFromLog(:,4) == indNSP);
            trialsWithStimPerCh = intersect(indChInThisNSP,[find(stimSitesFromLog(:,5)==chNumber); find(stimSitesFromLog(:,6)==chNumber)]); % same thing as indPerSite{indChInStimCh};
            
            allTrialsToExclude = trialsWithStimPerCh + indTrialsFromSTIM;
            [trialsToExclude inTrialsToExclude] = intersect(trialStimPerSite, allTrialsToExclude(:));
            trialsToExcludeFromTotal{iCh} = unique([trialsToExcludeFromTotal{iCh};trialsToExclude]); % exclude those that correspond to these data
            indTrialsToExcludePerCh{iCh} = unique([indTrialsToExcludePerCh{iCh};inTrialsToExclude]); % exclude those that correspond to these data
        end
    end
    trialsToExcludeFromTotal{iCh} = unique(trialsToExcludeFromTotal{iCh}); % to remove duplicates
    indTrialsToExcludePerCh{iCh} = unique(indTrialsToExcludePerCh{iCh}); % to remove duplicates
end

% %% Remove trials woth STIM artifacts
% for iCh =1: length(chNamesSelected)
%     trialsToKeep=1:size(EEGStimTrialsOrig{iCh},2);
%     trialsToKeep(intersect(indTrialsToExcludePerCh{iCh},trialsToKeep))=[];
%     EEGStimTrials{iCh} = detrend(EEGStimTrialsOrig{iCh}(:,trialsToKeep));
%     perTrialNormEEGStim{iCh} = detrend(perTrialNormEEGStimOrig{iCh}(:,trialsToKeep));
%     zNormEEGStim{iCh} = detrend(zNormEEGStimOrig{iCh}(:,trialsToKeep));
%     zNormZeroMeanEEGStim{iCh} = detrend(zNormZeroMeanEEGStimOrig{iCh}(:,trialsToKeep));
% end
% 

%% save new file
% if ~strcmpi(EEGStimTrialMATfile, newEEGStimTrialMATfile)
%     copyfile(EEGStimTrialMATfile, newEEGStimTrialMATfile);
% end
% save(newEEGStimTrialMATfile,'EEGStimTrials','perTrialNormEEGStim','zNormEEGStim','zNormZeroMeanEEGStim','indTrialsToExcludePerCh','trialsToExcludePerCh','-append');

% save only trials to remove - to have separate small files with the relevant info 
if ~exist(dirResults,'dir'),mkdir(dirResults);end
save([dirResults, filesep, onlyFileName,'_TrialsToExcludeStim','.mat'],...
    'chNamesSelected','allChNamesWithStim','EEGStimTrialMATfile',...
    'distInSecFromSTIM','distInTrialsFromSTIM','stWithStimInfo',...
    'indTrialsToExcludePerCh','trialsToExcludeFromTotal');
% 


