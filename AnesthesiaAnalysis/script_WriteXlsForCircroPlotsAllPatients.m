function script_WriteXlsForCircroPlotsAllPatients(dirGral, pNames, timeAnalysis,whatToUse,posFixDir)
% Write xls files that will be used in circro plots

if ~exist('pNames','var'), pNames = {'pXX'}; end
if ~exist('timeAnalysis','var'), timeAnalysis = [0 600]; end % in ms 10 150
if ~exist('whatToUse','var'), whatToUse = 'PERTRIAL'; end %'EEG0MEAN';%'ZEROMEANZNORM'; %;
if ~exist('posFixDir','var'), posFixDir = []; end % both for data dir and for results dir

allStates = {'WakeEMU', 'Sleep', 'WakeOR','Anesthesia'}; % USe  Anesthesia because is part of the filename! it's the way to load it!!
allStatesTitName = {'WakeEMU', 'Sleep', 'WakeOR','Anest'}; % USe Anest instead of Anesthesia because we are using this to remove from title and compare channels!! - poor hack!

posFixTimeAnalysisForTitle = [num2str(timeAnalysis(1)),'-',num2str(timeAnalysis(2))];
posFixTimeAnalysisForFile = [num2str(timeAnalysis(1)/1000),'_',num2str(timeAnalysis(2)/1000)];

titNameForFile = ['respCh',posFixTimeAnalysisForTitle,'_'];

dirCircroPlotsXls = [dirGral, filesep,'circroPlots',filesep,whatToUse, posFixDir,date];

maxValues.maxP2PAmp = 10; % assign to STIM channel - to enforce same scale in all plots 
maxValues.maxLatency = timeAnalysis(2)/1000; % assign to STIM channel - to enforce same scale in all plots

%% Organize files and run prepareRespChDataForCircroPlots
pairComp =[1,2;3,4]; %common between WakeEMU-Sleep(1-2),WakeEMU-OR(1-3),Sleep-Anest(2-3),WakeOR-Anest(3-4)
nPatients = numel(pNames);
allRespChFilesPerState=cell(1,numel(allStates));
stimChPName=cell(nPatients,numel(allStates));
commonStimChPName=cell(1,numel(pairComp)); %common between WakeEMU-Sleep(1-2),WakeEMU-OR(1-3),Sleep-Anest(2-3),WakeOR-Anest(3-4)
for iP=1:nPatients
    dirData =  [dirGral, filesep, pNames{iP}, filesep, 'ResultsAnalysisAllCh',posFixDir, filesep,'ResponsiveChannelsAllStates',whatToUse];
    for iState=1:numel(allStates)
        lstResponsiveChannelMATfile = [dirData,filesep,'lstResponsiveChannel',pNames{iP},'_',allStates{iState},'_P2P2std',posFixTimeAnalysisForFile,'.mat'];
        allRespChFilesPerState{iState} = [allRespChFilesPerState{iState}, {lstResponsiveChannelMATfile}];
        stStimCh = load(lstResponsiveChannelMATfile,'stimSiteNames','channInfo');
        stimChPName{iP,iState} = strcat(stStimCh.stimSiteNames,'_',stStimCh.channInfo.pName);
    end
    for iComp=1:size(pairComp,1)
        [ind1, ind2, commonStimChPNamePerPat] = strmatchAll(stimChPName{iP,pairComp(iComp,1)},stimChPName{iP,pairComp(iComp,2)});
        commonStimChPName{pairComp(iComp,1)} = [commonStimChPName{pairComp(iComp,1)};commonStimChPNamePerPat];
        commonStimChPName{pairComp(iComp,2)} = [commonStimChPName{pairComp(iComp,2)};commonStimChPNamePerPat];
    end
end

%% Run per patient
dirDataXls = [dirCircroPlotsXls,filesep,num2str(numel(pNames)),'pat', filesep,'xlsFiles'];
parfor iP=1:nPatients
    dirData =  [dirGral, filesep, pNames{iP}, filesep, 'ResultsAnalysisAllCh',posFixDir, filesep,'ResponsiveChannelsAllStates',whatToUse]; 
    for iState=1:numel(allStates)
        lstResponsiveChannelMATfile = [dirData,filesep,'lstResponsiveChannel',pNames{iP},'_',allStates{iState},'_P2P2std',posFixTimeAnalysisForFile,'.mat'];
         [dirCircroPlotsXlsPerPatient] = prepareRespChDataForCircroPlots(lstResponsiveChannelMATfile, dirDataXls, titNameForFile, maxValues);
         disp(['Saved xls files in dir:', dirCircroPlotsXlsPerPatient])
    end
end

%% Run again to create Pooled plots usigng COMMON STIM channels ONLY
parfor iState=1:numel(allStates)
    dirDataXls = [dirCircroPlotsXls,filesep,num2str(numel(pNames)),'pat', filesep,'xlsFiles',filesep,allStates{iState}];
    [dirCircroPlotsXlsPerState] = preparePerRegionDataForCircroPlots(allRespChFilesPerState{iState}, dirDataXls, ['Pooled',titNameForFile,allStates{iState}], maxValues, commonStimChPName{iState});
    disp(['Saved xls files in dir:', dirCircroPlotsXlsPerState])
end


% %% Run again to create Pooled plots using ALL STIM channels per state
% for iState=1:numel(allStates)
%     [dirCircroPlotsXlsPerState] = preparePerRegionDataForCircroPlots(allRespChFilesPerState{iState}, [dirCircroPlotsXls,filesep,num2str(numel(pNames)),'pat', filesep,'xlsFiles',filesep,allStates{iState}], ['Pooled',titNameForFile,allStates{iState}], maxValues);
%     disp(['Saved xls files in dir:', dirCircroPlotsXlsPerState])
% end



