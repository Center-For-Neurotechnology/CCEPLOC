function [dataPerAllCh, chNamesAll] = createIEEGMontage(useBipolar, dataReferentialPerCh, allChNamesReferential)

if useBipolar
    % Creates Bipolar data as consecutive channels - Assumes electrodes are
    % labeled as NAMExx
    nChannels = size(dataReferentialPerCh,2);
    nSamples = size(dataReferentialPerCh,1);
    dataBipolarPerCh =zeros(nSamples, 0);
    chNamesAll = cell(0,0);
    for iBipCh=1:nChannels-1
        % keep only within SHAFT - ONLY iEEG
        contacts{1} = allChNamesReferential{iBipCh+1};
        contacts{2} = allChNamesReferential{iBipCh};
        indContactName = regexp(upper(contacts),'[A-Z]','start');
        if (length(indContactName{1})==length(indContactName{2})) && (strcmpi(contacts{1}(indContactName{1}),contacts{2}(indContactName{2}))) % To ONLY consider Bipolar channels within shaft
            dataBipolarPerCh =[dataBipolarPerCh, dataReferentialPerCh(:,iBipCh+1) - dataReferentialPerCh(:,iBipCh)]; % BIPOLAR channel is CH2-CH1
            chNamesAll = [chNamesAll, strcat(contacts{1},'-', contacts{2})];
        end
    end
    dataPerAllCh = dataBipolarPerCh;
else
    % Keep referential
    dataPerAllCh = dataReferentialPerCh;
    chNamesAll = allChNamesReferential;
end



