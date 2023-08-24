function saveFigToExt(h, imagesDir, imagesFileName,specifiedExt)
%USAGE: saveFigToExt(gcf, imagesDir, imagesFileName)

if nargin<4, specifiedExt=[]; end
    
if ~exist(imagesDir,'dir')
    mkdir(imagesDir)
end
imagesFileName = regexprep(imagesFileName,{'/s','#','/'},'');
if isempty(specifiedExt)
    saveas (h,fullfile(imagesDir,[imagesFileName,'.fig']))
    saveas (h,fullfile(imagesDir,[imagesFileName,'.png']))
    saveas (h,fullfile(imagesDir,[imagesFileName,'.eps']), 'psc2')
else
    if strmatch('eps',specifiedExt,'exact'), saveas (h,fullfile(imagesDir,[imagesFileName,'.epsc']), 'psc2');
    else saveas (h,fullfile(imagesDir,[imagesFileName,'.',specifiedExt])); end
end
    
