function [gralRegionPerCh, stChannelPerRegion, labelPerRegion] = getGralRegionPerChannel(anatomicalRegionPerCh)

% Regional grouping
labelPerRegion.MTL = {'Amyg','Ent','HC'};
labelPerRegion.latTemp = {'Temp',  'Fusi'}; %inferiortemporal transversetemporal middletemporal superiortemporal
labelPerRegion.insula = {'Insu'};
labelPerRegion.ACC = {'rACC', 'cACC', };
labelPerRegion.dlPFC = {'dlPFC'};
labelPerRegion.dmPFC = {'dmPFC'};
labelPerRegion.vlPFC = {'vlPFC'};
labelPerRegion.PFC = {'dlPFC', 'dmPFC', 'vlPFC'};
labelPerRegion.mOF = {'mOFC'};
labelPerRegion.lOF = {'lOFC'};
labelPerRegion.OF = {'mOFC','lOFC'};
labelPerRegion.subcortical = {'Accum', 'Putam'};
labelPerRegion.thalCaud = {'Caud', 'Thal'};
labelPerRegion.parietal = {'SupMar','preC', 'Cun', 'Pari'};
labelPerRegion.occipital = {'Ling', 'Occ','Calcar'};
labelPerRegion.PCC = {'isCC', 'pCC'};
labelPerRegion.central = { 'Cent'};
labelPerRegion.WM = {'unkwn'};


% Lobular/general divisions
labelPerRegion.cingulate = [labelPerRegion.ACC, labelPerRegion.PCC];
labelPerRegion.frontal = [labelPerRegion.PFC, labelPerRegion.OF];
labelPerRegion.tempoinsula = [labelPerRegion.MTL, labelPerRegion.latTemp, labelPerRegion.insula];
labelPerRegion.subcorMTL = [labelPerRegion.MTL, labelPerRegion.thalCaud, labelPerRegion.subcortical]; % called subcortical by Paulk GM/WM paper 2022

labelPerRegion.anterior = [labelPerRegion.ACC, labelPerRegion.PFC, labelPerRegion.OF];
labelPerRegion.posterior = [labelPerRegion.PCC, labelPerRegion.parietal, labelPerRegion.occipital];
labelPerRegion.temporal = [labelPerRegion.MTL, labelPerRegion.latTemp];

labelPerRegion.posTemp = [labelPerRegion.tempoinsula, labelPerRegion.posterior]; % parietal, occipital, and Temporal lobes
labelPerRegion.frontCentral = [labelPerRegion.frontal, labelPerRegion.central]; % 
labelPerRegion.antCentral = [labelPerRegion.anterior, labelPerRegion.central]; % 
labelPerRegion.posCentral = [labelPerRegion.central, labelPerRegion.posterior]; % parietal, central lobes - called pariaetal in Paulk WM/GM paper
labelPerRegion.allButAnt = [labelPerRegion.tempoinsula, labelPerRegion.central, labelPerRegion.posterior, ...
                            labelPerRegion.WM, labelPerRegion.thalCaud, labelPerRegion.subcortical]; % Everything but Anterior

labelPerRegion.all = [labelPerRegion.allButAnt, labelPerRegion.anterior];

posLabelPerRegionNames = fieldnames(labelPerRegion);

%% find general region per anatomical region
gralRegionPerCh = cell(1,length(anatomicalRegionPerCh));
c = cell(length(posLabelPerRegionNames),1);
stChannelPerRegion = cell2struct(c, posLabelPerRegionNames);
for iCh=1:length(anatomicalRegionPerCh)
    gralRegionNames=[];
    for iRegion=1:length(posLabelPerRegionNames)
        isChInRegion = any(strcmpi(anatomicalRegionPerCh{iCh}, labelPerRegion.(posLabelPerRegionNames{iRegion})));
        if isChInRegion
            gralRegionNames = [gralRegionNames, posLabelPerRegionNames(iRegion)];
            stChannelPerRegion.(posLabelPerRegionNames{iRegion}){iCh} = 1;
        else
            stChannelPerRegion.(posLabelPerRegionNames{iRegion}){iCh} = 0;
        end
    end
    gralRegionPerCh{iCh} = gralRegionNames;
end

