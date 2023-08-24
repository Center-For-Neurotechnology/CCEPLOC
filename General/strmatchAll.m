function [indIn1, indIn2, commonCh] = strmatchAll(chNames1, chNames2)

% Find Channels from 1 in 2
indIn2=[];
for iCh=1:length(chNames1)
    indIn2 = [indIn2, find(strcmpi(chNames1(iCh),chNames2))];
end
commonCh = chNames2(indIn2);

%Find common Ch in 1
indIn1=[];
for iCh=1:length(commonCh)
    indIn1 = [indIn1, find(strcmpi(commonCh(iCh),chNames1))];
end

%commonCh2 = chNames1(indIn1); % to double check