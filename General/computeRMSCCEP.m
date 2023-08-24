function [rmsCCEP ] = computeRMSCCEP(dataIn, indTimeTrial, indTimeBaseline)

if ~exist('indTimeBaseline','var'), indTimeBaseline=[]; end
       
nTrials = size(dataIn,2);

% Computes RMS value of each trial of the data between indexes
rmsCCEP = rms(dataIn(indTimeTrial(1):indTimeTrial(2),:), 2);


% Computes RMS value of the baseline
if ~isempty(indTimeBaseline)
    rmsBaseline = rms(dataIn(indTimeBaseline(1):indTimeBaseline(2),:), 2);
    medianRMSBaseline = median(rmsBaseline, 1); % per trial
else
   medianRMSBaseline =  ones(1, nTrials);
end

% Compute ratio per trial
ratioRMSperTrial = rmsCCEP ./ repmat(medianRMSBaseline,
