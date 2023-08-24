function script_CombineAtlasRASAllPatients (dirGral, pNames, strDate, posFixDir)
% read RAS location from morph file and save in local file with all
% patients together
%
% Useful to then plot values of measures for all patient s in common brain.
% Should be updated if morphing method changes (e.g. from MMVT to MNI)

% strDate is the date as it apppears in directory and xls files

nPatients = length(pNames);

dirGralResults = [dirGral,filesep,'AnesthesiaAnalysis',filesep,num2str(nPatients),'pat_',strDate,filesep,posFixDir];
dirPlots = [dirGralResults,filesep,'plotsLOCpaper_Neuron2023'];
fileNameOuput = [dirPlots, filesep, 'atlasColin27_Neuron2023','_AllRAS_',num2str(length(pNames)),'.mat'];

pNameGeneric = 'pIDXXXXX';
fileMappingGenericCSV = [dirGral, filesep,pNameGeneric,filesep,'colin27',filesep,'electrodes_positions_from_',pNameGeneric,'.csv']; %colin27 RAS coordinates from MMVT,'_bipolar had errors
fileMappingGenericCSV2 = [dirGral, filesep,pNameGeneric,filesep,'colin27',filesep,'DKT_electrodes_positions_from_',pNameGeneric,'.csv']; %colin27 RAS coordinates from MMVT_bipolar
% using referential because error in bipolar CSVs

%% read each patient's location and channel names and save together
allChNames = cell(0,0);
allContactNames = cell(0,2);
allPatientNames = cell(0,0);
allRAS = zeros(0,3);
for iP=1:nPatients
    pName=pNames{iP};
    if isfile(regexprep(fileMappingGenericCSV,pNameGeneric,pName))
        tableRASColin27 =readtable(regexprep(fileMappingGenericCSV,pNameGeneric,pName));
    else
        tableRASColin27 =readtable(regexprep(fileMappingGenericCSV2,pNameGeneric,pName));
    end
    pNameChNames = table2cell(tableRASColin27(:,1)); % first column is patient - channel name
    splitPNameChName = split(pNameChNames,'_');
    allContactNames = [allContactNames; splitPNameChName(:,2)];
    allChNames = [allChNames; splitPNameChName(:,2)];
    allPatientNames = [allPatientNames; splitPNameChName(:,1)];
    RAScoordX = table2cell(tableRASColin27(:,2)); % x,Y,Z follow
    RAScoordY = table2cell(tableRASColin27(:,3)); % x,Y,Z follow
    RAScoordZ = table2cell(tableRASColin27(:,4)); % x,Y,Z follow
    RAScoord = cell2mat([RAScoordX,RAScoordY,RAScoordZ]);
    allRAS = [allRAS; RAScoord];
        
end
alChNamesPNames = strcat(allChNames,'_',allPatientNames);

%% save in new single file for all patients
save(fileNameOuput, 'fileMappingGenericCSV','pNames','pNameGeneric','allChNames','allContactNames','allPatientNames','alChNamesPNames','allRAS');



