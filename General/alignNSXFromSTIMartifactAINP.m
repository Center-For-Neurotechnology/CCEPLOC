function  [indTimeSTIMPerFile, startNSXSecPerNSP, dataBipolarPerCh] = alignNSXFromSTIMartifactAINP(fileNameNSxPerNSP, alignAINPChNames, channInfo, startNSxSec, endNSxSec)
% Align 2 NSPs using any IANP input
% returns difference un sec and aligned indTimeSTIMPerFile and dataBipolarPerCh,
% Before using this function, align NSPs by Start time to have close by artifacts
%% Config
%Time 
if ~exist('startNSxSec','var'), startNSxSec= 0; end %6.2*10^5/2000;
if ~exist('endNSxSec','var'), endNSxSec= []; end %6.2*10^5/2000;

if ~isfield(channInfo,'isStimInAINP')
    channInfo.isStimInAINP=1; %Default is stim info on AINP (SYNC)
end

% Start Diary
%diary([dirResults,filesep,'log',pName,'scriptAlignNSXFromAINP.log'])
minSTIMDistance = 50; % 25ms minimum distance between pulse - to aviod several hits


%% Plot Stim
 % NSP1
selChNames1 = channInfo.stimChNumberInNSX(:,channInfo.NSPnumber==1); %[1 2 13 14 18 19 39 40];
selChNames1 = selChNames1(:)';
selChNamesInCERESTIM = channInfo.stimChNumber(1,channInfo.NSPnumber==1)'; %[1 2 13 14 18 19 39 40];
selBipolar1 = reshape(1:length(selChNames1),2,length(selChNames1)/2)'; %[1,2;3,4;5,6;7,8];
% Compare to values on TXT file to find if trial 0 correponds to first trial 
[dataBipolarPerCh{1}, chNamesBipolar{1}, dataStim, indTimeAllSTIM, dataReferentialPerCh, chNamesRefToPlot, allChNames{1}, hdr] = GetBipolarEEGFromNSX(fileNameNSxPerNSP{1}, selChNames1, selBipolar1, alignAINPChNames, startNSxSec, endNSxSec);
if channInfo.isStimInAINP ==1 % whether stim information is on AINP or we should get it from stim artifact on stim channels
    indTimeSTIM = indTimeAllSTIM{1};
else
    indTimeSTIM = unique([indTimeAllSTIM{:}]); % All instead of first to take into account when no AINp but each - Before:indTimeAllSTIM{1};
