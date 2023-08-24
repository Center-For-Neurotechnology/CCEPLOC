function [fileNamesAnesthesia, fileNamesWakeOR, fileNamesWakeEMU, fileNamesSleep] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameMATfiles, originalDir, thisPCDir, channInfo)

% Config
if ~exist('originalDir','var')
    originalDir=[]; % where the files were originally
end
if ~exist('thisPCDir','var')
    thisPCDir=[]; % where are the files with respect to fileNameMATfiles
end
if ~exist('channInfo','var'),channInfo=struct(); end

% Initialize
fileNamesAnesthesia= cell(0,0);
fileNamesWakeEMU= cell(0,0);
fileNamesSleep= cell(0,0);
fileNamesWakeOR = cell(0,0);

%% Files and Directories
stFileNames = load(fileNameMATfiles);
if ~isempty(originalDir) && ~isempty(thisPCDir)
    %Files
    if isfield(stFileNames,'EEGStimTrialMATfileAnest')
        fileNamesAnesthesia = unique(regexprep(stFileNames.EEGStimTrialMATfileAnest, originalDir, thisPCDir, 'ignorecase'),'stable');
        if ~ispc, fileNamesAnesthesia = regexprep(fileNamesAnesthesia,'\\','/'); end
    end
    if isfield(stFileNames,'EEGStimTrialMATfileWakeOR')
        fileNamesWakeOR = unique(regexprep(stFileNames.EEGStimTrialMATfileWakeOR, originalDir, thisPCDir, 'ignorecase'),'stable');
        if ~ispc, fileNamesWakeOR = regexprep(fileNamesWakeOR,'\\','/'); end
    end
    if isfield(stFileNames,'EEGStimTrialMATfileWakeEMU')
        fileNamesWakeEMU = unique(regexprep(stFileNames.EEGStimTrialMATfileWakeEMU, originalDir, thisPCDir, 'ignorecase'),'stable');
        if ~ispc,fileNamesWakeEMU = regexprep(fileNamesWakeEMU,'\\','/'); end
    end
    if isfield(stFileNames,'EEGStimTrialMATfileWake')
        fileNamesWakeEMU = unique(regexprep(stFileNames.EEGStimTrialMATfileWake, originalDir, thisPCDir, 'ignorecase'),'stable');
        if ~ispc, fileNamesWakeEMU = regexprep(fileNamesWakeEMU,'\\','/'); end
    end
    if isfield(channInfo,'wakeFilePreFix')
        fileNamesWake1=cell(0,0);
        for iFile=1:length(fileNamesWakeEMU)
            if ~isempty(fileNamesWakeEMU) && ~isempty(strfind(fileNamesWakeEMU{iFile},channInfo.wakeFilePreFix))
                fileNamesWake1 = [fileNamesWake1, fileNamesWakeEMU{iFile}];
            end
        end
        fileNamesWakeEMU=fileNamesWake1;
    end
    if isfield(stFileNames,'EEGStimTrialMATfileSleep')
        fileNamesSleep = unique(regexprep(stFileNames.EEGStimTrialMATfileSleep, originalDir, thisPCDir, 'ignorecase'),'stable');
        if ~ispc, fileNamesSleep = regexprep(fileNamesSleep,'\\','/'); end
    end
    
else
    if isfield(stFileNames,'EEGStimTrialMATfileAnest')
        fileNamesAnesthesia = unique(stFileNames.EEGStimTrialMATfileAnest,'stable');
    end
    if isfield(stFileNames,'EEGStimTrialMATfileWakeOR')
        fileNamesWakeOR = unique(stFileNames.EEGStimTrialMATfileWakeOR,'stable');
    end
    if isfield(stFileNames,'EEGStimTrialMATfileWakeEMU')
        fileNamesWakeEMU = unique(stFileNames.EEGStimTrialMATfileWakeEMU,'stable');
    end
    if isfield(stFileNames,'EEGStimTrialMATfileWake')
        fileNamesWakeEMU = unique(stFileNames.EEGStimTrialMATfileWake,'stable');
    end
    if isfield(channInfo,'wakeFilePreFix')
       fileNamesWake1=cell(0,0);
        for iFile=1:length(fileNamesWakeEMU)
            if ~isempty(fileNamesWakeEMU) && ~isempty(strfind(fileNamesWakeEMU{iFile},channInfo.wakeFilePreFix))
                fileNamesWake1 = [fileNamesWake1, fileNamesWakeEMU{iFile}];
            end
        end
        fileNamesWakeEMU=fileNamesWake1;
    end
    if isfield(stFileNames,'EEGStimTrialMATfileSleep')
        fileNamesSleep = unique(stFileNames.EEGStimTrialMATfileSleep,'stable');
    end
    
end
