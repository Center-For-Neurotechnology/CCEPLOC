function [xlsFileNames xlsNewFileName allData] = someXLS2oneXLS(xlsFileNames, xlsNewFileName, sheetName, newSheetName)
%USAGE:
%inputs:
%   xlsFileNames= arrays of cells contaiing the name of the xls files to
%   put in 1 xls as different sheets.
warning off 

if nargin<1 || isempty(xlsFileNames)
    [filename, pathname] = uigetfile({'*.xls';'*.xlsx'}, 'Select XLS files from All Patients','MultiSelect','on');
    if isequal(filename, 0) || isequal(pathname, 0)
        disp('Exiting...');
        return;
    end
    for i=1:length(filename)
        xlsFileNames{i} = fullfile(pathname, filename{i});
        patientName{i} = strtok(filename{i},'.');
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

if nargin<3 ||isempty(sheetName)
    sheetName ='Kappa';
end
if nargin<4 ||isempty(newSheetName)
    newSheetName =[];
end

%Read XLS files
for f=1:length(xlsFileNames)
    if exist(xlsFileNames{f},'file')
        [typeXls sheetsXls] = xlsfinfo(xlsFileNames{f});
        regExpSheetName = regexprep(lower(sheetName),{' ','-','_'},'');
        regExpSheetsXls = regexprep(lower(sheetsXls),{' ','-','_'},'');
        currSheetName = sheetsXls(strmatch(regExpSheetName,regExpSheetsXls));
        for s=1:length(currSheetName)
            [numData{f} txtData{f} allData{f,s}] = xlsread(xlsFileNames{f},char(currSheetName{s}));
            xlswrite(xlsNewFileName,allData{f,s},char(currSheetName{s}));
        end
    end
end

if ~isempty(newSheetName)
    for s=1:size(allData,2)
        indRow =1;
        for f=1:size(allData,1)
            intervalRow = indRow:indRow+size(allData{f,s},1)-1;
            allDataTogether(intervalRow,:) = allData{f,s};
            indRow = max(intervalRow) + 3;
        end
        xlswrite(xlsNewFileName,allDataTogether,[newSheetName,'_',num2str(s)]);
    end
end



%Average 2nd & 3rd column 
if strmatch(sheetName,'Kappa')
    sizeData = [size(numData{1})];  
    matNumData = reshape(cell2mat(numData),sizeData(1),sizeData(2),length(numData));
    avNumData = mean(matNumData,3);
    
    allAvData =cell(size(allData{1}));
    allAvData(:,1) = allData{1}(:,1);
    kappaVal = avNumData(3,1);
    allAvData(6,1) =  {getDegreeAgree(kappaVal)}; %Get Degree of agreement for Average
    allAvData(1:length(avNumData(:,1)),2) = num2cell(avNumData(:,1));
    allAvData(1:length(avNumData(:,2)),3) = num2cell(avNumData(:,2));
    xlswrite(xlsNewFileName,allAvData,'Average');
end


%----------------------------------------------------
function degAgree = getDegreeAgree(kappaVal)
    if kappaVal<=0
        degAgree = 'POOR agreement';
    elseif kappaVal>0 && kappaVal<=0.2
        degAgree = 'SLIGHT agreement';
    elseif kappaVal>0.2 && kappaVal<=0.4
        degAgree = 'FAIR agreement';
    elseif kappaVal>0.4 && kappaVal<=0.6
        degAgree = 'MODERATE agreement';
    elseif kappaVal>0.6 && kappaVal<=0.8
        degAgree = 'SUBSTANTIAL agreement';
    elseif kappaVal>0.8 && kappaVal<=1
        degAgree = 'PERFECT agreement';
    else
        degAgree= 'ERROR';
    end


