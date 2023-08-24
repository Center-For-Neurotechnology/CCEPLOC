function pptFileName = createReportBasedOnPlots(dirImages, titName)
% Creates PPT presentation report based on the images created on directory dirImages

import mlreportgen.ppt.*;
doctype = 'pdf';

%pdfFileName = [dirImages,filesep, titName, '.pdf'];
dirNameParts = split(dirImages,{'/','\'});
pptFileName = [dirImages,filesep, titName,'_',dirNameParts{end}];
if ~exist(dirImages,'dir'), mkdir(dirImages); end
% Create a document.
%rpt = Document(pdfFileName, doctype);
rpt = Presentation(pptFileName);
open(rpt);

%Add basic info
%tTitle = Text(titName);
%append(rpt, tTitle);

slide = add(rpt, 'Title Slide');
replace(slide, 'Title', [titName,' ' ,dirNameParts{end}]);


%Get png images and add them to the pdf
dirImagesInfo = dir(dirImages);
fileImages = {dirImagesInfo.name};
fileImages(find([dirImagesInfo.isdir])) = [];
allPNGFileNames =[];
for iFile=1:length(fileImages)
    if strcmpi(fileImages{iFile}(end-2:end),'png')==1
        %imageObj = Image([dirImages,filesep,fileImages{iFile}]);
        %imageObj.Style = {ScaleToFit};
        %txtFileName = Heading2(fileImages{iFile}(1:end-4));
        fileNameParts = split(fileImages{iFile}(1:end-4),'_');
       % titSlide = [fileNameParts{1},' ',fileNameParts{end}];
        titSlide = regexprep(fileImages{iFile}(1:end-4),'_',' ');
        slide = add(rpt, 'Title and Content');
        replace(slide, 'Title', titSlide);
        replace(slide, 'Content', Picture([dirImages,filesep,fileImages{iFile}]));
        allPNGFileNames = [allPNGFileNames; fileImages(iFile)];
     %   append(rpt, txtFileName);
     %   append(rpt, imageObj);
    end
end
if ~isempty(allPNGFileNames)
    slide = add(rpt, 'Title and Content');
    replace(slide, 'Title', 'Files summary');
    replace(slide, 'Content', Table(allPNGFileNames))
end
close(rpt);
%rptview(rpt.OutputPath);

