function appendParcelation(fileNamesToAppend,dirParcelationFiles, chNamesChange)

% Files for Anatomical Information

for iFile =1:length(fileNamesToAppend)
    EEGStimTrialMATfile = fileNamesToAppend{iFile};
    stEEGStim = load(EEGStimTrialMATfile,'stimChannInfo','pName');
    pName = stEEGStim.pName;
    if isfield(stEEGStim.stimChannInfo,'useBipolar') && stEEGStim.stimChannInfo.useBipolar == 0
        fileNameParc =  [dirParcelationFiles, filesep, [pName, '_aparc.DKTatlas40_electrodes_cigar_r_3_l_4.csv']]; % contains the referential parcelation
    else
        fileNameParc =  [dirParcelationFiles, filesep, [pName, '_aparc.DKTatlas40_electrodes_cigar_r_3_l_4_bipolar.csv']]; % contains the bipolar parcelation
    end
    fileNameRAS = [dirParcelationFiles, filesep, [pName, '_RAS.csv']]; % RAS contains the coordinates
    
    % run parcelation and save in file
    getBrainRegionFromMMTV(fileNameParc, fileNameRAS, EEGStimTrialMATfile, 1,0, chNamesChange);
    disp(['File ',EEGStimTrialMATfile ,' corrected'])

end


