function dirCircroPlotsCommon = getCommonStimSitesSaveinXlsForCircro(dirCircroPlots, regionName, timeStr, selStates, posFixFile)

dirCircroPlotsXls = [dirCircroPlots, filesep, 'xlsFiles'];
dirCircroPlotsCommon = [dirCircroPlots, filesep,'commonSTIM'];
dirCircroPlotsXlsCommon = [dirCircroPlotsCommon, filesep, 'xlsFiles'];
if ~exist('posFixFile','var'), posFixFile = '_perLobeStimCh'; end%'_perStimCh'
if ~isdir(dirCircroPlotsXlsCommon), mkdir(dirCircroPlotsXlsCommon); end

anatRegionsStr = 'anatRegions';
%labelStrs = {'lobeRegions','gralRegions'}; 
edgeIndSTIMstr = 'indStimOnlyRespPerStim';
edgesStrs = {'indStimOnlyRespPerStim', 'ampOnlyRespCh'}; %'indStimPerStim'; %'isChResp'; %'ampOnlyRespCh_Max10_';% 'ampOnlyRespCh'; %'isChResp'; % 'ampRespCh'; %'ampRespCh'; %
maxEdgeVal = {1, 10};

%% read stim sites
nStates = length(selStates);
stimSites=cell(1,nStates);
for iState=1:nStates
    thisState = selStates{iState};
    strTitName = ['PooledrespCh',timeStr,'_',thisState,'_',regionName];
    dirCircroMAT = [dirCircroPlotsXls, filesep, thisState, filesep, 'MATFiles'];
    fileAnatRegions = [dirCircroMAT, filesep, strTitName,'_',anatRegionsStr, posFixFile,'.mat']; %chNameStr
    if ~exist(fileAnatRegions,'file')
        disp(['file ', fileAnatRegions,' does not exist - exiting!'])
        return;
    end
    stAnatRegion = load(fileAnatRegions);
    stimSites{iState} = stAnatRegion.stimSitePatNamesPerRegion;
end
    

%% Only keep info on common channels    
indCommonStimPerState = cell(1, nStates);
for iState=1:nStates-1
    [indCommonStimPerState{iState}, indCommonStimPerState{iState+1}] = strmatchAll(stimSites{iState},stimSites{iState+1});
end

