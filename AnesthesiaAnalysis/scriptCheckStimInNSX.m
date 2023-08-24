function  [fileNameStimSitesWNSXinfo, dataBipolarPerCh, chNamesBipolar, indTimeSTIMPerFile,  allChNames,hdr,cellWithStimInfo] = scriptCheckStimInNSX(fileNameNSxPerNSP, fileNameStimSites, dirResults, stimAINPChNames, channInfo, titName, startNSxSec, endNSxSec)

%% Config
fileNameStimSitesWNSXinfo=[];

%Time 
if ~exist('startNSxSec','var') || isempty(startNSxSec)
    startNSxSec= 0; %6.2*10^5/2000;
end
if ~exist('endNSxSec','var')
    endNSxSec = [];
end
excludeTrials=[];

dirImages = [dirResults, filesep, 'images'];
if ~exist(dirImages,'dir'), mkdir(dirImages); end

pName = channInfo.pName;

if ~exist('titName','var') || isempty(titName)
    titName = 'NetWorkQuick';
end
if ~isfield(channInfo,'isStimInAINP')
    channInfo.isStimInAINP=1; %Default is stim info on AINP (SYNC)
end
if ~isfield(channInfo,'NSPnumber')
    channInfo.NSPnumber=1; %Default is NSP1 if not specified
end
if ~isfield(channInfo,'stimChNumberInNSX') && isfield(channInfo,'stimChNumber')
    channInfo.stimChNumberInNSX= channInfo.stimChNumber(:); 
end

% Start Diary
diary([dirResults,filesep,'log',pName,'scriptCheckStimInNSX.log'])

minSTIMDistance = 50; % 25ms minimum distance between pulse - to aviod several hits

