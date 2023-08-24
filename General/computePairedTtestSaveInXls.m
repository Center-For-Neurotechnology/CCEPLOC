function [pVal, summaryVal1, summaryVal2, testName] = computePairedTtestSaveInXls(data4Stats1,data4Stats2,tit,legLabel,xlsFileName,sheetName,dirImages,useParam)

if nargin<5, xlsFileName=[];end
if nargin<7, dirImages=[]; end
if ~exist('useParam','var'), useParam=0; end % default is wilcoxon
hfig=[]; % permutation test plot
pThreshold = 0.01;

if all(isnan(data4Stats1)) || all(isnan(data4Stats2)) || isempty(data4Stats1) || isempty(data4Stats2) % all nan or empty -> return
    pVal=1;
    summaryVal1 = median(data4Stats1,'omitnan');
    summaryVal2 = median(data4Stats2,'omitnan');
    testName = '';
    return;
end

switch useParam
    case 0
        %Compute ranksign Test
        [pVal, h, stats] = signrank(data4Stats1,data4Stats2,'alpha',pThreshold);
        testName = 'Wilcoxon signrank (paired nonParam)';
        summaryVal1 = median(data4Stats1,'omitnan');
        summaryVal2 = median(data4Stats2,'omitnan');
    case 1
        %use ttest
        [h, pVal,ci, stats] = ttest(data4Stats1,data4Stats2,'Alpha',pThreshold);
        testName = 'TTEST (paired)';
        summaryVal1 = mean(data4Stats1,'omitnan');
        summaryVal2 = mean(data4Stats2,'omitnan');
        stats.ci1 = ci(1);
        stats.ci2 = ci(2);
    case 2
        %use permutation test
        testName = 'Permutation test (paired)'; 
        if ~isempty(dirImages) %if empty --> don't plot
            [pVal, stats.observeddifference, stats.effectsize, hfig] = permutationTest(data4Stats1,data4Stats2, 10000,'plotresult', 1);%, 'showprogress', 250)
            title(tit)
        else
           [pVal, stats.observeddifference, stats.effectsize] = permutationTest(data4Stats1,data4Stats2, 10000); %,'plotresult', 0, 'showprogress', 250)
        end
        summaryVal1 = median(data4Stats1,'omitnan');
        summaryVal2 = median(data4Stats2,'omitnan');
        h=pVal<pThreshold;
    otherwise
        %Compute ranksign Test
        [pVal, h, stats] = signrank(data4Stats1,data4Stats2);
        testName = 'Wilcoxon signrank (paired nonParam)';
        summaryVal1 = median(data4Stats1,'omitnan');
        summaryVal2 = median(data4Stats2,'omitnan');
end

%Save in XLS
if ~isempty(xlsFileName) %if empty --> don't save
    statsFiledNames = fieldnames(stats);
    m4Save{1,1} = tit;
    m4Save{2,1} =testName;
    m4Save{3,3} = ['h=p<',num2str(pThreshold)];
    m4Save{3,4} = 'pVal';
    m4Save(4,3) = num2cell(h); m4Save(4,4) = num2cell(pVal);
    for iStats=1:length(statsFiledNames)
        m4Save{3,4+iStats} = statsFiledNames{iStats};
        m4Save(4,4+iStats) = num2cell(stats.(statsFiledNames{iStats}));
    end
    m4Save{5,1} = '**********';
    m4Save(6,2:3) = legLabel;
    m4Save{7,1} = 'mean';
    m4Save{8,1} = 'std';    
    m4Save{9,1} = 'median';
    m4Save(7,2) = num2cell(mean(data4Stats1,'omitnan'));    m4Save(7,3) = num2cell(mean(data4Stats2,'omitnan'));
    m4Save(8,2) = num2cell(std(data4Stats1,'omitnan'));     m4Save(8,3) = num2cell(std(data4Stats2,'omitnan'));
    m4Save(9,2) = num2cell(median(data4Stats1,'omitnan'));  m4Save(9,3) = num2cell(median(data4Stats2,'omitnan')); 
    m4Save{11,1} = '**********';
    m4Save{12,1} = 'All Values';
    m4Save(13,2:3) = legLabel;
    m4Save(14:13+length(data4Stats1),2) = num2cell(data4Stats1);
    m4Save(14:13+length(data4Stats2),3) = num2cell(data4Stats2);
    if ispc
        xlswrite(xlsFileName,m4Save,sheetName); % only save as xls if we are in WINDOWS!
    end
    [dirMat, fileNameOnly] = fileparts(xlsFileName);
    save([dirMat, '/',fileNameOnly,'_',sheetName,'.mat'],'m4Save');
end

%PLOT
if ~isempty(dirImages) %if empty --> don't plot
    grpLabel = [repmat(legLabel(1),1,length(data4Stats1)),repmat(legLabel(2),1,length(data4Stats2))];
    figure('Name', tit)
    boxplot([data4Stats1, data4Stats2], grpLabel)
    title([tit, ' - pVal= ',num2str(pVal)])
    ylabel(['pVal= ',num2str(pVal)])
    set(gca,'YGrid','on')
    name4Save = ['BoxPlot ',regexprep(tit,'\s','')];
    if ~exist(dirImages,'dir'), mkdir(dirImages);end
    savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
    saveas(gcf, [dirImages,filesep, name4Save,'.png']);
    saveas(gcf, [dirImages,filesep, name4Save,'.svg']);
    if ~isempty(hfig)
        name4Save = ['PermTest',regexprep(tit,'\s','')];
        savefig(hfig,[dirImages, filesep, name4Save,'.fig'],'compact');
        saveas(hfig, [dirImages,filesep, name4Save,'.png']);
        saveas(hfig, [dirImages,filesep, name4Save,'.svg']);
    end
end
    


