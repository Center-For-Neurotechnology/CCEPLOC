function channInfo = getScalpChannels(channInfo)

if isfield(channInfo,'stimChNames')
    nStim = size(channInfo.stimChNames,2);
else
    nStim = 1;
end


channInfo.chNamesScalp = {'Fp1','F3','F7','C3','T1','T3','T5','P3','O1',...
                          'Fp2','F4','F8','C4','T2','T4','T6','P4','O2',...
                          'Fz','Cz','Pz','CII','LOC','ROC'}; % ONLY scalp electrodes to analyse separately
channInfo.recChPerStim = repmat({channInfo.chNamesScalp},1,nStim); %{[],[],[],[],[]};  

channInfo.scalpBipolarLongitudinal = [[1,3];[3,6];[6,7];[7,9];...
                                    [1,2];[2,4];[4,8];[8,9];...
                                    [10,12];[12,15];[15,16];[16,18];...
                                    [10,11];[11,13];[13,17];[17,18];...
                                    [3,5];[5,6];[12,14];[14,15];... % T1 & T2 added
                                    [3,23];[5,23];[6,23];[12,24];[14,24];[15,24];... % LOC & ROC added - check LOC/ROC location
                                    [19,20];[20,21];[21,22]];         % Middle line
channInfo.chNamesBipolarLongitudinal = channInfo.chNamesScalp(channInfo.scalpBipolarLongitudinal);

channInfo.scalpBipolarTransverse = [[1,10];...                                                % FP
                                  [23,3];[3,2];[2,11];[12,11];[11,19];[19,12];[12,24];... % Frontal - includes LOC and ROC 
                                  [5,6];[6,4];[4,20];[20,13];[13,15];[15,14];...  % Central
                                  [7,8];[8,21];[21,17];[17,16];...  % Parietal
                                  [5,14];[23,24];...                              % T1-T2 / LOC-ROC
                                  [9,18]];                                % Occipital
channInfo.chNamesBipolarTransverse = channInfo.chNamesScalp(channInfo.scalpBipolarTransverse);

channInfo.scalpBipolarLongTransv = unique([channInfo.scalpBipolarLongitudinal; channInfo.scalpBipolarTransverse],'rows');
channInfo.chNamesBipolarLongTransv = channInfo.chNamesScalp(channInfo.scalpBipolarLongTransv);

channInfo.selBipolar = repmat({channInfo.scalpBipolarLongTransv},1,nStim);                              
channInfo.useScalp = 1;                              


                                