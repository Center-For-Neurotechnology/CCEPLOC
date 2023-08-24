function [stSelChannelInfo, stStimChannelInfo] = getBrainRegionFromMMTV(fileNameParc, fileNameRAS, EEGStimTrialMATfile, useSave, needToInvertChannels, chNamesChange)

%% CONFIG
%fileNameParc = [dirGral, filesep, pName, filesep, 'MMVT', filesep, strcat(pName, '_aparc.DKTatlas40_electrodes_cigar_r_3_l_4.csv')]; % cigar contains the bipolar 
%fileNameRAS = [dirGral, filesep, pName, filesep, 'MMVT', filesep, strcat(pName, '_RAS.xlsx')];
%useBipolar = 1;
if ~exist('useSave','var'), useSave=1; end %whether to append anatomical info to EEGStimTrialMATfile file
if ~exist('needToInvertChannels','var'), needToInvertChannels=0; end %whether to Channel names are Ch2-Ch1 or they need to be inverted
if ~exist('chNamesChange','var'), chNamesChange=[]; end %if a Channel name needs to be changed (e.g. LOF -> LFO) - must be a struct with chNamesChange{1}.nsxChName = 'LOF' / chNamesChange{1}.parcChName='LFO'

% % We add some accronyms to the brain locations - MUST be SAME quantity as
% in parcellationMapping
TargetLabelsAccr={'dlPFC'
    'dmPFC'
    'vlPFC' %= inferior frontal 
    'mOFC'
    'lOFC'
    'rACC'
    'cACC'
    'isCC'
    'pCC'
    'Amyg'
    'Ent'
    'HC' %    'Hippocampus'    'parahippocampal'
    'Insu'
    'Accum'
    'Caud'
    'Putam'
    'Temp' %inferiortemporal transversetemporal middletemporal superiortemporal
    'Fusi'
    'Cent' %paracentral postcentral precentral
    'SupMar'
    'preC'
    'Pari' % inferiorparietal superiorparietal
    'Cun'
    'Ling' % put together with occipital?
    'Occ' %lateraloccipital
    'Calcar' % Calcarine put together with occipital
    'Thal'
    'unkwn'
    };

if isempty(EEGStimTrialMATfile) || ~isfile(EEGStimTrialMATfile)
    disp([EEGStimTrialMATfile, ' is NOT a file - Exiting getRegions from MMVT']);
    stSelChannelInfo=[];
    stStimChannelInfo=[];
    return;
end
%% Read chNamesSelected, stimSiteNames from EEG file
stChInfo = load(EEGStimTrialMATfile, 'chNamesSelected', 'stimSiteNames', 'pName', 'useBipolar');
chNamesSelected = stChInfo.chNamesSelected;
stimSiteNames = stChInfo.stimSiteNames;
pName = stChInfo.pName;
useBipolar = stChInfo.useBipolar;

%% Adapt ChNames to MMVT style
%1. Flip channel Name - it is Ch2-Ch1 in MMVT - MMVT is ACTUALLY CORRECT -
%RIZ: CORRECTED in code, NOT used on regular basis, left for hisotrical/backup reasons
% in the meantime flip the name
if needToInvertChannels
    chNamesSelectedCh2Ch1 = cell(size(chNamesSelected));
    for iCh=1:length(chNamesSelected)
        chOnly = split(chNamesSelected{iCh},'-');
        chNamesSelectedCh2Ch1{iCh} = strcat(chOnly{2},'-',chOnly{1});
    end
else
    chNamesSelectedCh2Ch1 = chNamesSelected;
end

% 3. Repeat for StimChannel (it is not in chNamesSelectedCh2Ch1)
stimSiteNamesCh2Ch1 = strcat(stimSiteNames(2),'-',stimSiteNames(1));

%% Patient specific corrections to fix wrong RAS/PARC labels
% labels to be changed must be specified in the patient's script
if ~isempty(chNamesChange) 
    if ~iscell(chNamesChange), chNamesChange={chNamesChange}; end
    for iCh=1:length(chNamesChange)
        chNamesSelectedCh2Ch1 = regexprep(chNamesSelectedCh2Ch1,chNamesChange{iCh}.nsxChName,chNamesChange{iCh}.parcChName);
        stimSiteNamesCh2Ch1 = regexprep(stimSiteNamesCh2Ch1,chNamesChange{iCh}.nsxChName,chNamesChange{iCh}.parcChName);
    end
end

