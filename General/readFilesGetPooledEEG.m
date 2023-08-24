function [EEGStimToCompare, EEGStimSameSignToCompare, EEGBaselineToCompare, selBipolarChanNames, selStimChannels, anatomicalInfo, cfgStats] = ...
            readFilesGetPooledEEG(fileNameEEGStimTrial, channInfo, cfgStats, whatToUse)


EEGStimToCompare=[];
EEGStimSameSignToCompare=[];
selBipolarChanNames=[];
selStimChannels=[];
anatomicalInfo.selBipolarAnatRegion=[];
anatomicalInfo.selStimAnatRegion=[];
anatomicalInfo.selStimRASCoord=[];
anatomicalInfo.selBipolarRASCoord=[];
anatomicalInfo.isRecChInStimShaft=[];
signRespBipolarCh=[];
EEGBaselineToCompare=struct('mean',[],'std',[]);
if isempty(fileNameEEGStimTrial)
    disp(['No File to read ', channInfo.pNames,' for this state'])
    return;
end
        
% There is 1 MAT file per stim site
for iFile =1:numel(fileNameEEGStimTrial)
    if ~isempty(fileNameEEGStimTrial{iFile})
        %indStimFile = find(~cellfun(@isempty,strfind(fileNameEEGStimTrial, channInfo.stimBipChNames{iStim})));
        stEEGStim = load(fileNameEEGStimTrial{iFile});
        stimSiteNames = stEEGStim.stimSiteNames;
        chNamesSelectedInFile = stEEGStim.chNamesSelected;
        anatRegionsPerChInFile = stEEGStim.anatRegionsPerCh;
        anatRegionsStimChInFile = stEEGStim.anatRegionsStimCh;
        RASCoordPerChInFile = stEEGStim.RASCoordPerCh;
        RASCoordPerChStimChInFile = stEEGStim.RASCoordPerChStimCh;
        Fs= stEEGStim.hdr.Fs;
        
        % Find WHICH stimulation channel is the one in this file
        indStim = find(strcmpi([stimSiteNames{2},'-',stimSiteNames{1}],channInfo.stimBipChNames));
        
        % Select specified channels if exist selChanNames = channInfo.recBipolarChPerStim{indStim};
        if ~isempty(indStim)
            selChanNames = channInfo.recBipolarChPerStim{indStim};
            selChanInStimShaft = channInfo.recBipChInStimShaft{indStim};
            iChSel=1;
            indSelCh=[];
            for iCh=1:numel(selChanNames)
                indChFound = find(strcmpi(selChanNames{iCh},chNamesSelectedInFile));
                if ~isempty(indChFound)
                    indSelCh(iChSel) = indChFound;
                    selBipolarChanNames = [selBipolarChanNames, selChanNames(iCh)];
                    selStimChannels = [selStimChannels, channInfo.stimBipChNames(indStim)];
                    % Add anatomical information
                    anatomicalInfo.selBipolarAnatRegion = [anatomicalInfo.selBipolarAnatRegion, anatRegionsPerChInFile(indChFound)];
                    anatomicalInfo.selStimAnatRegion = [anatomicalInfo.selStimAnatRegion, anatRegionsStimChInFile];
                    anatomicalInfo.selBipolarRASCoord = [anatomicalInfo.selBipolarRASCoord; RASCoordPerChInFile(indChFound,:)];
                    anatomicalInfo.selStimRASCoord = [anatomicalInfo.selStimRASCoord; RASCoordPerChStimChInFile];
                    anatomicalInfo.isRecChInStimShaft = [anatomicalInfo.isRecChInStimShaft; selChanInStimShaft(iCh)];
                    iChSel =iChSel+1;
                end
            end
            if ~isempty(indSelCh) % make sure that there are specified recording  channels for this stim Channel
                % Select WHAT to Analize
                [EEGStimPerFile, indSelCh, cfgStats] = selectWhatSignalToUse(stEEGStim, whatToUse, indSelCh, cfgStats);
                EEGStimToCompare = [EEGStimToCompare,EEGStimPerFile];
                % also baseline from file - RZ: are we using this??
                EEGBaselinePerFile.std = stEEGStim.stdBaseline(indSelCh);% these values is from before first stim!
                EEGBaselinePerFile.mean = stEEGStim.meanBaseline(indSelCh);
                EEGBaselineToCompare.mean = [EEGBaselineToCompare.mean, EEGBaselinePerFile.mean];
                EEGBaselineToCompare.std = [EEGBaselineToCompare.std, EEGBaselinePerFile.std];
                
                if isfield(channInfo,'signRespBipolarCh')
                    signRespBipolarCh = [signRespBipolarCh, [channInfo.signRespBipolarCh{indStim}]];
                else
                    signRespBipolarCh = [signRespBipolarCh; ones(numel(EEGStimPerFile),1)];
                end
            end
        else
            disp(['File ',fileNameEEGStimTrial{iFile},' not used']);
        end
    else
        disp(['File ',fileNameEEGStimTrial{iFile},' not used']);
    end
end
nChannels = numel(EEGStimToCompare);

for iCh=1:numel(EEGStimToCompare)
    EEGStimSameSignToCompare{iCh} = signRespBipolarCh(iCh)* EEGStimToCompare{iCh};
end

cfgStats.timePerTrialSec = stEEGStim.timePerTrialSec;
Fs = stEEGStim.hdr.Fs; % Assumes same sampling rate
cfgStats.Fs = Fs;
timeOfStimSamples = find(cfgStats.timePerTrialSec>=0,1); 
cfgStats.timeOfStimSamples = timeOfStimSamples;
cfgStats.pName = channInfo.pNames;


