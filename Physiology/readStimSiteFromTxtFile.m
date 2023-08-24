function [stimSites, nTrias] = readStimSiteFromTxtFile(fileNameStimSites)
%Reads file generate drng stimulation that ontains sites of stimulation
% Ech row contains: stimNumber electrode1 eletrode2

stimSites=cell(1,3);
nTrias=0;
fid = fopen(fileNameStimSites);
if fid<0
    disp(['Error opening file ',fileNameStimSites])
    return;
end

chRow = textscan(fid,'%d %d %d');
while ~isempty(chRow{1}) 
    for iCol=1:3
        stimSites{1,iCol} = cat(1,stimSites{1,iCol}, chRow{:,iCol});
    end
    chRow = textscan(fid,'%d %d %d');
end
fclose(fid);

stimSites = [stimSites{:}]; %reorganize into single cell

