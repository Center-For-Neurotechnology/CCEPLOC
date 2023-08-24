function plotWakeSleepAnesthesia(fileNameMATfiles, dirResults, channInfo)

%% Get Files to PLOT
pName = channInfo.pName;

[EEGStimTrialMATfileAnest, EEGStimTrialMATfileWakeOR, EEGStimTrialMATfileWakeEMU, EEGStimTrialMATfileSleep] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameMATfiles,[],[],channInfo);

%Dirs
if ~exist(dirResults,'dir'), mkdir(dirResults); end

% Start Diary
diary([dirResults,filesep,'log',pName,'ScriptAnesthesiaAnalysis_Plots.log'])

%% Plots - Anesthesia
titName = [pName, ' Anesth'];
dirImages = [dirResults, filesep, 'imagesAnesthesia'];

for iStimNSP=1:length(EEGStimTrialMATfileAnest)
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileAnest{iStimNSP}, channInfo, [dirImages,filesep,'EEG0Mean'], titName, 'EEG0Mean'); % Not Normlaized
%    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileAnest{iStimNSP}, channInfo, [dirImages,filesep,'EEG'], titName, 'EEG'); % Normalized
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileAnest{iStimNSP}, channInfo, [dirImages,filesep,'perTrial'], titName, 'perTrial'); % Normalized
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileAnest{iStimNSP}, channInfo, [dirImages,filesep,'zeroMeanZNorm'], titName, 'zeroMeanZNorm'); % Normalized
    
    % Save in PPT in  main images dir - to have all summaries together
    pptFileName = createReportBasedOnPlots(dirImageComplete, titNameComplete);
    %copyfile(pptFileName,dirResults);
    close all;
end

%% Plots - WakeOR
titName = [pName, ' WakeOR'];
dirImages = [dirResults, filesep, 'imagesWakeOR'];

for iStimNSP=1:length(EEGStimTrialMATfileWakeOR)
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeOR{iStimNSP}, channInfo, [dirImages,filesep,'EEG0Mean'], titName, 'EEG0Mean'); % Not Normlaized
%    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeOR{iStimNSP}, channInfo, [dirImages,filesep,'EEG'], titName, 'EEG'); % Normalized
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeOR{iStimNSP}, channInfo, [dirImages,filesep,'perTrial'], titName, 'perTrial'); % Normalized
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeOR{iStimNSP}, channInfo, [dirImages,filesep,'zeroMeanZNorm'], titName, 'zeroMeanZNorm'); % Normalized
    
    % Save in PPT in  main images dir - to have all summaries together
    pptFileName = createReportBasedOnPlots(dirImageComplete, titNameComplete);
    %copyfile(pptFileName,dirResults);
    close all;
end

%% Plots - WAKE
titName = [pName, ' WakeEMU'];
dirImages = [dirResults, filesep, 'imagesWakeEMU'];

for iStimNSP=1:length(EEGStimTrialMATfileWakeEMU)
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeEMU{iStimNSP}, channInfo, [dirImages,filesep,'EEG0Mean'], titName, 'EEG0Mean'); % Not Normlaized
%    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWake{iStimNSP}, channInfo, [dirImages,filesep,'EEG'], titName, 'EEG'); % Normalized
 %   [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeEMU{iStimNSP}, channInfo, [dirImages,filesep,'perTrial'], titName, 'perTrial'); % Normalized
 %   [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeEMU{iStimNSP}, channInfo, [dirImages,filesep,'zeroMeanZNorm'], titName, 'zeroMeanZNorm'); % Normalized
    
    % Save in PPT in  main images dir - to have all summaries together
    pptFileName = createReportBasedOnPlots(dirImageComplete, titNameComplete);
    %copyfile(pptFileName,dirResults);
    close all;
end

%% Plots - SLEEP
titName = [pName, ' Sleep'];
dirImages = [dirResults, filesep, 'imagesSleep'];

for iStimNSP=1:length(EEGStimTrialMATfileSleep)
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileSleep{iStimNSP}, channInfo, [dirImages,filesep,'EEG0Mean'], titName, 'EEG0Mean'); % Not Normlaized
%    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileSleep{iStimNSP}, channInfo, [dirImages,filesep,'EEG'], titName, 'EEG'); % Normalized
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileSleep{iStimNSP}, channInfo, [dirImages,filesep,'perTrial'], titName, 'perTrial'); % Normalized
    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileSleep{iStimNSP}, channInfo, [dirImages,filesep,'zeroMeanZNorm'], titName, 'zeroMeanZNorm'); % Normalized
    
    % Save in PPT in  main images dir - to have all summaries together
    pptFileName = createReportBasedOnPlots(dirImageComplete, titNameComplete);
    % copyfile(pptFileName,dirResults);
    close all;
end




%%
diary off

