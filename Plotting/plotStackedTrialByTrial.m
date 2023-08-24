function plotStackedTrialByTrial(dataByTrial, tBeforeTriggerSec, tAfterTriggerSec, cLimValues, titName, imageFileName, indTrialToMark, strYLabels)

if isempty(dataByTrial)
    disp(['Nothing to Plot - ',titName])
    return
end

if ~exist('cLimValues','var') || isempty(cLimValues)
    cLimValues = [quantile(dataByTrial(:),0.01) quantile(dataByTrial(:),0.99)];
%    cLimValues = [min(dataByTrial(:)) max(dataByTrial(:))];
end
if ~exist('titName','var'),        titName =[]; end
if ~exist('imageFileName','var'),  imageFileName =[]; end
if ~exist('indTrialToMark','var'), indTrialToMark =[]; end
if ~exist('strYLabels','var'),     strYLabels =[];end

nDistTraces = max(abs([cLimValues(:)])) * 1.1; % max([abs(dataByTrial(:))]) * 1.1;
nTrials = size(dataByTrial,1);
lTime =  size(dataByTrial,2);
hold on;
timePerTrialMiliSec = linspace(tBeforeTriggerSec, tAfterTriggerSec, lTime) * 1000; % in ms
for iTrials=1:nTrials
    if intersect(indTrialToMark,iTrials)
        plot(timePerTrialMiliSec, dataByTrial(iTrials,:)+nDistTraces*iTrials,'b') 
    else
        plot(timePerTrialMiliSec, dataByTrial(iTrials,:)+nDistTraces*iTrials,'k')
    end
end
plot(timePerTrialMiliSec, 5*mean(dataByTrial,1),'k', 'LineWidth', 2)% AVERAGE AMPLITUDE IS 5x to see BETTER
line([0, 0],[-nDistTraces nDistTraces*(nTrials+1)], 'Color','r','LineWidth',2)

if ~isempty(indTrialToMark) && length(indTrialToMark)==1, line([tBeforeTriggerSec tAfterTriggerSec], nDistTraces*[indTrialToMark, indTrialToMark], 'Color','magenta','LineWidth',2); end

xlim([tBeforeTriggerSec, tAfterTriggerSec]*1000); %in ms
ylim([-4*nDistTraces nDistTraces*(nTrials+1)])
yticks(nDistTraces*[0:nTrials])
ylabel(['#Trials (ylim=',num2str(cLimValues),')'])
xlabel('Time (ms)')
title(titName);
if ~isempty(strYLabels), yticklabels(strYLabels)
else, yticklabels([{'5xAv'},num2cell(1:nTrials)]); end
%Save
if ~isempty(imageFileName)
    imageDir = fileparts(imageFileName);
    if ~exist(imageDir,'dir')
        mkdir(imageDir);
    end
    savefig(gcf, imageFileName,'compact');
    saveas(gcf, [imageFileName,'.png']);
    saveas(gcf, [imageFileName,'.svg']);
end


