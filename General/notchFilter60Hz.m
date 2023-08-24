function Hd = notchFilter60Hz
%NOTCHFILTER60HZ Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.1 and the DSP System Toolbox 9.3.
% Generated on: 12-Aug-2019 10:32:59

% IIR Notching filter designed using the IIRNOTCH function.

% All frequency values are in Hz.
Fs = 2000;  % Sampling Frequency

Fnotch = 60;  % Notch Frequency
BW     = 2;   % Bandwidth
Apass  = 1;   % Bandwidth Attenuation

[b, a] = iirnotch(Fnotch/(Fs/2), BW/(Fs/2), Apass);
Hd     = dfilt.df2(b, a);

% [EOF]