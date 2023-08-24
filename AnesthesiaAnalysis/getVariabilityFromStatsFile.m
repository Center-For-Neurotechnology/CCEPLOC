function [meanVarPerChPerState, medianVarPerChPerState, stimChVarPerState, pNamesVarPerState, valVariability, cfgStats] = getVariabilityFromStatsFile(fileNameVariability, varMeasure)

% Variability is saved in a stats file
% Variability was computed pooling all channels from all patients together 
% varMeasure: 'N1N2','N1','N2','Long'


stVar = load(fileNameVariability);
stateNames = stVar.cfgStats.legLabel;
nStates = length(stateNames);
cfgStats =stVar.cfgStats;

% remove '-' from stim names
stimChVarAllRecCh = cell(nStates,1);
stimChVarPerState = cell(nStates,1);
for iState=1:nStates
    switch stateNames{iState}
        case 'WakeEMU'
             stimChVarAllRecCh{iState} = regexprep(stVar.stimPatChWakeEMU,'-','');
             stimChVarPerState{iState} = unique(regexprep(stVar.stimPatChWakeEMU,'-',''));
             indWakeEMU=iState;
        case 'Sleep'
             stimChVarAllRecCh{iState} = regexprep(stVar.stimPatChSleep,'-','');
             stimChVarPerState{iState} = unique(regexprep(stVar.stimPatChSleep,'-',''));
             indSleep = iState;
        case 'WakeOR'
             stimChVarAllRecCh{iState} = regexprep(stVar.stimPatChWakeOR,'-','');
             stimChVarPerState{iState} = unique(regexprep(stVar.stimPatChWakeOR,'-',''));
             indWakeOR=iState;
        case 'Anesthesia'
             stimChVarAllRecCh{iState} = regexprep(stVar.stimPatChAnesthesia,'-','');
             stimChVarPerState{iState} = unique(regexprep(stVar.stimPatChAnesthesia,'-',''));
             indAnesthesia = iState;
    end    
end
cfgStats.indStates.WakeEMU = indWakeEMU;
cfgStats.indStates.Sleep = indSleep;
cfgStats.indStates.WakeOR = indWakeOR;
cfgStats.indStates.Anesthesia = indAnesthesia;

%% Get Patient names from stimch
% and INVERT CHANNEL NAMES - RZ: BUT THIS IS CORRECT SHOULD BE CHANGED IN RESP AND PCI INSTEAD!!!
%disp('CHANGING NAMES ORERS -THIS IS WORNG!!')
pNamesVarPerState = cell(nStates,1);
for iState=1:nStates
    [stimSiteCorrect, pNamesTemp] = strtok(stimChVarPerState{iState},'_');
    pNamesVarPerState{iState} = regexprep( pNamesTemp,'_','');
%     % TRUCHISIMO!!! REVERT NUMBERS -- REMOVE WHEN CORRECTED IN OTHERS!!
%     stimSite=cell(0,0);
%     for iCh=1:length(stimChVarPerState{iState})
%         indNumeric = regexp(stimSiteCorrect{iCh},'[0-9]');
%         stimSite{iCh} = stimSiteCorrect{iCh};
%         stimSite{iCh}(indNumeric(1:end/2)) = stimSiteCorrect{iCh}(indNumeric(end/2+1:end));
%         stimSite{iCh}(indNumeric(end/2+1:end)) = stimSiteCorrect{iCh}(indNumeric(1:end/2));
%     end
%     stimChVarPerStateNEWORDER{iState} = strcat(stimSite,pNamesTemp);
end
%stimChVarPerState = stimChVarPerStateNEWORDER;

%% reorganize variability as mean/median per chann
% Could use other measures instead of STD

valVariability = cell(nStates,1);
switch varMeasure
    case 'N1N2'
        valVariability{indWakeEMU} = stVar.meanStatsEEGWakeEMU.normVariabilityN1N2PerCh;
        valVariability{indSleep} = stVar.meanStatsEEGSleep.normVariabilityN1N2PerCh;
        valVariability{indWakeOR} = stVar.meanStatsEEGWakeOR.normVariabilityN1N2PerCh;
        valVariability{indAnesthesia} = stVar.meanStatsEEGAnesthesia.normVariabilityN1N2PerCh;
    case 'N1'
        valVariability{indWakeEMU} = stVar.meanStatsEEGWakeEMU.normVariabilityN1PerCh;
        valVariability{indSleep} = stVar.meanStatsEEGSleep.normVariabilityN1PerCh;
        valVariability{indWakeOR} = stVar.meanStatsEEGWakeOR.normVariabilityN1PerCh;
        valVariability{indAnesthesia} = stVar.meanStatsEEGAnesthesia.normVariabilityN1PerCh;
    case 'N2'
        valVariability{indWakeEMU} = stVar.meanStatsEEGWakeEMU.normVariabilityN2PerCh;
        valVariability{indSleep} = stVar.meanStatsEEGSleep.normVariabilityN2PerCh;
        valVariability{indWakeOR} = stVar.meanStatsEEGWakeOR.normVariabilityN2PerCh;
        valVariability{indAnesthesia} = stVar.meanStatsEEGAnesthesia.normVariabilityN2PerCh;
     case 'Long'
        valVariability{indWakeEMU} = stVar.meanStatsEEGWakeEMU.normVariabilityLongPerCh;
        valVariability{indSleep} = stVar.meanStatsEEGSleep.normVariabilityLongPerCh;
        valVariability{indWakeOR} = stVar.meanStatsEEGWakeOR.normVariabilityLongPerCh;
        valVariability{indAnesthesia} = stVar.meanStatsEEGAnesthesia.normVariabilityLongPerCh;
     
        
end


meanVarPerChPerState = cell(nStates,1);
medianVarPerChPerState = cell(nStates,1);
for iState=1:nStates
    nStimChannels = length(stimChVarPerState{iState});
    for iCh=1:nStimChannels
        indPerCh = find(strcmpi(stimChVarPerState{iState}(iCh), stimChVarAllRecCh{iState}));
        meanVarPerChPerState{iState}(iCh) = mean(valVariability{iState}(1,indPerCh),'omitnan');
        medianVarPerChPerState{iState}(iCh) = median(valVariability{iState}(1,indPerCh),'omitnan');
    end
end
%
%figure;
%scatter( meanStatsEEGAnesthesia.AllMeasures.rangeQ2575.N1,  meanStatsEEGAnesthesia.AllMeasures.allStd.N1)
%scatter( meanStatsEEGAnesthesia.AllMeasures.coeffVar.N1,  meanStatsEEGAnesthesia.AllMeasures.allStd.N1)

