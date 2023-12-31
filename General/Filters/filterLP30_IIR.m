function Hd = filterLP30_IIR
%FILTERLP30_IIR Returns a discrete-time filter object.
% used for Keller's CCEP detections (Keller 2011 PNAS)

% MATLAB Code
% Generated by MATLAB(R) 9.1 and the Signal Processing Toolbox 7.3.
% Generated on: 19-Aug-2019 10:42:01

% Butterworth Lowpass filter designed using FDESIGN.LOWPASS.

% All frequency values are in Hz.
Fs = 2000;  % Sampling Frequency

Fpass = 30;          % Passband Frequency
Fstop = 35;          % Stopband Frequency
Apass = 1;           % Passband Ripple (dB)
Astop = 30;          % Stopband Attenuation (dB)
match = 'passband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

% [EOF]
