function [xlsFileNames xlsNewFileName allData] = someSheets2oneXLSSheet(xlsFileNames, xlsNewFileName, sheetNames, newSheetName)
%USAGE:
%inputs:
%   xlsFileNames= arrays of cells contaiing the name of the xls files to
%   put in 1 xls as different sheets.
warning off 
dirAppend ='Row';

if nargin<1 || isempty(xlsFileNames)
    [filename, pathname] = uigetfile('*.XLS', 'Select XLS files from All Patients with all SpreadSheets','MultiSelect','off');
    if isequal(filename, 0) || isequal(pathname, 0)
        disp('Exiting...');
        return;
    end
    if iscell(filename)
    for i=1:length(filename)
        xlsFileNames{i} = fullfile(pathname, filename{i});
        patientName{i} = strtok(filename{i},'.');
    end
    else
        xlsFileNames{1} =fullfile(pathname, filename);
    end
end
    
if nargin <2 || isempty(xlsNewFileName)
    [filename, pathname] = uiputfile('*.XLS', 'XLS to SAVE all summary of all others');
    if isequal(filename, 0) || isequal(pathname, 0)
        disp('Exiting...');
        return;
    end
    xlsNewFileName= fullfile(pathname, filename);
end

if nargin<3 ||isempty(sheetNames)
    [typeXls allSheetsXls] = xlsfinfo(xlsFileNames{1});
    [indSheet, ok] = listdlg('ListString', allSheetsXls, 'SelectionMode', 'multiple', 'Name', 'Sheet Names', 'PromptString', 'Select Sheet Name/s');
    if ok == 0
        mFileClose;
        return;
    end
    sheetNames =allSheetsXls(indSheet); %cell containing the different sheet names selected
end
if nargin<4 ||isempty(newSheetName)
    newSheetName = 'NewSpreadSheet';
end

%Read XLS files
for f=1:length(xlsFileNames)
    if exist(xlsFileNames{f},'file')
        [typeXls sheetsXls] = xlsfinfo(xlsFileNames{f});
        for s=1:length(sheetNames)
%             regExpSheetName = regexprep(lower(sheetName),{' ','-','_'},'');
%             regExpSheetsXls = regexprep(lower(sheetsXls),{' ','-','_'},'');
%            currSheetName = sheetsXls(strmatch(regExpSheetName,regExpSheetsXls));
%            [numData{f} txtData{f} allData{f,s}] = xlsread(xlsFileNamess{f},char(currSheetName{s}));
            currSheetName = sheetNames{s};
            [numData{f} txtData{f} allData{f,s}] = xlsread(xlsFileNames{f},currSheetName);
            xlswrite(xlsNewFileName,allData{f,s},currSheetName);
        end
    end
end

sizesAllData = cellfun(@size,allData,'UniformOutput',false);
for k=1:length(sizesAllData)
    size1(k) = sizesAllData{k}(1);
    size2(k) = sizesAllData{k}(2);
end
allDataTogether = cell(max(size1),max(size2));

for f=1:size(allData,1)
    indRow =1; indCol =1;
    for s=1:size(allData,2)
        if strmatch(dirAppend,'Row') %1 excelSheet below the other
            intervalRow = indRow:indRow+size(allData{f,s},1)-1;
            allDataTogether(intervalRow,1:size(allData{f,s},2)) = allData{f,s};
            indRow = max(intervalRow) + 3;
        else %1 next to the other
            intervalCol = indCol:indCol+size(allData{f,s},2)-1;
            allDataTogether(:,intervalCol) = allData{f,s};
            indCol = max(intervalCol) + 3;
        end
    end
    if f>1
        xlswrite(xlsNewFileName,allDataTogether,[newSheetName,'_',num2str(f)]);
    else
        xlswrite(xlsNewFileName,allDataTogether,newSheetName);
    end
end