% read from MATLAB and save in new XLS
indCommonMatrix=cell(1,nStates);
for iState=1:nStates
    thisState = selStates{iState};
    strTitName = ['PooledrespCh',timeStr,'_',thisState,'_',regionName];
    dirCircroMAT = [dirCircroPlotsXls, filesep, thisState, filesep, 'MATFiles'];
    fileEdges = [dirCircroMAT,filesep, strTitName,'_mEdges_',edgeIndSTIMstr, posFixFile,'.mat'];       % edgeIndSTIMstr Matrix data
    stEdge = load(fileEdges);
    indCommonStim = stEdge.indStimChPerRegion(indCommonStimPerState{iState});
    indCommonMatrix{iState} = zeros(size(stEdge.mEdges4Save));
    for iStim=1:length(indCommonStim)   % Keep matrix with common STIM
        indCommonPerStim{iState, iStim} = find(stEdge.mEdges4Save==indCommonStim(iStim));
        indCommonMatrix{iState}(indCommonPerStim{iState, iStim})=1; % geenrate a temp matrix with common matrix
    end
    
    % keep only common and save for each edge str specified
        strTitNameNew = ['Pool','_',regionName];

    for iEdge=1:length(edgesStrs)
        fileEdges = [dirCircroMAT,filesep, strTitName,'_mEdges_',edgesStrs{iEdge}, posFixFile,'.mat'];       % Matrix data
        stEdge = load(fileEdges);
        mEdges4Save = stEdge.mEdges4Save.*indCommonMatrix{iState}; % Keep only common stim data
        if ~exist([dirCircroPlotsXlsCommon, filesep, thisState],'dir'),mkdir([dirCircroPlotsXlsCommon, filesep, thisState]);end
        xlswrite([dirCircroPlotsXlsCommon, filesep, thisState, filesep, strTitNameNew,'_mEdges_',edgesStrs{iEdge}, posFixFile,'.xlsx'], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        if ~isempty(maxEdgeVal{iEdge})
            mEdges4Save(mEdges4Save>maxEdgeVal{iEdge}) = maxEdgeVal{iEdge};
            xlswrite([dirCircroPlotsXlsCommon, filesep, thisState, filesep, strTitNameNew,'_mEdges_',edgesStrs{iEdge}, '_Max',num2str(maxEdgeVal{iEdge}),'_', posFixFile, '.xlsx'], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        end
    end
end
        
        
%% save also difference for this common stim channels
for iState=1:nStates-1
    state1 = selStates{iState};
    state2 = selStates{iState+1};
    dirCircroMAT1 = [dirCircroPlotsXls, filesep, state1, filesep, 'MATFiles'];
    dirCircroMAT2 = [dirCircroPlotsXls, filesep, state2, filesep, 'MATFiles'];
    strTitNameNew = ['PoolCh','_',regionName];

    for iEdge=1:length(edgesStrs)
        fileEdges1 = [dirCircroMAT1,filesep, 'PooledrespCh',timeStr,'_',state1,'_',regionName,'_mEdges_',edgesStrs{iEdge}, posFixFile,'.mat'];       % Matrix data
        fileEdges2 = [dirCircroMAT2,filesep, 'PooledrespCh',timeStr,'_',state2,'_',regionName,'_mEdges_',edgesStrs{iEdge}, posFixFile,'.mat'];       % Matrix data
        stEdge1 = load(fileEdges1);
        stEdge2 = load(fileEdges2);
        
        mEdges1 = stEdge1.mEdges4Save.*indCommonMatrix{iState};
        mEdges2 = stEdge2.mEdges4Save.*indCommonMatrix{iState+1};
        
        indmEdges4SaveDiff1 = (mEdges1>=1) & ~(mEdges2>=1); % difference - in 1 but not in 2        
        indmEdges4SaveDiff2 = ~(mEdges1>=1) & (mEdges2>=1); % difference - in 2 but not in 1  
        indmEdges4SaveDiff = indmEdges4SaveDiff1 | indmEdges4SaveDiff2;
        indmEdges4SaveCommon = (mEdges1>=1) & (mEdges2>=1); % Common       
        
        mEdges4Save = mEdges1.*indmEdges4SaveDiff - mEdges2.*indmEdges4SaveDiff2 + 0.1*indmEdges4SaveCommon;
     %   xlswrite([dirCircroPlotsXlsCommon, filesep, state1, filesep, strTitName,'_mEdges_',edgesStrs{iEdge}, posFixFile,'_Common',state1,state2,'.xlsx'], indmEdges4SaveCommon); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        xlswrite([dirCircroPlotsXlsCommon, filesep, state1, filesep, strTitNameNew,'_mEdges_',edgesStrs{iEdge}, posFixFile,'_Diff',state1,state2,'.xlsx'], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
 
        if ~isempty(maxEdgeVal{iEdge})
            indLargerMaxVal = find(mEdges4Save>maxEdgeVal{iEdge});
            indLargerMaxValMinus = find(mEdges4Save<-maxEdgeVal{iEdge});
            mEdges4Save(indLargerMaxVal) = maxEdgeVal{iEdge};
            mEdges4Save(indLargerMaxValMinus) = -maxEdgeVal{iEdge};
            xlswrite([dirCircroPlotsXlsCommon,filesep, state1, filesep,strTitNameNew,'_mEdges_',edgesStrs{iEdge}, '_Max',num2str(maxEdgeVal{iEdge}),'_', posFixFile, '_Diff',state1,state2,'.xlsx'], mEdges4Save); % only save as xls if we are in WINDOWS! it saves as csv in MAC
        end
    end    
    
    
end

