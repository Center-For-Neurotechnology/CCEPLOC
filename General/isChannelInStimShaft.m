function [recChInStimShaft, uniqueElectStim] = isChannelInStimShaft(recChNames, stimChNames)

% Find electrode names for recording channels
[uniqueElect, indElecPerCh, nContactsPerElectrode, electNamePerCh] = getElectrodeNames(recChNames);
% Find electrode name for stim channels
[uniqueElectStim, indElecStimPerCh, nContactsPerStimElectrode, electNamePerStimCh] = getElectrodeNames(stimChNames);
% Indicate if channel is within the STIM SHAFT

% indicate if electrode is within a stim shaft (shaft or electrode are interchangable)
recChInStimShaft = zeros(1, numel(recChNames));
for iUnStimElect=1:numel(uniqueElectStim)
    indInStimElec = find(strcmpi(electNamePerCh, uniqueElectStim{iUnStimElect}));
    recChInStimShaft(indInStimElec) = iUnStimElect;
end


