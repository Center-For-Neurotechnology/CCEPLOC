function [medianVal, q05, q95]= medianQuantiles(data, dimension)

medianVal = median(data,dimension);
q05 = quantile(data,0.05,dimension);
q95 = quantile(data,0.95,dimension);

