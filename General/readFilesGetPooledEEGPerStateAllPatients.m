function [EEGStimPooled, bipChPooled, stimChPooled, stimPatChPooled,anatomicalInfoPooled, EEGBaselinePooled, cfgStats] = ...
                readFilesGetPooledEEGPerStateAllPatients(fileNamesPerStateAllPatients, stateName, channInfo, cfgStats, whatToUse)
% stateName must Be the same as trialsToExclude variable

EEGStimPooled = [];
bipChPooled = [];
stimChPooled = [];
stimPatChPooled = [];
EEGBaselinePooled=[];
anatomicalInfoPooled.bipChAnatRegionPooled=[];
anatomicalInfoPooled.stimChAnatRegionPooled=[];
anatomicalInfoPooled.bipChRASCoordPooled=[];
anatomicalInfoPooled.stimChRASCoordPooled=[];
anatomicalInfoPooled.isRecChInStimShaft=[];

for iP=1:numel(channInfo)
    if ~isempty(fileNamesPerStateAllPatients{iP})
        unFileNamesPerPat = unique(fileNamesPerStateAllPatients{iP},'stable'); % if more than 1 file per state, keep only 1!!
        [EEGStimPerPat, EEGStimSameSignPerPat, EEGBaselinePerPat, selBipolarChanNames, selStimChannels, anatomicalInfo, cfgStats] = ...
                readFilesGetPooledEEG(unFileNamesPerPat, channInfo{iP}, cfgStats, whatToUse);
        if isfield(channInfo{iP}, ['trialsToExclude',stateName]) % remove trials to exclude
            trialsToExclude = channInfo{iP}.(['trialsToExclude',stateName]);
            for iCh=1:numel(trialsToExclude)
                indInChFromFile = find(strcmpi(selStimChannels,channInfo{iP}.stimBipChNames{iCh}));
                for iChEEG=1:length(indInChFromFile)
                    EEGStimSameSignPerPat{indInChFromFile(iChEEG)}(:,trialsToExclude{iCh})=[];
                end
            end
        end
        EEGStimPooled = [EEGStimPooled, EEGStimSameSignPerPat];
        EEGBaselinePooled = [EEGBaselinePooled, EEGBaselinePerPat];
      % names and anatomical info
        bipChPooled = [bipChPooled, strcat('rec',selBipolarChanNames,' st',selStimChannels,'_',channInfo{iP}.pNames)];
        stimChPooled = [stimChPooled, selStimChannels];
        stimPatChPooled = [stimPatChPooled, strcat(selStimChannels,'_',channInfo{iP}.pNames)];
        anatomicalInfoPooled.bipChAnatRegionPooled = [anatomicalInfoPooled.bipChAnatRegionPooled, anatomicalInfo.selBipolarAnatRegion];
        anatomicalInfoPooled.stimChAnatRegionPooled = [anatomicalInfoPooled.stimChAnatRegionPooled, anatomicalInfo.selStimAnatRegion];
        anatomicalInfoPooled.bipChRASCoordPooled = [anatomicalInfoPooled.bipChRASCoordPooled; anatomicalInfo.selBipolarRASCoord];
        anatomicalInfoPooled.stimChRASCoordPooled = [anatomicalInfoPooled.stimChRASCoordPooled; anatomicalInfo.selStimRASCoord];
        anatomicalInfoPooled.isRecChInStimShaft = [anatomicalInfoPooled.isRecChInStimShaft; anatomicalInfo.isRecChInStimShaft];
        disp([channInfo{iP}.pNames,' ', stateName,' ',num2str(length(EEGStimSameSignPerPat)),' rec channs - reading MAT files done!'])
    end
end

cfgStats.whatToUse = whatToUse;