%% get parcellation from csv/xls files  
[parcelationLabelPerCh, ProbabilityMapping, RASCoordPerCh, parcelationLabelPerChStimCh, ProbabilityMappingStimCh, RASCoordPerChStimCh, ProbabilityMappingHeader, TargetLabels] = ...
    parcellationMappingBipolar(fileNameParc,fileNameRAS,chNamesSelectedCh2Ch1, stimSiteNamesCh2Ch1, useBipolar);

% Check if labels are wrong (if so add in chNamesChange)
% one easy way is if RAS is zeros
indWrongChName = find(~any(RASCoordPerCh,2));
indWrongStimChName = find(~any(RASCoordPerChStimCh,2));

if ~isempty(indWrongChName) || ~isempty(indWrongStimChName)
    disp(['Channels: ',chNamesSelectedCh2Ch1(indWrongChName),' not found in PARC/RAS - Trying with 1 instead of 01'])
    % 2. Change 01 to 1 and 1 to 01
    chNamesSelectedCh2Ch1_1 = regexprep(chNamesSelectedCh2Ch1,'0(?=\d)','');
    indChWithout0 = find(~cellfun(@isempty,regexp(chNamesSelectedCh2Ch1,'\D\d\D')));
    for iCh=1:length(indChWithout0)
        indNumber = regexp(chNamesSelectedCh2Ch1{indChWithout0(iCh)},'\D\d'); % not taking 9-10 into accoount!
        if length(indNumber)==2
            chNamesSelectedCh2Ch1_1{indChWithout0(iCh)} = strcat(chNamesSelectedCh2Ch1{indChWithout0(iCh)}(1:indNumber(1)),'0',chNamesSelectedCh2Ch1{indChWithout0(iCh)}(indNumber(1)+1:indNumber(2)),'0',chNamesSelectedCh2Ch1{indChWithout0(iCh)}(indNumber(2)+1:end));        
        elseif length(indNumber)==1 % assume we are in 9-10 case
             chNamesSelectedCh2Ch1_1{indChWithout0(iCh)} = strcat(chNamesSelectedCh2Ch1{indChWithout0(iCh)}(1:indNumber(1)),'0',chNamesSelectedCh2Ch1{indChWithout0(iCh)}(indNumber(1)+1:end));        
        end
    end
    stimSiteNamesCh2Ch1_1 = regexprep(stimSiteNamesCh2Ch1,'0(?=\d)','');
    indStimChWithout0 = find(~cellfun(@isempty,regexp(stimSiteNamesCh2Ch1,'\D\d\D')));
    if ~isempty(indStimChWithout0)
        indNumber = regexp(stimSiteNamesCh2Ch1{indStimChWithout0},'\D\d'); % not taking 9-10 into accoount!
        if length(indNumber)==2
            stimSiteNamesCh2Ch1_1{indStimChWithout0} = strcat(stimSiteNamesCh2Ch1{indStimChWithout0}(1:indNumber(1)),'0',stimSiteNamesCh2Ch1{indStimChWithout0}(indNumber(1)+1:indNumber(2)),'0',stimSiteNamesCh2Ch1{indStimChWithout0}(indNumber(2)+1:end));        
        elseif length(indNumber)==1 % assume we are in 9-10 case
             stimSiteNamesCh2Ch1_1{indStimChWithout0} = strcat(stimSiteNamesCh2Ch1{indStimChWithout0}(1:indNumber(1)),'0',stimSiteNamesCh2Ch1{indStimChWithout0}(indNumber(1)+1:end));        
        end        
    end

    % get new parcellation info
    [parcelationLabelPerCh_1, ProbabilityMapping_1, RASCoordPerCh_1, parcelationLabelPerChStimCh_1, ProbabilityMappingStimCh_1, RASCoordPerChStimCh_1, ProbabilityMappingHeader, TargetLabels] = ...
    parcellationMappingBipolar(fileNameParc,fileNameRAS,chNamesSelectedCh2Ch1_1, stimSiteNamesCh2Ch1_1, useBipolar);
    % reassign missing ones
    if  ~isempty(indWrongChName)
        parcelationLabelPerCh(indWrongChName) = parcelationLabelPerCh_1(indWrongChName);
        ProbabilityMapping(indWrongChName,:) = ProbabilityMapping_1(indWrongChName,:);
        RASCoordPerCh(indWrongChName,:) = RASCoordPerCh_1(indWrongChName,:);
    end
    if ~isempty(indWrongStimChName)
        parcelationLabelPerChStimCh(indWrongStimChName) = parcelationLabelPerChStimCh_1(indWrongStimChName);
        ProbabilityMappingStimCh(indWrongStimChName,:) = ProbabilityMappingStimCh_1(indWrongStimChName,:);
        RASCoordPerChStimCh(indWrongStimChName,:) = RASCoordPerChStimCh_1(indWrongStimChName,:);        
    end
