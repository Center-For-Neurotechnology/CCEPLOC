function [EEGtoUse, indSelCh, cfgInfoPlot] = selectWhatSignalToUse(stData, whatToUse, indSelCh, cfgInfoPlot)
% Options are: 'ZNORM', 'PERTRIAL', 'ZEROMEANZNORM', 'EEG', 'EEG0MEAN'

%% CONFIG
if ~exist('indSelCh','var') || isempty(indSelCh)
    indSelCh=1:length(stData.EEGStimTrials); % Default is ALL channels
end
if ~exist('cfgInfoPlot','var')
    cfgInfoPlot=[];
end

%% Select WHAT to plot/Compute
switch upper(whatToUse)
    case 'ZNORM'
        %before:useNormalized==1
        EEGtoUse = stData.zNormEEGStim(indSelCh);
        cfgInfoPlot.ampUnits = 'Zscore (fromStart)';
        cfgInfoPlot.maxAmpVal = 5;
        cfgInfoPlot.minAmpVal = -5;
    case 'PERTRIAL'
        %before:useNormalized==1
        EEGtoUse = stData.perTrialNormEEGStim(indSelCh);
        cfgInfoPlot.ampUnits = 'Zscore (perTrial)';
        cfgInfoPlot.maxAmpVal = 10;
        cfgInfoPlot.minAmpVal = -10;
        
    case 'ZEROMEANZNORM'
        %before:useNormalized==1
        EEGtoUse = stData.zNormZeroMeanEEGStim(indSelCh); % similar to zNORM but removed per trial mean baseline (to align pre-stim interval)
        cfgInfoPlot.ampUnits = 'Zscore (fromStart)';
        cfgInfoPlot.maxAmpVal = 5;
        cfgInfoPlot.minAmpVal = -5;

    case 'EEG'
        EEGtoUse = stData.EEGStimTrials(indSelCh);
        cfgInfoPlot.ampUnits = 'uV';
        cfgInfoPlot.maxAmpVal = 200;
        cfgInfoPlot.minAmpVal = -200;
 
    case 'EEG0MEAN'
        EEGtoUse = stData.EEGStimTrials(indSelCh);
        for iCh=1:numel(EEGtoUse)
            EEGtoUse{iCh} = detrend(EEGtoUse{iCh},'linear');
        end
        cfgInfoPlot.ampUnits = 'uV';
        cfgInfoPlot.maxAmpVal = 200;
        cfgInfoPlot.minAmpVal = -200;
%          % Get General Baseline Information - ONLY makes sense for RAW EEG
%         EEGBaselinePerFile.std = stEEGStim.stdBaseline(indSelCh); % these values is from before first stim!
%         EEGBaselinePerFile.mean = stEEGStim.meanBaseline(indSelCh);

%% Filtered data - addition for HFOs project
    case 'FILTEEG'        
        EEGtoUse = stData.filtEEGStimTrials(indSelCh);
        cfgInfoPlot.ampUnits = 'uV';
        cfgInfoPlot.maxAmpVal = 10;
        cfgInfoPlot.minAmpVal = -10;
    case 'PERTRFILTEEG'
        EEGtoUse = stData.perTrialFilNormEEGStim(indSelCh);
        cfgInfoPlot.ampUnits = 'Zscore (perTrial)';
        cfgInfoPlot.maxAmpVal = 5;
        cfgInfoPlot.minAmpVal = -5;
end

if isfield(cfgInfoPlot,'tBaselineForZeroMean') % if we want to change the interval for the zero mean
    indTimeStim = find(stData.timePerTrialSec>0,1);
    indBaselineStart = max(1, round(cfgInfoPlot.tBaselineForZeroMean(1)*stData.hdr.Fs)+ indTimeStim);
    indBaselineEnd = min( -6, round(cfgInfoPlot.tBaselineForZeroMean(2)*stData.hdr.Fs))+indTimeStim;
    for iCh=1:numel(EEGtoUse)
        EEGtoUse{iCh} = EEGtoUse{iCh} - repmat(mean(EEGtoUse{iCh}(indBaselineStart:indBaselineEnd,:),1),size(EEGtoUse{iCh},1),1);
    end
end

%nChannels = numel(EEGtoUse);
