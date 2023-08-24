function script_mergeEEGStimFrom2NSPsAnesthesia(fileNameAllChMATfiles,channInfo)

%% Files and Directories
[fileNamesAnesthesia, fileNamesWakeOR, fileNamesWakeEMU, fileNamesSleep] = getAnesthesiaWakeSleepFilesFromAllFile(fileNameAllChMATfiles,[],[],channInfo);

