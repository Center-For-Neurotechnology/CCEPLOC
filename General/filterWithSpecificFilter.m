function filteredData = filterWithSpecificFilter(dataPerCh, filterType)

% Filters
HdFilter = eval(filterType);

if strcmpi(HdFilter.FilterStructure, 'Direct-Form FIR') %FIR
    filteredData = filtfilt(HdFilter.Numerator, 1, dataPerCh);
elseif strcmpi(HdFilter.FilterStructure, 'Direct-Form II, Second-Order Sections') %IIR with sosMatrix
    filteredData = filtfilt(HdFilter.sosMatrix, HdFilter.ScaleValues, dataPerCh);
elseif strcmpi(HdFilter.FilterStructure, 'Direct-Form II') %IIR
    filteredData = filtfilt(HdFilter.Numerator, HdFilter.Denominator, dataPerCh);
else
    disp('Filter not supported - returning raw signal')
    filteredData = dataPerCh;
end

