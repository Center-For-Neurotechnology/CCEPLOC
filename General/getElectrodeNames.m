function [uniqueElect, indElecPerCh, nContactsPerElectrode, electNamePerCh] = getElectrodeNames(chNames)


%% find individual electrodes
contactNumberPerCh = regexp(chNames,'[0-9]','start');
uniqueElect=cell(0,0);
electNamePerCh=cell(1,numel(chNames));
for iCh=1:numel(chNames)
    if ~isempty(contactNumberPerCh{iCh})
        electNamePerCh{iCh} = chNames{iCh}(1:contactNumberPerCh{iCh}(1)-1);
    else
        contactNumberPerCh{iCh} = 0; % there is number in channel name - it is more likely Cz-Pz or another unique channel
        electNamePerCh{iCh} = chNames{iCh};
    end
    uniqueElect = unique([uniqueElect, electNamePerCh{iCh}]);
    
end
nElectrodes= numel(uniqueElect);

%% find row for each channel - then assume consecutive contacts
indElecPerCh=cell(1,nElectrodes);
nContactsPerElectrode=[];
for iElec=1:nElectrodes
    chStartWithElectName = find(strncmpi(chNames, uniqueElect{iElec},length(uniqueElect{iElec})));
    chWithNUmberAfterElectName = find(cellfun(@min,contactNumberPerCh)==length(uniqueElect{iElec})+1); % to remove cases as RP vs RPT
    indElecPerCh{iElec} =  intersect(chStartWithElectName, chWithNUmberAfterElectName);
    nContactsPerElectrode = [nContactsPerElectrode,numel(indElecPerCh{iElec})];
end
