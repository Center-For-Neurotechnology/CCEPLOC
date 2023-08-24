function infoBaseline = computeBaselines(infoBaseline, dataPerCh, indTimeSTIM, Fs)

%% Compute Baseline as mean of 1min before the very first stim (assuming we are well before Anesthesia starts).
switch upper(infoBaseline.computeBaselineFrom)
    case 'START'
        indBaselineStart=  max(1,round(infoBaseline.tBaselineStartSec*Fs));
        indBaselineEnd= round((infoBaseline.tBaselineStartSec+ infoBaseline.tBaselineDurationSec)*Fs);        
    case 'BEFOREFIRSTSTIM'
        indBaselineStart= max(1,round(indTimeSTIM(1)-(infoBaseline.tBaselineStartSec+ infoBaseline.tBaselineDurationSec)*Fs));
        indBaselineEnd=   round(indTimeSTIM(1)- infoBaseline.tBaselineStartSec*Fs);
    otherwise
        indBaselineStart=  max(1,round(infoBaseline.tBaselineStartSec*Fs)); %default is from the begining of the file
        indBaselineEnd=  round((infoBaseline.tBaselineStartSec+ infoBaseline.tBaselineDurationSec)*Fs);
end
[meanBaseline,  q25, q75, stdBaseline] = meanQuantiles(dataPerCh(indBaselineStart:indBaselineEnd,:),1);
infoBaseline.meanBaseline=meanBaseline;
infoBaseline.stdBaseline=stdBaseline;
% infoBaseline.tBaselineSec=tBaselineStartSec;
% infoBaseline.tBaselineDurationSec=tBaselineDurationSec;
% infoBaseline.computeBaselineFrom=computeBaselineFrom;

%Trial per trial Normalization
infoBaseline.indBaselinePerTrial = max(1,round(infoBaseline.tBaselinePerTrialStartSec*Fs)):round((infoBaseline.tBaselinePerTrialStartSec+ infoBaseline.tBaselinePerTrialEndSec)*Fs);
%infoBaseline.tBaselinePerTrialStartSec = infoBaseline.tBaselinePerTrialStartSec;
%infoBaseline.tBaselinePerTrialEndSec = infoBaseline.tBaselinePerTrialEndSec;