function [noSTimDataPerCh] = removeStimArtifactCerestim(dataPerCh, indTimeSTIM)
% Simlar to the original removeStimArtifact but since Cerestim has a
% re-bound at ~10ms 2 median filters are used. a short one at -3 to +7 samples  and another for only a few samples around 10ms. 

%% CONFIG
% Tukey-windowed median filter (Chang et al., 2012)
FILT_ORDER_SHORT = 24; %19; %in Chang is 19 but gets double around stim - and Fs=1kHz
FILT_ORDER_REBOUND = 9; %19; %in Chang is 19 - and Fs=1kHz
Fs =2000; % might want to have a variable from outside!
reboundTPts = 8/1000 * Fs; % rebound is at 10ms - start 1ms before to be around center

%% REMOVE STIM artifact 
%noSTimDataPerCh = dataPerCh;

%% STEP 1 remove the large STIM artifact 
[noSTimDataPerCh, dataMedianFiltered] = removeStimArtifact(dataPerCh, indTimeSTIM, FILT_ORDER_SHORT);

%% STEP 2 remove the rebound at 10ms - > the new filter covers this.
% in this second round use the median data from the original data
%[noSTimDataPerCh] = removeStimArtifact(noSTimDataPerCh, indTimeSTIM + reboundTPts, FILT_ORDER_REBOUND, dataMedianFiltered);

%     
