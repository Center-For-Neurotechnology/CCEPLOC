function changeStrInFileName(dirName, origStr, newStr)
% Recursively replace a string for another in all files of a directory.
% useful to remove dates from filenames
% Example:
%

allFiles = dir(dirName);
origFileNames = {allFiles.name};
isDirAllFiles = {allFiles.isdir};
for iFile =1:length(allFiles)
    origFileName =origFileNames{iFile};
    origFileNameFull = [dirName,filesep,origFileName];
    indStrInFileName = strfind(origFileName,origStr);
    if isDirAllFiles{iFile} && ~strncmp(origFileName,'.',1)  && ~strncmp(origFileName,'..',2)
     %   disp(['Entering ',origFileNameFull])
        changeStrInFileName(origFileNameFull, origStr, newStr);
    end
   if ~isempty(indStrInFileName)
        newFileName = strrep(origFileName, origStr, newStr);
        newFileNameFull = [dirName,filesep,newFileName];
        movefile(origFileNameFull,newFileNameFull)
        disp([origFileName, 'changed to ',newFileName])
   end
    
end