function plotTrialByTrial(dataByTrial, tBeforeTriggerSec, tAfterTriggerSec, cLimValues, titName, imageFileName, indTrialToMark)

if isempty(dataByTrial)
    disp(['Nothing to Plot - ',titName])
    return
end

if ~exist('cLimValues','var') || isempty(cLimValues)
    cLimValues = [min(dataByTrial(:)) max(dataByTrial(:))];
end
if ~exist('titName','var')
    titName =[];
end
if ~exist('imageFileName','var')
    imageFileName =[];
end
if ~exist('indTrialToMark','var')
    indTrialToMark =[];
end

nTrials = size(dataByTrial,1);
lTime =  size(dataByTrial,2);
imagesc('XData',tBeforeTriggerSec:1/lTime:tAfterTriggerSec,'YData',1:nTrials,'CData',dataByTrial, cLimValues);
hold on;
line([0, 0], [0, nTrials], 'Color','red','LineWidth',2)
if ~isempty(indTrialToMark), line([tBeforeTriggerSec tAfterTriggerSec], [indTrialToMark, indTrialToMark], 'Color','magenta','LineWidth',2); end

colorbar
xlim([tBeforeTriggerSec, tAfterTriggerSec]);
ylim([0 nTrials])
ylabel('#Trials')
xlabel('Time')
title(titName);
%Save
if ~isempty(imageFileName)
    imageDir = fileparts(imageFileName);
    if ~exist(imageDir,'dir')
        mkdir(imageDir);
    end
    savefig(gcf, imageFileName,'compact');
    saveas(gcf, [imageFileName,'.png']);
end


