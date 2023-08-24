function scriptPlotStimEvokedScalpEEG(fileNameMATfiles, dirResults, channInfo)

%% Get Files to PLOT
pName = channInfo.pName;

[FilteredScalpEEGStimTrialMATfile, FilteredEEGStimTrialMATfile, channInfo] = getFilteredScalpFilesFromAllFile(fileNameMATfiles, [], []);

%Dirs
if ~exist(dirResults,'dir'), mkdir(dirResults); end

% Start Diary
diary([dirResults,filesep,'log',pName,'ScriptAnesthesiaAnalysis_FilteredPlots.log'])

% what to Plot
whatToPlot =  'perTrial'; %,'EEG0Mean','zeroMeanZNorm'};
whatToPlotFiltered = 'PERTRFILTEEG'; %,'EEG0Mean','zeroMeanZNorm'};

whichStates = {'WakeEMU','Sleep'};

%% Plots - Scalp
for iState=1:length(whichStates)
    thisState = whichStates{iState};
    titName = [pName, ' ', thisState,' Scalp'];
    dirImages = [dirResults, filesep, 'images',filesep, thisState];
    for iStimNSP=1:length(FilteredScalpEEGStimTrialMATfile.(thisState))
        FilteredEEGStimTrialMATfile = FilteredScalpEEGStimTrialMATfile.(thisState){iStimNSP};
        % Only plot selected STIM channels (usually SOZ)
        stStimSiteNamesInFile = load(FilteredEEGStimTrialMATfile, 'stimSiteNames');        % Find WHICH stimulation channel is the one in this file
        if sum(strcmpi(stStimSiteNamesInFile.stimSiteNames{1}, channInfo.stimChNames(1,:)))>0 % Should have option for ALL Stim channels?
           % [dirImageComplete, titNameComplete] = plotScalpFilteredData(FilteredEEGStimTrialMATfile, channInfo, [dirImages,filesep,whatToPlotFiltered], titName, whatToPlotFiltered);

            plotStimEvokedScalpEEG(FilteredEEGStimTrialMATfile, channInfo, thisState);
            % Save in PPT in  main images dir - to have all summaries together
  %          pptFileName = createReportBasedOnPlots(dirImageComplete, titNameComplete);
            % copyfile(pptFileName,dirResults);
            close all;
            
        end
    end
end

% %    [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeOR{iStimNSP}, channInfo, [dirImages,filesep,'EEG'], titName, 'EEG'); % Normalized
%     [dirImageComplete, titNameComplete] = plotAnesthesiaData(EEGStimTrialMATfileWakeOR{iStimNSP}, channInfo, [dirImages,filesep,'perTrial'], titName, 'perTrial'); % Normalized


%%
diary off

