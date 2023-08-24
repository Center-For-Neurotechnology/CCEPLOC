function channInfo = findChannelNamesInNSX(channInfo, allChNames, fileNameNSx)

nChannels=length(channInfo.stimChNumber);
nPreFixName=2;

if isempty(allChNames) % we might want to change to the same input
    for iNSP=1:length(fileNameNSx)
        hdrNSX = openNSx(fileNameNSx{iNSP}, 'noread'); % only read header
        allChNames{iNSP} = {hdrNSX.ElectrodesInfo.Label}';
    end
end

% remove space from channel names
for iNSP=1:length(allChNames)
    for iCh=1:length(allChNames{iNSP})
        allChNames{iNSP}{iCh} = regexprep( allChNames{iNSP}{iCh},'\W','');
    end
end


% Assign NSX channel number based on bank info
if isfield(channInfo,'bankInfo') && (~isfield(channInfo,'stimChNumberInNSX') || isempty(channInfo.stimChNumberInNSX))
    channInfo.stimChNumberInNSX = zeros(size(channInfo.stimChNumber));
    indChInBankA = find(channInfo.stimChNumber(1,:)<=32);
    indChInBankB = intersect(find(channInfo.stimChNumber(1,:)>32), find(channInfo.stimChNumber(1,:)<=64));
    indChInBankC = intersect(find(channInfo.stimChNumber(1,:)>64), find(channInfo.stimChNumber(1,:)<=96));
    for iPair=1:2
    channInfo.stimChNumberInNSX(iPair,:) = [channInfo.bankInfo.bankA(channInfo.stimChNumber(iPair,indChInBankA) + 0),...
                                   channInfo.bankInfo.bankB(channInfo.stimChNumber(iPair,indChInBankB) - 32),...
                                   channInfo.bankInfo.bankC(channInfo.stimChNumber(iPair,indChInBankC) - 64)];
    end
    channInfo.NSPnumber = [ repmat(channInfo.bankInfo.bankANSP,1,length(indChInBankA)),...
                            repmat(channInfo.bankInfo.bankBNSP,1,length(indChInBankB)),...
                            repmat(channInfo.bankInfo.bankCNSP,1,length(indChInBankC))];
end

if ~isfield(channInfo,'stimChNames') || isempty(channInfo.stimChNames)
    channInfo.stimChNames=[];
    for iCh=1:nChannels
        stimChNumbers = channInfo.stimChNumberInNSX(:,iCh);
        indNSP = channInfo.NSPnumber(iCh);
        channInfo.stimChNames = [channInfo.stimChNames, allChNames{indNSP}(stimChNumbers)];
    end
end

if ~isfield(channInfo,'recBipolarChPerStim')|| isempty(channInfo.recBipolarChPerStim)
    for iCh=1:nChannels
        stimChNumbers = channInfo.stimChNumberInNSX(:,iCh);
        indNSP = channInfo.NSPnumber(iCh);
        channInfo.recBipolarChPerStim{iCh} = cell(1,2);
        if stimChNumbers(1)>2
            channInfo.recBipolarChPerStim{iCh}{1} = strcat(allChNames{indNSP}{stimChNumbers(1)-1},'-',allChNames{indNSP}{stimChNumbers(1)-2});
        end
        channInfo.recBipolarChPerStim{iCh}{2} = strcat(allChNames{indNSP}{stimChNumbers(2)+2},'-',allChNames{indNSP}{stimChNumbers(2)+1});
        if ~strncmp(channInfo.recBipolarChPerStim{iCh}{2},channInfo.stimChNames{1,iCh}(1:nPreFixName),nPreFixName)
            channInfo.recBipolarChPerStim{iCh}(2) = [];
        end
        if ~strncmp(channInfo.recBipolarChPerStim{iCh}{1},channInfo.stimChNames{1,iCh}(1:nPreFixName),nPreFixName)
            channInfo.recBipolarChPerStim{iCh}(1) = [];
        end
    end
end

% assign other channInfo based on number of channels
if ~isfield(channInfo,'recChPerStim')
    channInfo.recChPerStim = cell(1,nChannels);
end
if ~isfield(channInfo,'selBipolar')
    channInfo.selBipolar = cell(1,nChannels);  
end

