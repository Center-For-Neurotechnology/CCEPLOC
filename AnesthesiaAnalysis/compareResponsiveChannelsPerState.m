function cfgStats = compareResponsiveChannelsPerState(fileNameRespChAllPatAllStates, dirResults, cfgStats)

nPatients = size(fileNameRespChAllPatAllStates,1);
nStates = size(fileNameRespChAllPatAllStates,2);

if ~isfield(cfgStats,'allStatesTitName'), cfgStats.allStatesTitName= cfgStats.allStates; end  % allStatesTitName is used to remove from titName (in order to match channels)

% Start Diary
if ~exist(dirResults,'dir'),mkdir(dirResults); end
diary([dirResults,filesep,'log','CompareRespChannelsPerRegion','.log'])

%% Get nRespChannels for all states and stim channels
[nRespPerState, perRespChPerState, stimSitesPerState, pNamesPerState, meanNRespPerState, nRespPerStatePerPat, stimSitesPerStatePerPat] = getNRespChannels(fileNameRespChAllPatAllStates);

%% Plot only those with corresponding stim channels
dirImages = [dirResults,filesep,'images'];
cfgStats.dirImages = dirImages;
cfgStats.bipolarChannels = stimSitesPerState;
cfgStats.legLabel = cfgStats.allStates;
cfgStats.ylabel = '# RespCh';
pairComps = [1,3;1,2;3,4];
plotWakeVsAnesthesiaPerCh(meanNRespPerState, nRespPerState, cfgStats.titName, cfgStats, pairComps);
% Repeat for percentage of responsive channels
cfgStats.ylabel = 'perc RespCh';
plotWakeVsAnesthesiaPerCh([], perRespChPerState, [cfgStats.titName, 'percResp'], cfgStats, pairComps);


%% Stats
for iComp=1:size(pairComps,1)
    titName = [cfgStats.titName,' ',num2str([pairComps(iComp,:)])];
    legLabel=cfgStats.legLabel(pairComps(iComp,:));
    [indIn1, indIn2, commonCh] = strmatchAll(cfgStats.bipolarChannels{pairComps(iComp,1)}, cfgStats.bipolarChannels{pairComps(iComp,2)});
    % # Resp Ch
    cfgStats.sheetName ='nRespCh';
    [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(nRespPerState{pairComps(iComp,1)}(indIn1),nRespPerState{pairComps(iComp,2)}(indIn2),titName,legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
    disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', ' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
    % percentage Resp Ch
    cfgStats.sheetName ='perResp';
    [pairedTtest, medianVal1, medianVal2] = computePairedTtestSaveInXls(perRespChPerState{pairComps(iComp,1)}(indIn1),perRespChPerState{pairComps(iComp,2)}(indIn2),[titName,'_perResp'],legLabel,cfgStats.xlsFileName,[cfgStats.sheetName,num2str([pairComps(iComp,:)])],cfgStats.dirImages,cfgStats.useParam);
    disp(['Wilcoxon: ', cfgStats.sheetName,' between ',[legLabel{:}], ' ', ' - pVal= ', num2str(pairedTtest),' median1= ', num2str(medianVal1),' median2= ', num2str(medianVal2)])
end

diary off;
