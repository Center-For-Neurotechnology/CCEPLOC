function [infoFirstPeak, infoAllPeaks, infoLargestPeak] = getPeaksAsMaxAmplitude(data, indTimeStart,indTimeEnd, cfgInfoPeaks )
% find positive and negative peaks and re-organize in time
if ~isfield(cfgInfoPeaks,'minPeakDistance'),cfgInfoPeaks.minPeakDistance=0;end
if ~isfield(cfgInfoPeaks,'minPeakProminence'),cfgInfoPeaks.minPeakProminence=0;end
if ~isfield(cfgInfoPeaks,'minPeakWidth'),cfgInfoPeaks.minPeakWidth=0;end

nEvents = size(data,2);

infoFirstPeak=struct('peakAmp',[],'peakLoc',[],'peakWidth',[],'peakProm',[],'peakToPeakAmp',[],'iEv',[]);
infoAllPeaks{1}=struct('peakAmp',[],'peakLoc',[],'peakWidth',[],'peakProm',[],'peakToPeakAmp',[],'iEv',[]);
infoLargestPeak=struct('peakAmp',[],'peakLoc',[],'peakWidth',[],'peakProm',[],'peakToPeakAmp',[],'iEv',[],'idLargestPeak',[]);

iEvPos=0;
for iEv=1:nEvents
    [posPeaksAmp, posLocs] = max(data(indTimeStart:indTimeEnd,iEv));
    [negPeaksAmp, negLocs] = min(data(indTimeStart:indTimeEnd,iEv));
    
    
   % [posPeaksAmp,posLocs,wPos,pPos] = findpeaks(data(indTimeStart:indTimeEnd,iEv),'MinPeakDistance',cfgInfoPeaks.minPeakDistance,'MinPeakProminence',cfgInfoPeaks.minPeakProminence,'MinPeakWidth',cfgInfoPeaks.minPeakWidth,'Annotate','extents');
   % [negPeaksAmp,negLocs,wNeg,pNeg] = findpeaks(-1 * data(indTimeStart:indTimeEnd,iEv),'MinPeakDistance',cfgInfoPeaks.minPeakDistance,'MinPeakProminence',cfgInfoPeaks.minPeakProminence,'MinPeakWidth',cfgInfoPeaks.minPeakWidth,'Annotate','extents');

    % Order by location
    [allPeaksLocs, idx2] = sort([posLocs; negLocs]);
    allPeaksLocs=allPeaksLocs+indTimeStart; % with respect to start of data
    allPeaksAmp = [posPeaksAmp; negPeaksAmp];
    allPeaksAmp = allPeaksAmp(idx2);
  %  allPeaksWidth = [wPos; wNeg];
  %  allPeaksWidth = allPeaksWidth(idx2);
  %  allPeaksProm = [pPos; pNeg];
  %  allPeaksProm = allPeaksProm(idx2);
    
    %peak to peak to peak amplitude 
    % presumably N1-P1 / P1-N2
%     peakToPeakAmp = diff(allPeaksAmp); % original
%     if isempty(peakToPeakAmp),peakToPeakAmp=0; end % for completitude
% peak to peak amplitude: ABSOLUTE amplitude from MAX to MIN peak
    % (otherwise we might be caught in local fluctuations)
    allPeakToPeakAmp = diff(allPeaksAmp); % consecutive peaks
    peakToPeakAmp =  abs(max(allPeaksAmp) - min(allPeaksAmp)); % from largest to smallest (most likely negative largest) peak
    if isempty(peakToPeakAmp),peakToPeakAmp=0; end % for completitude
    if isempty(allPeakToPeakAmp),allPeakToPeakAmp=0; end % for completitude

    % Also get largest amplitude peak
    [maxVal, idLargestPeak] = max(abs(allPeaksAmp));
    
    if ~isempty(allPeaksAmp)
        iEvPos= iEvPos+1;
        infoFirstPeak(iEvPos).peakLoc=allPeaksLocs(1);
        infoFirstPeak(iEvPos).peakAmp=allPeaksAmp(1);
       % infoFirstPeak(iEvPos).peakWidth=allPeaksWidth(1);
       % infoFirstPeak(iEvPos).peakProm=allPeaksProm(1);
        infoFirstPeak(iEvPos).peakToPeakAmp=allPeakToPeakAmp(1);
        infoFirstPeak(iEvPos).iEv = iEv;
        
        infoAllPeaks{iEvPos}.peakLoc=allPeaksLocs;
        infoAllPeaks{iEvPos}.peakAmp=allPeaksAmp;
     %   infoAllPeaks{iEvPos}.peakWidth=allPeaksWidth;
     %   infoAllPeaks{iEvPos}.peakProm=allPeaksProm;
        infoAllPeaks{iEvPos}.peakToPeakAmp = allPeakToPeakAmp; 
        infoAllPeaks{iEvPos}.nPeaks = length(allPeaksAmp); 
        infoAllPeaks{iEvPos}.iEv = iEv;
        
        infoLargestPeak(iEvPos).peakLoc=allPeaksLocs(idLargestPeak);
        infoLargestPeak(iEvPos).peakAmp=allPeaksAmp(idLargestPeak);
    %    infoLargestPeak(iEvPos).peakWidth=allPeaksWidth(idLargestPeak);
    %    infoLargestPeak(iEvPos).peakProm=allPeaksProm(idLargestPeak);
        infoLargestPeak(iEvPos).idLargestPeak =idLargestPeak;
        infoLargestPeak(iEvPos).peakToPeakAmp=peakToPeakAmp;
        infoLargestPeak(iEvPos).iEv = iEv;

    end
end