%% Plot Stim
%allChNames=cell(1,0);
if sum(channInfo.NSPnumber==1)>0
    % NSP1
    selChNames1 = channInfo.stimChNumberInNSX(:,channInfo.NSPnumber==1); %[1 2 13 14 18 19 39 40];
    selChNames1 = selChNames1(:)';
    selChNamesInCERESTIM = channInfo.stimChNumber(1,channInfo.NSPnumber==1)'; %[1 2 13 14 18 19 39 40];
    selBipolar1 = reshape(1:length(selChNames1),2,length(selChNames1)/2)'; %[1,2;3,4;5,6;7,8];
    % Compare to values on TXT file to find if trial 0 correponds to first trial
    [dataBipolarPerCh{1}, chNamesBipolar{1}, dataStim, indTimeAllSTIM, dataReferentialPerCh, chNamesRefToPlot, allChNames{1}, hdr] = GetBipolarEEGFromNSX(fileNameNSxPerNSP{1}, selChNames1, selBipolar1, stimAINPChNames, startNSxSec, endNSxSec);
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
        plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'ms','LineWidth',20)
        legend(strcat(chNamesBipolar{1},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
        try
            savefig(gcf,[dirImages, filesep,'stimChannels_', titName,'_' pName,'_NSP1'],'compact');
        catch
            disp(['Could not save fig file ',   [dirImages, filesep,'stimChannels_', titName,'_' pName,'_NSP1']]);
        end
    end
    indTimeSTIMPerFile{1} = indTimeSTIM;
    
    %% Check alignment beween TXT files and NSX (when STIM actually ocurred!)
    nStim = length(indTimeSTIM);
    [stimSitesFromLog] = readFileWithSTIMsitesPerTrial(fileNameStimSites);
    if isempty(stimSitesFromLog) %if NO file Return empty and then ->USE ALL STIM
        stimSitesFromLog = zeros(length(indTimeSTIM),3);
        stimSitesFromLog(:,1) = 0:length(indTimeSTIM)-1;
        stimSitesFromLog(:,2) = find(strncmpi(allChNames{1},stimAINPChNames{1},length(stimAINPChNames{1})));
        stimSitesFromLog(:,3) = stimSitesFromLog(:,2) +1; % Assumes consecutive!!
    end
    nStimFromTXT = size(stimSitesFromLog,1);
    
    disp(['Number of OR TXT file Stim: ', num2str(nStimFromTXT),' Number of Stim from NSX (NSP1): ',num2str(nStim)])
    if nStimFromTXT > nStim %&& ~strncmpi(stimAINPChNames,allChNames{stimChNumber1},length(stimAINPChNames))
        % Assumption is that Cerestim was disconnected before Auditory/Stim program finished 
        disp(['Analyzing only first ', num2str(nStim), ' Stims recorded on TXT file'])
    end
end
 %% NSP2
 if numel(fileNameNSxPerNSP)>1 && sum(channInfo.NSPnumber==2)>0
     selChNames1 = channInfo.stimChNumberInNSX(:,channInfo.NSPnumber==2); %selChNames1 = [159 160]-128;
     selChNames1 = selChNames1(:)';
     selBipolar1 = reshape(1:length(selChNames1),2,length(selChNames1)/2)'; %selBipolar1 = [1,2];
     selChNamesInCERESTIM = channInfo.stimChNumber(1,channInfo.NSPnumber==2)'; %[1 2 13 14 18 19 39 40];
     [dataBipolarPerCh{2}, chNamesBipolar{2}, dataStim, indTimeAllSTIM, dataReferentialPerCh, chNamesRefToPlot, allChNames{2}, hdr] = GetBipolarEEGFromNSX(fileNameNSxPerNSP{2}, selChNames1, selBipolar1, stimAINPChNames, startNSxSec, endNSxSec);
     if channInfo.isStimInAINP ==1 % whether stim information is on AINP or we should get it from stim artifact on stim channels
         indTimeSTIM = indTimeAllSTIM{1};
     else
         indTimeSTIM = unique([indTimeAllSTIM{:}]); % All instead of first to take into account when no AINp but each - Before:indTimeAllSTIM{1};
     end
     indSameStim = find(diff([0 indTimeSTIM])<=minSTIMDistance); % remove those that are too close (they correspond to the same stim pulse
     indTimeSTIM(indSameStim)=[];
     if ~isempty(indTimeSTIM) %Should be changed to ANY!
         figure; hold on;
         plot(dataBipolarPerCh{2})
         plot(dataStim{1},'k','LineWidth',3)
         plot(indTimeSTIM,zeros(1,length(indTimeSTIM)),'ms','LineWidth',20)
         % legend(strcat(chNamesBipolar{2},' (ch',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',')'))
         legend(strcat(chNamesBipolar{2},' (chNSX ',cellfun(@num2str,num2cell(selChNames1(selBipolar1(:,1))),'UniformOutput',0)',' / chCER',cellfun(@num2str,num2cell(selChNamesInCERESTIM),'UniformOutput',0),')'))
         try
             savefig(gcf,[dirImages, filesep,'stimChannels_', titName,'_' pName,'_NSP2'],'compact');
         catch
             disp(['Could not save fig file ',   [dirImages, filesep,'stimChannels_', titName,'_' pName,'_NSP2']]);
         end
     end
     indTimeSTIMPerFile{2} = indTimeSTIM;
     
     
     %% Check alignment beween TXT files and NSX (when STIM actually ocurred!)
    nStim = length(indTimeSTIM);
    [stimSitesFromLog] = readFileWithSTIMsitesPerTrial(fileNameStimSites);
    if isempty(stimSitesFromLog) %if NO file Return empty and then ->USE ALL STIM
        stimSitesFromLog = zeros(length(indTimeSTIM),3);
        stimSitesFromLog(:,1) = 0:length(indTimeSTIM)-1;
        stimSitesFromLog(:,2) = find(strncmpi(allChNames{2},stimAINPChNames{1},length(stimAINPChNames{1})));
        stimSitesFromLog(:,3) = stimSitesFromLog(:,2) +1; % Assumes consecutive!!
    end
    nStimFromTXT = size(stimSitesFromLog,1);

    disp([' Number of OR TXT file Stim: ', num2str(nStimFromTXT),' Number of Stim from NSX (NSP2): ',num2str(nStim)])
    if nStimFromTXT > nStim %&& ~strncmpi(stimAINPChNames,allChNames{stimChNumber1},length(stimAINPChNames))
        % Assumption is that Cerestim was disconnected before Auditory/Stim program finished 
        disp(['Analyzing only first ', num2str(nStim), ' Stims recorded on TXT file'])
    end
 end

 %% add information regarding NSX ch number and NSP number to stimSitesFromLog variable
 if ~isempty(fileNameStimSites)
     [stimSitesFromLog, stWithStimInfo, cellWithStimInfo,headerInfo] = addNSXChannelInfoToStimLog(stimSitesFromLog, allChNames, channInfo.bankInfo);
     [origPath, onlyFileName] = fileparts(fileNameStimSites);
     fileNameStimSitesWNSXinfo = [dirResults, filesep, onlyFileName,'_wNSXinfo.mat'];
     save(fileNameStimSitesWNSXinfo, 'stWithStimInfo','cellWithStimInfo','stimSitesFromLog','headerInfo')
 end
 
%%
diary off

%% From Notes:
