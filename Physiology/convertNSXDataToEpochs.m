function [EEGStimTrials, timePerTrialSec] = convertNSXDataToEpochs(dataPerCh, indTimeSTIM, tBeforeStimSec, tAfterStimSec, Fs)
 

nDataPts = size(dataPerCh, 1);
nChannels = size(dataPerCh, 2);
nStims = length(indTimeSTIM);
EEGStimTrials = cell(1,nChannels);
    
indTBeforeStim = round(-tBeforeStimSec*Fs);
indTAfterStim = round(tAfterStimSec*Fs);
timePerTrialSec = (indTBeforeStim:indTAfterStim)/Fs;
lTime = length(timePerTrialSec);

for iCh=1:nChannels
    EEGPerTrial=zeros(lTime, nStims);
    for iEv=1:nStims
        indTrial = max(indTBeforeStim+indTimeSTIM(iEv),1):min(indTAfterStim+indTimeSTIM(iEv),nDataPts);
        indInMatrix= 1:length(indTrial);
        if indTrial(1)==1, indInMatrix=indInMatrix+(lTime-length(indTrial));end % to account for events at the beginning
        EEGPerTrial(indInMatrix,iEv) = dataPerCh(indTrial, iCh);
    end
    EEGStimTrials{iCh}=EEGPerTrial;
end


% % Organize in trials around stim
% tTimeAroundStim = round([-tBeforeStimSec:1/Fs:tAfterStimSec]*Fs);
% lTrial = length(tTimeAroundStim);
% dataPerStim = zeros(lTrial, nStims, nChannels);
% for iStim=1:nStims
%     timeTrial = tTimeAroundStim + indTimeSTIM(iStim);       % since we are detection pulse ->  we get directly te sample
%     dataPerStim(:,iStim,:) = dataPerCh(timeTrial, :);
% end
% 
% 

