function [pairedComparisons, indCombs] = getPairs(comparisonsNames)
% return all unique combinations for a cell array 
indVals = 1:length(comparisonsNames);
indCombs = nchoosek(indVals, 2);
pairedComparisons = comparisonsNames(indCombs);
