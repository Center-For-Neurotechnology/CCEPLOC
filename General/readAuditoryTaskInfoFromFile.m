function [firstLossConscTrial, isAudioResponse, audioRespRT, stAudioTask] = readAuditoryTaskInfoFromFile(fileNameAudioTaskAnesthesia, indMinTrialLOC, indTimeSTIMSec)

%LOC definition
nMaxNaN = 5; %if more than 5 consecutive NaN consider as LOC
minRTtimeSec = 0.075; % minimum response time is 75ms - otherwise it is not a real response

isAudioResponse=[];firstLossConscTrial=[];audioRespRT=[];
stAudioTask=struct();lastRespTrial=[];
if ~isempty(fileNameAudioTaskAnesthesia)
    stAudioTask = load(fileNameAudioTaskAnesthesia);
    if isempty(indMinTrialLOC)
        indMinTrialLOC = floor(length([stAudioTask.Log.data.Resp]) / 3);% LOC MUST happen at least 1/3 into experiment
    end
    isAudioResponse = [stAudioTask.Log.data.Resp]; % -1 means NO response
    audioRespRT = [stAudioTask.Log.data.RT];       %NaN means NO response 
    meas = regionprops(logical(isnan(audioRespRT(indMinTrialLOC:end))),'Area'); % Find number of consecutive NaNs in response
    consecNaN = [meas.Area];
    nNaNFirstLOC = sum(consecNaN(1:find(consecNaN>nMaxNaN,1)-1))+1; % Find nMaxNaN  consecutive NaNs 
    indNaNUntilLOC = find(isnan(audioRespRT(indMinTrialLOC:end)),nNaNFirstLOC)+indMinTrialLOC-1;         % Find index in  audioRespRT of NaNs up to 
    indRepNaN = find(diff([0 indNaNUntilLOC])<=3);% join together NaN separate by only 1-2 responses
    indNaNUntilLOC(indRepNaN)=[];
    lastRespTrial = find(isAudioResponse>0,1,'last'); %find last responsive trial
    if isempty(indNaNUntilLOC), indNaNUntilLOC=length(isAudioResponse); end
    lastRealRespTrial = find(audioRespRT<minRTtimeSec); % if RT is <50ms the response cannot be real -> it is likely from just keeping the finger on the mouse
    indRepResp = find(diff([0 lastRealRespTrial])<=2);% join together NaN separate by only 1-2 responses
    lastRealRespTrial(indRepResp)=[];
    firstLossConscTrial = min([lastRespTrial+1, lastRealRespTrial(end)+1, indNaNUntilLOC(end)]);
    if firstLossConscTrial >= 0.9*length(indTimeSTIMSec) || firstLossConscTrial <= 0.1*length(indTimeSTIMSec) % for those cases when the auditory task didn't work
        firstLossConscTrial = ceil(length(indTimeSTIMSec)/2);
    end 
    indTimeLOCSec = indTimeSTIMSec(firstLossConscTrial); %/ hdr.Fs;
    disp(['LOC at STIM number: ',num2str(firstLossConscTrial),' - ',num2str(indTimeLOCSec),' sec'])
else
    if isempty(indMinTrialLOC)
        firstLossConscTrial = ceil(length(indTimeSTIMSec)/2); % assume half and half
    else
        firstLossConscTrial = indMinTrialLOC; % use as specified
    end
    indTimeLOCSec = indTimeSTIMSec(firstLossConscTrial); %/ hdr.Fs;
    disp(['LOC at STIM number: ',num2str(firstLossConscTrial),' - ',num2str(indTimeLOCSec),' sec - No Auditory File'])
end