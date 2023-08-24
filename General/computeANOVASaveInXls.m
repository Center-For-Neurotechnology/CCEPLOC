function [pVal] = computeANOVASaveInXls(data4Stats,groupLabels,tit, xlsFileName,sheetName,imagesDir,allDataLabels)

if nargin<3,    tit=[]; end
if nargin<4,    xlsFileName=[]; end
if nargin<5,    sheetName=[]; end
if nargin<6,    imagesDir=[]; end
if nargin<7,    allDataLabels=[]; end

% Ignore Inf and ignore NaN
indIsInf = find(isinf(data4Stats));% remove Inf values
indIsNaN = find(isnan(data4Stats));% remove NaN values
indToExclude = [indIsInf,indIsNaN];
data4Stats(indToExclude)=[];     
groupLabels(indToExclude)=[];
if ~isempty(allDataLabels),allDataLabels(indToExclude)=[]; end

figure;
%Compute KS Test
[pVal table statsVals] = anova1(data4Stats,groupLabels,'off');
testName = 'anova1';

%Multiple Comparison
[cMult,mMedian,h,nameStats] = multcompare(statsVals);
%Contains zero the CI?
isSignif = sign([cMult(:,3)]./ [cMult(:,5)])>=0;

if ~isempty(imagesDir) %if empty --> don't save
    tit2 = ['MultComp ',tit];
    title(tit2)
    set(gca,'YGrid','on')
    titNameForFile = regexprep(tit2,{'/s','/','/'},'');
saveas(gcf,[imagesDir, filesep,titNameForFile,'.png']);
savefig(gcf,[imagesDir, filesep,titNameForFile,'.fig'],'compact');
end


groupNames = nameStats; % DO NOT use UNIQUE - it changes the order -  unique(groupLabels);
nGroups = length(groupNames);
for iGr=1:nGroups
    indGroupEv = strmatch(groupNames{iGr},groupLabels);
    nEvPerGroup(iGr) = length(indGroupEv);
    if length(groupLabels)<length(data4Stats) %matrix format
        muData(iGr) = mean(data4Stats(:,indGroupEv));
        stdData(iGr) = std(data4Stats(:,indGroupEv));
        medianData(iGr) = median(data4Stats(:,indGroupEv));
    else                                    %vector format -- groupName is a vector of size data4stats
        muData(iGr) = mean(data4Stats(indGroupEv));
        stdData(iGr) = std(data4Stats(indGroupEv));
        medianData(iGr) = median(data4Stats(indGroupEv));
    end
end

%Save in XLS
if ~isempty(xlsFileName) %if empty --> don't save
    m4Save{1,1} = tit;
    m4Save{2,1} = testName;
    m4Save{3,1} = 'pVal';
    m4Save(4,1) = num2cell(pVal);

    m4Save{6,1} ='Groups:'; m4Save(6,2:1+nGroups) = groupNames; 
    m4Save{7,1} ='# Events:'; m4Save(7,2:1+nGroups) = num2cell(nEvPerGroup); 
    m4Save{8,1} ='Mean:'; m4Save(8,2:1+nGroups) = num2cell(muData); 
    m4Save{9,1} ='Std:'; m4Save(9,2:1+nGroups) =num2cell(stdData); 
    m4Save{10,1} ='Median:'; m4Save(10,2:1+nGroups) = num2cell(medianData); 

    m4Save(12:11+size(table,1),1:size(table,2)) = table;
    iRow= size(m4Save,1)+1;
    m4Save{iRow+1,1} = '*******'; m4Save{iRow+1,2} = 'Multiple Comparisons'; m4Save{iRow+1,3} = '*******';
    iRow = size(m4Save,1) +1;
    m4Save{iRow+1,1} = 'Pair';
    m4Save{iRow+1,3} = 'CIDown'; m4Save{iRow+1,4} = 'MeanDiff'; m4Save{iRow+1,5} = 'CIUp';
    m4Save{iRow+1,6} = 'IsSignif?';
    m4Save(iRow+2:1+iRow+size(cMult,1),1:size(cMult,2)) = num2cell(cMult);
    m4Save(iRow+2:1+iRow+size(isSignif,1),size(cMult,2)+1) = num2cell(isSignif);

    iRow= size(m4Save,1)+1;
    m4Save{iRow+1,1} = '*******';    m4Save{iRow+1,2} = 'All Events';    m4Save{iRow+1,3} = '*******';
    m4Save{iRow+2,1} = 'Group';     m4Save(iRow+2,2) = {tit};
%    if length(groupLabels)<length(data4Stats)
        m4Save(iRow+3:iRow+2+length(groupLabels),2) = groupLabels;        
        if ~isempty(allDataLabels), m4Save(iRow+3:iRow+2+size(data4Stats,1),1) = allDataLabels; end
        m4Save(iRow+3:iRow+2+length(data4Stats(:)),3) = num2cell(data4Stats(:));
%     else
%         m4Save(iRow+3:iRow+2+length(data4Stats),1) = groupLabels;
%         m4Save(iRow+3:iRow+2+length(data4Stats),2) = num2cell(data4Stats);
%     end
    if ispc
        xlswrite(xlsFileName,m4Save,sheetName); % only save as xls if we are in WINDOWS!
    end
    [dirMat, fileNameOnly] = fileparts(xlsFileName);
    save([dirMat, '/',fileNameOnly,'_',sheetName,'.mat'],'m4Save');
end

if ~isempty(imagesDir) %if empty --> don't save
    figure;
    if size(data4Stats,2)>size(data4Stats,1)
        %data4Stats=data4Stats';
        groupLabels=groupLabels';
    end
    boxplot(data4Stats,groupLabels);
    %tit = ['BoxPlot ',tit];
    title(tit)
    set(gca,'YGrid','on')
    titNameForFile = ['BoxPlot ', regexprep(tit,{'/s','/','/'},'')];
    %saveFig(gcf, imagesDir,titNameForFile);
saveas(gcf,[imagesDir, filesep,titNameForFile,'.png']);
savefig(gcf,[imagesDir, filesep,titNameForFile,'.fig'],'compact');
end


