function [stimSitesWithNSXinfo, stWithStimInfo, cellWithStimInfo, headerInfo] = addNSXChannelInfoToStimLog(stimSitesFromLog, allChNames, bankInfo)
% Add information regarding NSX channel number. cerestim bank and NSP to original log
% return  a struct to save with EEGStimTrial files
%
% New matrix is composed of: stim number |  Cerestim STIM ch 1 | Cerestim STIM ch 2 | NSP number |  NSX STIM ch 1 |  NSX STIM ch 2
% New cell is composed of: stim number |  Cerestim STIM ch 1 | Cerestim STIM ch 2 | NSP number |  NSX STIM ch 1 |  NSX STIM ch 2 | NSX STIM ch name 1 |  NSX STIM ch name 2 

headerInfo = {'trial','CerestimCh1','CerestimCh2','NSPnumber','NSXChNumber1','NSXChNumber2','NSXChName1','NSXChName2'};
    
bankACerestim = 1:32;
bankBCerestim = 33:64;
bankCCerestim = 65:96;

%if ~iscell(allChNames{1}), allChNames={allChNames}; end % cell of cells (from scriptCheckNSX)

allChNumbersWithStimFromLog = unique(stimSitesFromLog(:,2:3));
stWithStimInfo=[];
for iCh=1:length(allChNumbersWithStimFromLog)
    chNumberInCerestim = allChNumbersWithStimFromLog(iCh);
    if ~isempty(intersect(chNumberInCerestim, bankACerestim)) % BANK A
        [indInCerstim, indInBank] = intersect(bankACerestim, chNumberInCerestim);
        chNumberInNSX = bankInfo.bankA(indInBank);
        NSPnumber = bankInfo.bankANSP;
        bankValue='A';
    end
    if ~isempty(intersect(chNumberInCerestim, bankBCerestim)) % BANK B
        [indInCerstim, indInBank] = intersect(bankBCerestim, chNumberInCerestim);
        chNumberInNSX = bankInfo.bankB(indInBank);
        NSPnumber = bankInfo.bankBNSP;
        bankValue='B';
    end
    if ~isempty(intersect(chNumberInCerestim, bankCCerestim)) % BANK C
        [indInCerstim, indInBank] = intersect(bankCCerestim, chNumberInCerestim);
        chNumberInNSX = bankInfo.bankC(indInBank);
        NSPnumber = bankInfo.bankCNSP;
        bankValue='C';
    end
    stWithStimInfo(iCh).chNumberInCerestim = chNumberInCerestim;
    stWithStimInfo(iCh).chNumberInNSX = chNumberInNSX;
    stWithStimInfo(iCh).NSPnumber = NSPnumber;
    stWithStimInfo(iCh).bank = bankValue;
    stWithStimInfo(iCh).chName = allChNames{NSPnumber}(chNumberInNSX);
end
    
%% add also to original matrix
stimSitesWithNSXinfo = stimSitesFromLog;
for iStim=1:size(stimSitesFromLog,1)
    indInSt = find([stWithStimInfo.chNumberInCerestim] == stimSitesFromLog(iStim,2));
    stimSitesWithNSXinfo(iStim, 4) = stWithStimInfo(indInSt).NSPnumber;
    stimSitesWithNSXinfo(iStim, 5) = stWithStimInfo(indInSt).chNumberInNSX;
    indInSt = find([stWithStimInfo.chNumberInCerestim] == stimSitesFromLog(iStim,3));    
    stimSitesWithNSXinfo(iStim, 6) = stWithStimInfo(indInSt).chNumberInNSX;
end   

%% also create cell with all stim
cellWithStimInfo = cell(size(stimSitesFromLog,1),8);
for iStim=1:size(stimSitesFromLog,1)
    indInSt = find([stWithStimInfo.chNumberInCerestim] == stimSitesFromLog(iStim,2));
    cellWithStimInfo{iStim, 1} = stimSitesFromLog(iStim,1);
    cellWithStimInfo{iStim, 2} = stimSitesFromLog(iStim,2);
    cellWithStimInfo{iStim, 3} = stimSitesFromLog(iStim,3);
    cellWithStimInfo{iStim, 4} = stWithStimInfo(indInSt).NSPnumber;
    cellWithStimInfo{iStim, 5} = stWithStimInfo(indInSt).chNumberInNSX;
    cellWithStimInfo{iStim, 7} = stWithStimInfo(indInSt).chName;
    indInSt = find([stWithStimInfo.chNumberInCerestim] == stimSitesFromLog(iStim,3));
    cellWithStimInfo{iStim, 6} = stWithStimInfo(indInSt).chNumberInNSX;
    cellWithStimInfo{iStim, 8} = stWithStimInfo(indInSt).chName;
end   
