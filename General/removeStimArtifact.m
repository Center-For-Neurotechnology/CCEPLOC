function [noSTimDataPerCh, dataMedianFiltered] = removeStimArtifact(dataPerCh, indTimeSTIM, FILT_ORDER, dataMedianFiltered)

%% CONFIG
% Tukey-windowed median filter (Chang et al., 2012)
if ~exist('FILT_ORDER','var'), FILT_ORDER = 38; end %19; %in Chang is 19 - and Fs=1kHz
if ~exist('dataMedianFiltered','var'), dataMedianFiltered = []; end %this is to allow a previously calculated median to be used (for the second pass of the filter)

%% REMOVE STIM artifact 
noSTimDataPerCh = dataPerCh;
nSamples = size(dataPerCh,1);
% Specify time as 1/3 before stim and 2/3 after stim as the stim artifact is after stim time
indTimeAround = -ceil(FILT_ORDER/2)-1:ceil(3/2*FILT_ORDER); %[-tBeforeToInterpolateSec*hdr.Fs: tAfterToInterpolateSec*hdr.Fs];
%1. Create Tukey window to use as weights
w = tukeywin(length(indTimeAround), 0.5);
%2. create weighting signal
%indTimeAround = -FILT_ORDER:FILT_ORDER; %[-tBeforeToInterpolateSec*hdr.Fs: tAfterToInterpolateSec*hdr.Fs];
indTimeToInterpolate=[];
weightVals = zeros(1, nSamples);
for iT=1:length(indTimeSTIM)
    indAroundThisStim = indTimeSTIM(iT) + indTimeAround+1;
    indTimeToInterpolate = [indTimeToInterpolate, indAroundThisStim]; %move 1 smaple to capture center of STIM artifact
    weightVals(indAroundThisStim) = w;
end

% 3. Apply median filter
if isempty(dataMedianFiltered)
    dataMedianFiltered  = medfilt1(dataPerCh, 2*FILT_ORDER,[],1);
end
%4. Replace 2*FILT_ORDER samples around STIM with weighted average

for iCh=1:size(dataPerCh,2)
 %   dataMedianFiltered  = medfilt1(dataPerCh(:,iCh), 3*FILT_ORDER);
    
    noSTimDataPerCh(:,iCh) = dataMedianFiltered(:,iCh) .* weightVals' + dataPerCh(:,iCh) .* (1-weightVals)';
end

    
    %OTHER METHOD (David2013)
% using cubic spline interpolation in 8ms (16 samples at 2kHZ) around STIM
%   indTimeAround = -19:19; %[-tBeforeToInterpolateSec*hdr.Fs: tAfterToInterpolateSec*hdr.Fs];
%     indTimeToInterpolate=[];
%     for iT=1:length(indTimeSTIM)
%         indTimeToInterpolate = [indTimeToInterpolate,indTimeSTIM(iT) + indTimeAround + 1]; %move 1 smaple to capture center of STIM artifact
%     end
%     indTimeClean=1:size(dataPerCh,1);
%     indTimeClean(indTimeToInterpolate)=[];
%     for iCh=1:size(dataPerCh,2)
%         noSTimDataPerCh(indTimeToInterpolate,iCh) = NaN;
%         
%         interpVals = interp1(indTimeClean, dataPerCh(indTimeClean,iCh), 1:size(dataPerCh,1),'spline','extrap');
%         noSTimDataPerCh(:,iCh) = interpVals;
%     end
%     
