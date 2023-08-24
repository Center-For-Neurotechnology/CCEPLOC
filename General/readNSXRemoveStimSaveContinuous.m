function  [allEEGContinousMATfile, indTimeSTIMPerFile,  allChNames, hdr] = readNSXRemoveStimSaveContinuous(fileNameNSxPerNSP, dirResults, stimAINPChNames, channInfo, titName, startNSxSec, endNSxSec)
% read NSX remove stim artifact and divide iEEG from scalp data and save as MAT

%% Config
chNamesToExcludeInput =[];
if isfield(channInfo,'chNamesToExcludeInput'),chNamesToExcludeInput= channInfo.chNamesToExcludeInput; end
if isfield(channInfo,'chNamesToExclude'),chNamesToExcludeInput= channInfo.chNamesToExclude; end

chNamesToExcludeDefault = {'ainp','empty','EMG','chan','EKG','SYNC','TRIGGER','IMAGE','DETECT','SHAM','SEND STIM'}; % remove AINP,"empty" and EMG channels
chNamesToExcludeDefault = [chNamesToExcludeDefault, cellfun(@num2str,num2cell(34:46),'UniformOutput',false)];
chNamesScalp = {'T1','T2','T3','T4','T5','T6','F3', 'F4', 'F7', 'F8','Fp1','Fp2','Fz', 'Cz','Pz', 'C3', 'C4','P3','P4', 'O1', 'O2', 'A1', 'A2','LOC','ROC','CII'}; % remove scalp electrodes / analyse separately
chNamesToExclude = [chNamesToExcludeDefault, chNamesToExcludeInput, chNamesScalp]; % Save Scalp data apart

%Time 
if ~exist('startNSxSec','var') || isempty(startNSxSec)
    startNSxSec= 0; %6.2*10^5/2000;
end
if ~exist('endNSxSec','var')
    endNSxSec = [];
end

dirImages = [dirResults, filesep, 'images'];
if ~exist(dirImages,'dir'), mkdir(dirImages); end

pName = channInfo.pName;

if ~exist('titName','var') || isempty(titName)
    titName = 'ContiEEG';
end
if ~isfield(channInfo,'isStimInAINP')
    channInfo.isStimInAINP=1; %Default is stim info on AINP (SYNC)
end
if isfield(channInfo, 'useBipolar')
    useBipolar = channInfo.useBipolar;
else
    useBipolar = 1;   % DEFAULT: use BIPOLAR montage
end

if ~isfield(channInfo, 'stimSiteNames')
    channInfo.stimSiteNames = []; 
end

% Start Diary
diary([dirResults,filesep,'log',pName,'scriptContEEGfromNSX.log'])

minSTIMDistance = 50; % 25ms minimum distance between pulse - to aviod several hits

%% Plot Stim
allEEGContinousMATfile=[];
for iNSP=1:numel(fileNameNSxPerNSP)
    % per NSP - NOT aligned!!
    selChNames1 = []; 
    selBipolar1 = reshape(1:length(selChNames1),2,length(selChNames1)/2)'; %[1,2;3,4;5,6;7,8];
    % Compare to values on TXT file to find if trial 0 correponds to first trial
    [dataBipolarPerCh, allChNamesBipolar, dataStim, indTimeAllSTIM, dataReferentialPerCh, allChNamesReferential, allChNames, hdr] = GetBipolarEEGFromNSX(fileNameNSxPerNSP{iNSP}, selChNames1, selBipolar1, stimAINPChNames, startNSxSec, endNSxSec);
    if channInfo.isStimInAINP ==1 % whether stim information is on AINP or we should get it from stim artifact on stim channels
        indTimeSTIM = indTimeAllSTIM{1};
    else
        indTimeSTIM = unique([indTimeAllSTIM{:}]); % All instead of first to take into account when no AINp but each - Before:indTimeAllSTIM{1};
    end
    indSameStim = find(diff([0 indTimeSTIM])<=minSTIMDistance); % remove those that are too close (they correspond to the same stim pulse
    indTimeSTIM(indSameStim)=[];
    indTimeSTIMPerFile{1} = indTimeSTIM;
    
    %% Decide whether to use Referential or Bipolar data
    [dataPerAllCh, chNamesAll] = createIEEGMontage(useBipolar, dataReferentialPerCh, allChNamesReferential);

    %% organize channels in iEEG and exclude some channels
    [dataPerCh, chNamesSelected, iChToAnalyse] = organizeiEEGChannels(dataPerAllCh, chNamesAll, chNamesToExclude, channInfo.stimSiteNames);
    
    %% Create also scalp montage
    [dataPerScalpCh, chNamesScalpSelected, channInfo] = createScalpMontage(dataReferentialPerCh, allChNamesReferential, channInfo);
    
    %% remove STIM artifact -
    [dataPerCh] = removeStimArtifactAndCCEP(dataPerCh, indTimeSTIM);
    [dataPerScalpCh] = removeStimArtifactAndCCEP(dataPerScalpCh, indTimeSTIM);
    
    
    %% Save continuous and organized data
    if ~exist(dirResults,'dir'), mkdir(dirResults); end
    disp([pName,'_',titName,'_', 'STIM - done!'])
    % Save also contiuous data without STIM artifact
    EEGContinousMATfile = [dirResults, filesep, pName,'_',titName,'_NSP',num2str(iNSP),'_Continuous.mat'];
    save(EEGContinousMATfile,'dataPerCh','indTimeSTIM',...
        'chNamesSelected','allChNamesBipolar','allChNamesReferential','channInfo','useBipolar','iChToAnalyse',...
        'titName','chNamesToExclude','hdr','pName','-v7.3');
    EEGContinousScalpMATfile = [dirResults, filesep, pName,'_',titName,'_NSP',num2str(iNSP),'_ScalpContinuous.mat'];
    save(EEGContinousScalpMATfile,'dataPerScalpCh','indTimeSTIM',...
        'chNamesScalpSelected','allChNamesBipolar','allChNamesReferential','channInfo','useBipolar',...
        'titName','chNamesToExclude','hdr','pName');
    
    allEEGContinousMATfile =[allEEGContinousMATfile, EEGContinousMATfile, EEGContinousScalpMATfile,];
    
end

%%
diary off

%% From Notes:
