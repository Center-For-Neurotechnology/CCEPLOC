function filteredData = remove60Hz(dataPerCh)


%% CLEAN 60Hz Noise
% Notch filter order 2 using matlab iirnotch - best compromise
Hd60 = filterNotch60_IIR;
filteredData = filtfilt(Hd60.Numerator, Hd60.Denominator, dataPerCh);

Hd120 = filterNotch120_IIR;
filteredData = filtfilt(Hd120.Numerator, Hd120.Denominator, filteredData); % filter also first harmonique

Hd180 = filterNotch180_IIR;
filteredData = filtfilt(Hd180.Numerator, Hd180.Denominator, filteredData); % filter also first harmonique

%filteredData = filtfilt(Hd.Numerator, 1, dataPerCh);
%Downsample to 200Hz
%cleanDataPerCh = downsample(cleanDataPerChOrigSamp,5);



%% OTHER tested methods
%cleanDataPerCh = sgolayfilt(noSTimDataPerCh, 1, round(hdr.Fs/60));
%   cleanDataPerCh = cleanLineNoiseWithChronux(noSTimDataPerCh, hdr.Fs);
% Keep only <45Hz
%Hd = filterLP45_IIR; %
%cleanDataPerCh = filtfilt(Hd.sosMatrix, Hd.ScaleValues, noSTimDataPerCh);

% Notch filter order 19 -> problem much wider
%    Hd = filterNotch60_IIR_19sec; %
%    cleanDataPerCh = filtfilt(Hd.sosMatrix, Hd.ScaleValues, noSTimDataPerCh);

%    Hd = filterNotchComb60_IIR; % Comb filter to remove 60, 120, 180 -
%       problem: notch is not really at 60Hz and it filters 0-5Hz

