function [meanVal, q25, q75, stdVal, stdErrorVal,medianVal,coeffVar, madVar, coeffMADVar, rmsVal, snrVal]= meanQuantiles(data, dimension,useDeTrend)

if ~exist('useDeTrend','var') ||isempty(useDeTrend)
    useDeTrend=0;
end

if useDeTrend 
    data=detrend(data,'linear');
end
% if wrong order (aka length 1 in required dimension), invert dimensions
if size(data, dimension)==1, data=data'; end

% ignore Inf
[rowIsInf, colIsInf]= find(isinf(data));
data(:,colIsInf)=[];

meanVal = mean(data,dimension,'omitnan');
q25 = quantile(data,0.25,dimension);
q75 = quantile(data,0.75,dimension);
stdVal = std(data,0,dimension,'omitnan');
stdErrorVal = stdVal / sqrt( size( data,dimension ));
medianVal = median(data,dimension,'omitnan');
coeffVar = stdVal ./ meanVal;
madVar = mad(data,1, dimension); % flag=1 means: MEDIAN absolute deviation
coeffMADVar = madVar ./ medianVal; % equivalent to CV but for median/MAD
rmsVal = rms(data, dimension);
snrVal = rmsVal./std(data(:));

