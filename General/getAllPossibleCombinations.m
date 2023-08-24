function allPossibleValues = getAllPossibleCombinations(indValues)

% Length 1
allPossibleValues = num2cell(indValues)';
% All other lengths
for iComb=2:length(indValues)
    matComb = nchoosek(indValues,iComb);
    allPossibleValues(length(allPossibleValues) + 1 : length(allPossibleValues) + size(matComb,1)) = num2cell(matComb, 2)';
end
