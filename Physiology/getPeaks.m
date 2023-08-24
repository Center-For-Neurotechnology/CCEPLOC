function infoPeak = getPeaks(data, indTimeStart,indTimeEnd, cfgInfoPeaks )

nEvents = size(data,2); 

infoPeak=struct('posLocs',[],'posPeaksAmp',[],'widthPeak',[],'promPeak',[],'iEv',[]);
iEvPos=0;
for iEv=1:nEvents
    [posPeaksAmp,posLocs,wPos,pPos] = findpeaks(data(indTimeStart:indTimeEnd,iEv),'MinPeakProminence',cfgInfoPeaks.minPeakProminence,'MinPeakWidth',cfgInfoPeaks.minPeakWidth,'Annotate','extents');
    
    if ~isempty(posPeaksAmp)
        iEvPos= iEvPos+1;
        infoPeak(iEvPos).posLocs=posLocs(1);
        infoPeak(iEvPos).posPeaksAmp=posPeaksAmp(1);
        infoPeak(iEvPos).widthPeak=wPos(1);
        infoPeak(iEvPos).promPeak=pPos(1);
        infoPeak(iEvPos).iEv = iEv;
    end
end

