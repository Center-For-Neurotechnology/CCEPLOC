function script_SomeXls2OneXls(dirResults, pName)


xlsNewFileName = [dirResults,filesep,'Summary_CompAnesthesiaWake_',pName,'.xls'];
allFilesInDir = dir(dirResults);


iXLSFiles=1;
xlsFileNames=cell(1,0);
for iFile=1:length(allFilesInDir)
   if  ~allFilesInDir(iFile).isdir && strcmpi(allFilesInDir(iFile).name(end-3:end),'.xls')
       xlsFileNames{iXLSFiles} = [allFilesInDir(iFile).folder,filesep,allFilesInDir(iFile).name];
       iXLSFiles=iXLSFiles+1;
   end
   
end

someXLS2oneXLS(xlsFileNames, xlsNewFileName, pName, [])


