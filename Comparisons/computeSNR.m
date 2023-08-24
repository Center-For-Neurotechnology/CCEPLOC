function [snrVal] = computeSNR(perTrialNormEEGStim, cfgInfoPeaks)
% tBaselineBeforeStimPerTrialSec = [0.1 0.6];
% tSignalForSNRSec = [0.01 0.1];


% load data
indTimeSamples = cfgInfoPeaks.tSamples.CCEP; % time (Samples) to compute N1 peak amplitude
indBaseline = cfgInfoPeaks.tSamples.Baseline; % time (Samples) to compute baseline variation amplitude/variability if no general baseline is provided

% indBaselinePerTrial = intersect(find(timePerTrialSec <= -tBaselineBeforeStimPerTrialSec(1)),find(timePerTrialSec >= -tBaselineBeforeStimPerTrialSec(2)));
% indSignalSNRPerTrial = intersect(find(timePerTrialSec >= tSignalForSNRSec(1)),find(timePerTrialSec <= tSignalForSNRSec(2)));

nChannels = length(perTrialNormEEGStim);
snrVal = zeros(1,nChannels);
for iCh=1:nChannels
    meanSignal = mean(perTrialNormEEGStim{iCh},2);
    snrVal(iCh)= var(meanSignal(indTimeSamples)) / var(meanSignal(indBaseline));
end




