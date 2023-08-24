function  [startNSXSecPerNSP, differenceInSamples,indTimeSTIMPerFile, dataBipolarPerCh, allChNames, hdr] = alignNSXFromAINP(fileNameNSxPerNSP, alignAINPChNames, channInfo)
% Align 2 NSPs using any IANP input
% returns difference un sec and aligned indTimeSTIMPerFile and dataBipolarPerCh,

%% Config
%Time 
startNSxSec= 0; %6.2*10^5/2000;
endNSxSec = [];
excludeTrials=[];
indStimToAlign = 1:20; % Consider the first 20 stim

pName = channInfo.pName;

if ~isfield(channInfo,'isStimInAINP')
    channInfo.isStimInAINP=1; %Default is stim info on AINP (SYNC)
end

% Start Diary
%diary([dirResults,filesep,'log',pName,'scriptAlignNSXFromAINP.log'])


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
indSameStim = find(diff([0 indTimeSTIM])<=10); % remove those that are too close (they correspond to the same stim pulse
indTimeSTIM(indSameStim)=[];
if ~isempty(indTimeSTIM) 
    figure; hold on;
    plot(dataBipolarPerCh{1})
    plot(dataStim{1},'k','LineWidth',3)
    plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'ms','LineWidth',10)
    legend(strcat(chNamesBipolar{1},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
end
indTimeSTIMPerFile{1} = indTimeSTIM;


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
     indSameStim = find(diff([0 indTimeSTIM])<=10); % remove those that are too close (they correspond to the same stim pulse
     indTimeSTIM(indSameStim)=[];
     if ~isempty(indTimeSTIM) %Should be changed to ANY!
      %  figure; hold on; %same figure 
       %  plot(dataBipolarPerCh{2})
       %  plot(dataStim{2},'b','LineWidth',3)
         plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'rx','LineWidth',10)
        % legend(strcat(chNamesBipolar{2},' (ch',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',')'))
         %legend(strcat(chNamesBipolar{2},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
        % savefig(gcf,[dirImages, filesep,'stimChannels_', titName,'_' pName,'_NSP2','fig'],'compact');
     end
     indTimeSTIMPerFile{2} = indTimeSTIM;
 

 end
 
 %% Find difference in Alignment
 if length(indTimeSTIMPerFile{1})~= length(indTimeSTIMPerFile{2})
     disp(['Different length - Assuming that start is the same'])
 end
minLen = min(length(indTimeSTIMPerFile{1}), length(indTimeSTIMPerFile{2}));
% asume might have an extra one (same start! might be wrong!!)
indAlign1 = indTimeSTIMPerFile{1}(1:minLen);
indAlign2 = indTimeSTIMPerFile{2}(1:minLen);
differenceInSamples = round(mean(indAlign1(indStimToAlign) - indAlign2(indStimToAlign)));
stdDiffInSamples = std(indAlign1(indStimToAlign) - indAlign2(indStimToAlign));

disp(['Aligning with ', num2str(differenceInSamples),' +/-', num2str(stdDiffInSamples),' using ', num2str(length(indStimToAlign)), ' AINP events (',[alignAINPChNames{:}],')'])


%% change dataBipolar and indTimeSTIMPerFile accordingly
if differenceInSamples>0
    startNSXSecPerNSP{1}= differenceInSamples/hdr.Fs;
    startNSXSecPerNSP{2}=0;
    dataBipolarPerCh{1} = dataBipolarPerCh{1}(differenceInSamples:end, :);
    indTimeSTIMPerFile{1} = indTimeSTIMPerFile{1}-differenceInSamples;
elseif differenceInSamples<0
    startNSXSecPerNSP{1}= 0;
    startNSXSecPerNSP{2}= -differenceInSamples/hdr.Fs;
    dataBipolarPerCh{2} = dataBipolarPerCh{2}(-differenceInSamples:end, :);
    indTimeSTIMPerFile{2} = indTimeSTIMPerFile{2}+differenceInSamples;
end

%% PLOTS
figure; hold on;
plot(indAlign1 - indAlign2)


    figure; hold on;
    %plot(dataBipolarPerCh{1})
    plot(dataStim{1}(startNSXSecPerNSP{2}*hdr.Fs+1:end),'k','LineWidth',3)
    plot(indTimeSTIMPerFile{1},zeros(1,length(indTimeSTIM)),'ms','LineWidth',10)
 %   plot(dataStim{2}(startNSXSecPerNSP{2}*hdr.Fs:end),'b','LineWidth',3)
    plot(indTimeSTIMPerFile{2}-startNSXSecPerNSP{2}*hdr.Fs,zeros(1,length(indTimeSTIM)),'rx','LineWidth',10)

% figure; hold on;
% plot(dataBipolarPerCh{1}(1:10000, :),'b')
% plot(dataBipolarPerCh{2}(1:10000, :),'r')
%%
%diary off

%% From Notes:
