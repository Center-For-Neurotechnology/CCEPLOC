function [dataScalpMontage, chNamesScalp, channInfo] = createScalpMontage(dataPerCh, allChNames, channInfo)
% selScalpMontage = scalpBipolarLongitudinal, scalpBipolarTransverse, scalpBipolarLongTransv, Average, Referential
% We might want to add AVERAGE montage
if ~isfield(channInfo, 'selScalpMontage')
    channInfo.selScalpMontage = 'scalpBipolarLongTransv';
end
selScalpMontage = channInfo.selScalpMontage;

%% Get  montages
channInfo = getScalpChannels(channInfo);
nChannels = size(dataPerCh,2);
nSamples = size(dataPerCh,1);

if iscell(dataPerCh), dataScalpMontage = cell(0,0);
else, dataScalpMontage = zeros(size(dataPerCh,1),0);end


%% If we want bipolar -> let's see which
switch upper(selScalpMontage)
    case upper('scalpBipolarLongitudinal')
        mtgChNames = channInfo.chNamesBipolarLongitudinal;
    case upper('scalpBipolarTransverse')
        mtgChNames = channInfo.chNamesBipolarTransverse;
    case upper('scalpBipolarLongTransv')
        mtgChNames = channInfo.chNamesBipolarLongTransv;
    case upper('Referential')
        mtgChNames = [channInfo.chNamesScalp, channInfo.chNamesScalp];
    otherwise
        mtgChNames = channInfo.chNamesBipolarLongTransv;
end
channInfo.mtgChNames = mtgChNames;

%% If we want Bipolar - Let's see if data is in Referential or Bipolar - assumes that if names have '-' is bipolar
[contacts1, contacts2] = strtok(allChNames,'-');
indScalp = [] ;%zeros(1, length(allChNames));
if sum(~cellfun(@isempty, contacts2))>1 % at least 2 with '-' in name -> assume bipolar
    isBipolar = 1;
    for iCh=1:size(mtgChNames,1)
        indScalp = [indScalp, find(strcmpi(allChNames,[mtgChNames{iCh,2}, '-', mtgChNames{iCh,1}]))];
    end
else
    isBipolar =0;
end

%% if data in Bipolar - return scalp channels only
if ~strcmpi(selScalpMontage, 'Referential') && isBipolar==1
    channInfo.chNamesInMontage = allChNames(indScalp);
    channInfo.chNumberInMontage=1:length(indScalp);
    if iscell(dataPerCh)
        dataScalpMontage = dataPerCh(indScalp);
    else % asume time x channels
        dataScalpMontage = dataPerCh(:,indScalp);
    end
end

%% If montage AND data are referentia OR data and MONTAGE BIPOLAR - find scalp channels and return 
iChKeep=1;
if strcmpi(selScalpMontage, 'Referential') && isBipolar==0
    channInfo.chNamesInMontage=cell(0,0);
    channInfo.chNumberInMontage=[];
    for iCh=1:length(channInfo.chNamesScalp)
        iChFound1 = find(strcmpi(allChNames, channInfo.chNamesScalp{iCh}));
        if ~isempty(iChFound1)
            if iscell(dataPerCh)
                dataScalpMontage{iChKeep} = dataPerCh{iChFound1};
            else % asume time x channels
                dataScalpMontage(:,iChKeep) = dataPerCh(:,iChFound1);
            end
            channInfo.chNamesInMontage{iChKeep} = allChNames{iChFound1};
            channInfo.chNumberInMontage(iChKeep) = iChKeep; %
            iChKeep=iChKeep+1;
        end
    end
end

%% if data in referential - Let's create the bipolar 
if ~strcmpi(selScalpMontage, 'Referential') && isBipolar==0
    channInfo.chNamesInMontage=[];
    for iCh=1:size(mtgChNames,1)
        iChFound1 = find(strcmpi(allChNames, mtgChNames{iCh,1}));
        iChFound2 = find(strcmpi(allChNames, mtgChNames{iCh,2}));
        if ~isempty(iChFound1) && ~isempty(iChFound2)
            if iscell(dataPerCh)
                dataScalpMontage{iChKeep} = dataPerCh{iChFound2} -  dataPerCh{iChFound1};
            else % asume time x channels
                dataScalpMontage(:,iChKeep) = dataPerCh(:,iChFound2) -  dataPerCh(:,iChFound1);
            end
            channInfo.chNamesInMontage{iChKeep} = strcat(allChNames{iChFound2},'-',allChNames{iChFound1});
            indInMontage = intersect(find(strcmpi(mtgChNames(:,1), allChNames{iChFound1})), find(strcmpi(mtgChNames(:,2), allChNames{iChFound2})));
            channInfo.chNumberInMontage(iChKeep) = indInMontage(1); % could probably remove the 1
            iChKeep = iChKeep+1;
        end
    end
end

chNamesScalp = channInfo.chNamesInMontage;


                                