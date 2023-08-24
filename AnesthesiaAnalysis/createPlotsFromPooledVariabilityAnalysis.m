function createPlotsFromPooledVariabilityAnalysis(fileNameVariability, varMeasure)


[meanVarPerChPerState, medianVarPerChPerState, stimChVarPerStateNEWORDER, pNamesVarPerState, valVariability, cfgStats] = getVariabilityFromStatsFile(fileNameVariability, varMeasure);
stateNames = cfgStats.legLabel;
stateColors = {'b','g','m','r'};

%% Histograms of variability
for iState=1:length(stateNames)
    [counts centers] = hist(valVariability{iState},50);
    perHistCounts{iState} = counts/length(valVariability{iState});
    allCenters{iState} = centers;
end

% Plot histograms
figure; hold on;
for iState=1:length(stateNames)
    bar(allCenters{iState}, perHistCounts{iState},'histc', 'FaceColor','none','LineWidth',3,'EdgeColor',stateColors{iState})
end
legend(stateNames)
title(['Variability ',varMeasure])