end

% Check AGAIN if labels are wrong - one easy way is if RAS is zeros
indWrongChName = find(~any(RASCoordPerCh,2));
indWrongStimChName = find(~any(RASCoordPerChStimCh,2));
if ~isempty(indWrongChName) || ~isempty(indWrongStimChName)
    disp(['Channels: ',chNamesSelectedCh2Ch1(indWrongChName),'STILL not found in PARC/RAS - CHECK your naming'])
end

% Assign 0 to label 'unknow'
for iCh = 1:length(ProbabilityMapping(:,1))
    if ProbabilityMapping(iCh,8) == 0 % Unknown
         ProbabilityMapping(iCh,8) = length(TargetLabelsAccr); % To add an unknown label (the last label)
    end
end
for iCh = 1:length(ProbabilityMappingStimCh(:,1))
    if ProbabilityMappingStimCh(iCh,8) == 0 % Unknown
         ProbabilityMappingStimCh(iCh,8) = length(TargetLabelsAccr); % To add an unknown label (the last label)
    end
end
%% Write names per channel as anatomical regions
anatRegionsPerCh = cell(size(chNamesSelectedCh2Ch1));
for iCh = 1:length(anatRegionsPerCh)
    indParc = ProbabilityMapping(iCh,8);
    anatRegionsPerCh{iCh} = TargetLabelsAccr{indParc};
end

anatRegionsStimCh = cell(size(stimSiteNamesCh2Ch1));
for iCh = 1:length(anatRegionsStimCh)
    indParc = ProbabilityMappingStimCh(iCh,8);
    anatRegionsStimCh{iCh} = TargetLabelsAccr{indParc};
end
%% Organize as struct with all the channel information
stSelChannelInfo.chNamesSelected = chNamesSelected;
stSelChannelInfo.anatRegionsPerCh = anatRegionsPerCh;
stSelChannelInfo.RASCoordPerCh = RASCoordPerCh;
stSelChannelInfo.parcelationLabelPerCh = parcelationLabelPerCh;
stSelChannelInfo.ProbabilityMapping = ProbabilityMapping;
stSelChannelInfo.ProbabilityMappingHeader = ProbabilityMappingHeader;
stSelChannelInfo.chNamesSelectedCh2Ch1 = chNamesSelectedCh2Ch1;

stStimChannelInfo.stimSiteNames = stimSiteNames;
stStimChannelInfo.anatRegionsStimCh = anatRegionsStimCh;
stStimChannelInfo.RASCoordPerChStimCh = RASCoordPerChStimCh;
stStimChannelInfo.parcelationLabelPerChStimCh = parcelationLabelPerChStimCh;
stStimChannelInfo.ProbabilityMappingStimCh = ProbabilityMappingStimCh;
stStimChannelInfo.stimSiteNamesCh2Ch1 = stimSiteNamesCh2Ch1;

%% Add anatomical information into EEGStimTrialMATfile file
if useSave
    save(EEGStimTrialMATfile, 'stSelChannelInfo', 'stStimChannelInfo', 'anatRegionsPerCh', 'anatRegionsStimCh', 'RASCoordPerCh', 'RASCoordPerChStimCh', 'parcelationLabelPerCh', 'parcelationLabelPerChStimCh', ...
        'ProbabilityMapping', 'ProbabilityMappingStimCh', 'ProbabilityMappingHeader', 'TargetLabelsAccr', 'TargetLabels', '-append')
end

%% orginal Target accronysms
% TargetLabelsAccr = {'dlPFC'
%                     'dmPFC'
%                     'dlPFC'
%                     'mOFC'
%                     'lOFC'
%                     'vlPFC'
%                     'Acc'
%                     'vlPFC'
%                     'Temp'
%                     'raCg'
%                     'caCg'
%                     'pCg'
%                     'Amyg'
%                     'Hip'
%                     'Hip'
%                     'Ins'
%                     'Occ'
%                     'Cun'
%                     'Caud'
%                     'unkwn' % added specifically here but not in closed-loop code
%                     };