end
indSameStim = find(diff([0 indTimeSTIM])<=minSTIMDistance); % remove those that are too close (they correspond to the same stim pulse
indTimeSTIM(indSameStim)=[];
if ~isempty(indTimeSTIM) 
    figure; hold on;
    plot(dataBipolarPerCh{1})
    plot(dataStim{1},'k','LineWidth',3)
    plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'ms','LineWidth',10)
    legend(strcat(chNamesBipolar{1},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
end
indTimeSTIMPerFile{1} = indTimeSTIM;
     startTimeSamples{1} = hdr.startTimeSec*hdr.Fs;

 %% NSP2
 if numel(fileNameNSxPerNSP)>1 
     selChNames1 = channInfo.stimChNumberInNSX(:,channInfo.NSPnumber==2); %selChNames1 = [159 160]-128;
     selChNames1 = selChNames1(:)';
     selBipolar1 = reshape(1:length(selChNames1),2,length(selChNames1)/2)'; %selBipolar1 = [1,2];
     selChNamesInCERESTIM = channInfo.stimChNumber(1,channInfo.NSPnumber==2)'; %[1 2 13 14 18 19 39 40];
     [dataBipolarPerCh{2}, chNamesBipolar{2}, dataStim, indTimeAllSTIM, dataReferentialPerCh, chNamesRefToPlot, allChNames{2}, hdr] = GetBipolarEEGFromNSX(fileNameNSxPerNSP{2}, selChNames1, selBipolar1, alignAINPChNames, startNSxSec, endNSxSec);
     if channInfo.isStimInAINP ==1 % whether stim information is on AINP or we should get it from stim artifact on stim channels
         indTimeSTIM = indTimeAllSTIM{1};
     else
         indTimeSTIM = unique([indTimeAllSTIM{:}]); % All instead of first to take into account when no AINp but each - Before:indTimeAllSTIM{1};
     end
     indSameStim = find(diff([0 indTimeSTIM])<=minSTIMDistance); % remove those that are too close (they correspond to the same stim pulse
     indTimeSTIM(indSameStim)=[];
     if ~isempty(indTimeSTIM) %Should be changed to ANY!
         plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'rx','LineWidth',10) % PLOT on the PLOT of NSP1 - to compare

         figure; hold on; %Plot also on a separate plot figure 
         plot(dataBipolarPerCh{2})
         plot(dataStim{2},'b','LineWidth',3)
         plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'rx','LineWidth',10)
        % legend(strcat(chNamesBipolar{2},' (ch',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',')'))
         legend(strcat(chNamesBipolar{2},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
        % savefig(gcf,[dirImages, filesep,'stimChannels_', titName,'_' pName,'_NSP2','fig'],'compact');
     end
     indTimeSTIMPerFile{2} = indTimeSTIM;
     startTimeSamples{2} = hdr.startTimeSec*hdr.Fs;
 end
 
%% align NSPs to have the same start point based on CLOCKS 
diffSamplesNSPs= startTimeSamples{2}-startTimeSamples{1};
%% change dataBipolar and indTimeSTIMPerFile accordingly
if diffSamplesNSPs>0
    startNSXSecPerNSP{1}= diffSamplesNSPs/hdr.Fs;
    startNSXSecPerNSP{2}=0;
    dataBipolarPerCh{1} = dataBipolarPerCh{1}(diffSamplesNSPs:end, :);
    indTimeSTIMPerFile{1} = indTimeSTIMPerFile{1}-diffSamplesNSPs;
elseif diffSamplesNSPs<0
    startNSXSecPerNSP{1}= 0;
    startNSXSecPerNSP{2}= -diffSamplesNSPs/hdr.Fs;
    dataBipolarPerCh{2} = dataBipolarPerCh{2}(-diffSamplesNSPs:end, :);
    indTimeSTIMPerFile{2} = indTimeSTIMPerFile{2}+diffSamplesNSPs;
end
 
 %% Find difference in Alignment - assumes that they are closed by
 lenDiff= length(indTimeSTIMPerFile{1}) - length(indTimeSTIMPerFile{2});
 disp(['Different length by ',num2str(lenDiff),' - looking for closest stim sync to stim artifact'])
 if lenDiff>1      
     indNSPWithMore =1;
     indNSPWithLess =2;
 else
     indNSPWithMore =2;
     indNSPWithLess =1;
 end
 % if NSP1 is longer assume that AINP worked on this one and not in the other -> thus replace NSP2 indexes with the changed ones from NSP1
 for indStim =1: length(indTimeSTIMPerFile{indNSPWithLess})
     distNSPs = indTimeSTIMPerFile{indNSPWithMore} - indTimeSTIMPerFile{indNSPWithLess}(indStim);
     [~, indMin(indStim)] = min(abs(distNSPs));
     minDist(indStim) = distNSPs(indMin(indStim));
 end
 % remove outliers - assumes that it is detecting noise/IIDs instead of STIM artifacts
 indOutliers = find(isoutlier(minDist,'mean'));
 minDist(indOutliers)=[];
 indMin(indOutliers)=[];

 minDist=minDist+minDist(1); % assume the first one are OK
 
 differenceInSamples = round(median(minDist));
 stdDiffInSamples = std(minDist);
 indTimeSTIMPerFile{indNSPWithLess} = indTimeSTIMPerFile{indNSPWithMore}-differenceInSamples;

disp(['Aligning with ', num2str(differenceInSamples),' +/-', num2str(stdDiffInSamples),' using ',' AINP events (',[alignAINPChNames{:}],')'])
disp(['Removed trials with outliers: ', num2str(indOutliers)])


%% PLOTS
figure; 
plot(minDist)


    figure; hold on;
    plot(dataBipolarPerCh{1})
    legend(chNamesBipolar{1})
    plot(indTimeSTIMPerFile{1},zeros(1,length(indTimeSTIMPerFile{1})),'ms','LineWidth',10)
    title('Channels with STIM info from NSP1')
    figure; hold on;
    plot(dataBipolarPerCh{2})
    legend(strcat(chNamesBipolar{2},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
    plot(indTimeSTIMPerFile{2},zeros(1,length(indTimeSTIMPerFile{2})),'ms','LineWidth',10)
    title('Channels with STIM info from NSP2')
    xlim([indTimeSTIMPerFile{2}(1) indTimeSTIMPerFile{2}(4)]) 
% figure; hold on;
% plot(dataBipolarPerCh{1}(1:10000, :),'b')
% plot(dataBipolarPerCh{2}(1:10000, :),'r')
%%
%diary off

%% From Notes:
