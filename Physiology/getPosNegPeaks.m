function [infoFirstPeak, infoAllPeaks, infoLargestPeak] = getPosNegPeaks(data, indTimeStart,indTimeEnd, cfgInfoPeaks )
% find positive and negative peaks and re-organize in time
if ~isfield(cfgInfoPeaks,'minPeakDistance'),cfgInfoPeaks.minPeakDistance=0;end
if ~isfield(cfgInfoPeaks,'minPeakProminence'),cfgInfoPeaks.minPeakProminence=0;end
if ~isfield(cfgInfoPeaks,'minPeakWidth'),cfgInfoPeaks.minPeakWidth=0;end
if ~isfield(cfgInfoPeaks,'maxPeakWidth'),cfgInfoPeaks.maxPeakWidth=inf;end % RIZ added to detected IIDs as they tend to be sharp
if ~isfield(cfgInfoPeaks,'extraSamplesForPeakDet'),cfgInfoPeaks.extraSamplesForPeakDet = 0;end

nEvents = size(data,2);

infoFirstPeak=struct('peakAmp',[],'peakLoc',[],'peakWidth',[],'peakProm',[],'peakToPeakAmp',[],'p2P2PAmp',[],'peakIntegral',[],'iEv',[]);
infoAllPeaks{1}=struct('peakAmp',[],'peakLoc',[],'peakWidth',[],'peakProm',[],'peakToPeakAmp',[],'p2P2PAmp',[],'peakIntegral',[],'iEv',[]);
infoLargestPeak=struct('peakAmp',[],'peakLoc',[],'peakWidth',[],'peakProm',[],'peakToPeakAmp',[],'idLargestPeak',[],...
                       'idLargestPeakToPeak',[],'p2P2PAmp',[],'peakMaxMinAmp',[],'peakIntegral',[],'peakToPeakIntegral',[],'peakToPeakToPeakIntegral',[],'iEv',[]);

indTimeStartWExtra = max(1,indTimeStart - cfgInfoPeaks.extraSamplesForPeakDet(1)); % extra time for detection - it is removed afterwards
indTimeEndWExtra = min(length(data), indTimeEnd + cfgInfoPeaks.extraSamplesForPeakDet(end));
iEvPos=0;
for iEv=1:nEvents
    [posPeaksAmp,posLocs,wPos,pPos] = findpeaks(data(indTimeStartWExtra:indTimeEndWExtra,iEv),'MinPeakDistance',cfgInfoPeaks.minPeakDistance,'MinPeakProminence',cfgInfoPeaks.minPeakProminence,...
        'MinPeakWidth',cfgInfoPeaks.minPeakWidth,'MaxPeakWidth',cfgInfoPeaks.maxPeakWidth,'Annotate','extents');
    [negPeaksAmp,negLocs,wNeg,pNeg] = findpeaks(-1 * data(indTimeStartWExtra:indTimeEndWExtra,iEv),'MinPeakDistance',cfgInfoPeaks.minPeakDistance,'MinPeakProminence',cfgInfoPeaks.minPeakProminence,...
        'MinPeakWidth',cfgInfoPeaks.minPeakWidth,'MaxPeakWidth',cfgInfoPeaks.maxPeakWidth,'Annotate','extents');
    
    % Order by location
    [allPeaksLocs, idx2] = sort([posLocs; negLocs]);
    allPeaksLocs=allPeaksLocs+indTimeStartWExtra; % with respect to start of data
    allPeaksAmp = [posPeaksAmp; -1*negPeaksAmp];
    allPeaksAmp = allPeaksAmp(idx2);
    allPeaksWidth = [wPos; wNeg];
    allPeaksWidth = allPeaksWidth(idx2);
    allPeaksProm = [pPos; pNeg];
    allPeaksProm = allPeaksProm(idx2);
    isPeakPos = [ones(length(posLocs),1); -ones(length(negLocs),1)]; %indicate if oeak is peak or through
    isPeakPos = isPeakPos(idx2);
    
    %     % only keep peaks within indTimeStart:indTimeEnd
    indKeepPeaks = find(allPeaksLocs >= indTimeStart & allPeaksLocs <= indTimeEnd);
    allPeaksLocs = allPeaksLocs(indKeepPeaks);
    allPeaksAmp = allPeaksAmp(indKeepPeaks);
    allPeaksWidth = allPeaksWidth(indKeepPeaks);
    allPeaksProm = allPeaksProm(indKeepPeaks);
    isPeakPos = isPeakPos(indKeepPeaks);
    
    % remove consecutive peaks of same sign (keep peak-through combinations only)
    indLocalPeaks = find(diff(isPeakPos)==0);
    indLocalPeakToRemove=[];
    for iPeak=1:length(indLocalPeaks)
        indToTest = indLocalPeaks(iPeak):indLocalPeaks(iPeak)+1;
        [minLocalVal, idxMin] = min(abs(allPeaksProm(indToTest))); % remove the one with lowest prominence
        indLocalPeakToRemove(iPeak) = indToTest(idxMin);
    end
    allPeaksAmp(indLocalPeakToRemove)=[];
    allPeaksLocs(indLocalPeakToRemove)=[];
    allPeaksWidth(indLocalPeakToRemove)=[];
    allPeaksProm(indLocalPeakToRemove)=[];
    
    %  get largest amplitude peak and index
    if isempty(allPeaksAmp),allPeaksAmp=0; end % for completitude
    [largestPeakVal, idLargestPeak] = max(abs(allPeaksAmp));

    % Compute also the intergral (prominence*Width)
    if isempty(allPeaksLocs),allPeaksLocs=0; end % for completitude
    if isempty(allPeaksProm),allPeaksProm=0; end % for completitude
    if isempty(allPeaksWidth),allPeaksWidth=0; end % for completitude
    allPeaksIntegral = allPeaksWidth .* allPeaksProm;
    
    %peak to peak amplitude: ABSOLUTE amplitude from MAX to MIN peak
    % (otherwise we might be caught in local fluctuations)
    allPeakToPeakAmp = diff(allPeaksAmp); % consecutive peaks
    if isempty(allPeakToPeakAmp),allPeakToPeakAmp=allPeaksAmp; end % If NO second peak - use only peak amplitude as p2p
    [peakToPeakAmp, indMaxPeakToPeak] =  max(abs(allPeakToPeakAmp)); % largest P2P amplitude of 1 peak - Before it was in the whole period: 
    if length(allPeaksAmp)>1
        peakMaxMinAmp =  abs(max(allPeaksAmp) - min(allPeaksAmp)); % from largest to smallest (most likely negative largest) peak
    else
        peakMaxMinAmp = largestPeakVal; % if only 1 peak -> keep its value
    end
    peakToPeakIntegral= sum(allPeaksIntegral(indMaxPeakToPeak:min(length(allPeaksIntegral), indMaxPeakToPeak+1)));

    
    % Get also peak 2 peak 2 peak amplitude - to consider W shape events
    allP2P2PAmp = diff(allPeakToPeakAmp); % consecutive peaks
    if isempty(allP2P2PAmp),allP2P2PAmp=allPeakToPeakAmp; end % If NO Additional peaks - use only p2p amplitude as p2p2p
    [p2P2PAmp, indMaxP2P2P] =  max(abs(allP2P2PAmp)); % largest P2P amplitude of 1 peak - Before it was in the whole period: abs(max(allPeaksAmp) - min(allPeaksAmp)); % from largest to smallest (most likely negative largest) peak
    peakToPeakToPeakIntegral= sum(allPeaksIntegral(indMaxP2P2P:min(length(allPeaksIntegral), indMaxP2P2P+2)));

    if ~isempty(allPeaksAmp)
        iEvPos= iEvPos+1;
        infoFirstPeak(iEvPos).peakLoc=allPeaksLocs(1);
        infoFirstPeak(iEvPos).peakAmp=allPeaksAmp(1);
        infoFirstPeak(iEvPos).peakWidth=allPeaksWidth(1);
        infoFirstPeak(iEvPos).peakProm=allPeaksProm(1);
        infoFirstPeak(iEvPos).peakToPeakAmp=allPeakToPeakAmp(1);
        infoFirstPeak(iEvPos).peakIntegral=allPeaksIntegral(1);
        infoFirstPeak(iEvPos).iEv = iEv;
        
        infoAllPeaks{iEvPos}.peakLoc=allPeaksLocs;
        infoAllPeaks{iEvPos}.peakAmp=allPeaksAmp;
        infoAllPeaks{iEvPos}.peakWidth=allPeaksWidth;
        infoAllPeaks{iEvPos}.peakProm=allPeaksProm;
        infoAllPeaks{iEvPos}.peakToPeakAmp = allPeakToPeakAmp; 
        infoAllPeaks{iEvPos}.p2P2PAmp = allP2P2PAmp; 
        infoAllPeaks{iEvPos}.peakIntegral = allPeaksIntegral; 
        infoAllPeaks{iEvPos}.nPeaks = length(allPeaksAmp); 
        infoAllPeaks{iEvPos}.iEv = iEv;
        
        infoLargestPeak(iEvPos).peakLoc=allPeaksLocs(idLargestPeak);
        infoLargestPeak(iEvPos).peakAmp=allPeaksAmp(idLargestPeak);
        infoLargestPeak(iEvPos).peakWidth=allPeaksWidth(idLargestPeak);
        infoLargestPeak(iEvPos).peakProm=allPeaksProm(idLargestPeak);
        infoLargestPeak(iEvPos).idLargestPeak =idLargestPeak;
        infoLargestPeak(iEvPos).idLargestPeakToPeak =[indMaxPeakToPeak indMaxPeakToPeak+1];
        infoLargestPeak(iEvPos).peakToPeakAmp=peakToPeakAmp;
        infoLargestPeak(iEvPos).p2P2PAmp=p2P2PAmp;
        infoLargestPeak(iEvPos).peakMaxMinAmp = peakMaxMinAmp;
        infoLargestPeak(iEvPos).peakIntegral=allPeaksIntegral(idLargestPeak);
        infoLargestPeak(iEvPos).peakToPeakIntegral=peakToPeakIntegral;
        infoLargestPeak(iEvPos).peakToPeakToPeakIntegral= peakToPeakToPeakIntegral;
        infoLargestPeak(iEvPos).iEv = iEv;
            
    end
end

