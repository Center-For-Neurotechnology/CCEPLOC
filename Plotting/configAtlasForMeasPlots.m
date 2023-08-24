function [CategoryStr, FaceLabels, VertexLabels, CombinedRegionAccr, CategoryValues] = configAtlasForMeasPlots(atlasPlyFilesDir, regionsToCombine)

%% General Labels config
TargetLabels={'middlefrontal' % caudalmiddlefrontal rostralmiddlefrontal
    'superiorfrontal'
    'pars' %= inferior frontal 'parstriangularis'     'parsopercularis'      'parsorbitalis'    % put together as inferior frontal 
    'medialorbitofrontal'
    'lateralorbitofrontal'
    'rostralanteriorcingulate'
    'caudalanteriorcingulate'
    'isthmuscingulate'
    'posteriorcingulate'
    'amygdala'
    'entorhinal'
    'hippocamp' %    'Hippocampus'    'parahippocampal'
    'insula'
    'accumbens'
    'caudate'
    'putamen'
    'temporal' %inferiortemporal transversetemporal middletemporal superiortemporal
    'fusiform'
    'central' %paracentral postcentral precentral
    'supramarginal'
    'precuneus' % precuneus MUST be before cuneus to be considered
    'parietal' % inferiorparietal superiorparietal
    'cuneus'
    'lingual' % put together with occipital
    'occipital' %lateraloccipital
    'calcarine' % put together with occipital
    'thalamus'
    'unk'};

TargetLabelAccr={'dlPFC' 
    'dmPFC'
    'vlPFC' %= inferior frontal 
    'mOFC'
    'lOFC'
    'rACC'
    'cACC'
    'isCC'
    'pCC'
    'Amyg'
    'Ent'
    'HC' %    'Hippocampus'    'parahippocampal'
    'Insu'
    'Accum'
    'Caud'
    'Putam'
    'Temp' %inferiortemporal transversetemporal middletemporal superiortemporal
    'Fusi'
    'Cent' %paracentral postcentral precentral
    'SupMar'
    'preC'
    'Pari' % inferiorparietal superiorparietal
    'Cun'
    'Ling' % put together with occipital?
    'Occ' %lateraloccipital
    'Calcar' % Calcarine put together with occipital
    'Thal'
    'unkwn'
    };

% Use the Target Labels above - they are the same as in MMVT parcelation code
RegionLabels=TargetLabels;
nRegions = length(TargetLabels);
ChanColorSch=1:nRegions;
maxColorValue = nRegions;

%% Combine regions as requested
indInCombinedRegions= 1:length(TargetLabelAccr);
for iReg=1:numel(regionsToCombine)
    indInCombinedRegions(find(strcmp(TargetLabelAccr,regionsToCombine{iReg}{1})))=find(strcmp(TargetLabelAccr,regionsToCombine{iReg}{2}));
end
CombinedRegionAccr=TargetLabelAccr(indInCombinedRegions); % must correspond to each other


%% Read PLY files and organize per region
fileNamesPly=dir([atlasPlyFilesDir,'*.ply']);
RegionPly={};VertexLabels={};FaceLabels={};
CategoryValues=zeros(length(fileNamesPly),2);
CategoryStr = cell(length(fileNamesPly),1);
for LP=1:length(fileNamesPly)
    [vertex,face] = read_ply([atlasPlyFilesDir,fileNamesPly(LP).name]);
    VertexLabels{LP}=vertex;
    FaceLabels{LP}=face;
    RegionPly{LP}=fileNamesPly(LP).name;
    for RL=1:nRegions
        if contains(fileNamesPly(LP).name,RegionLabels{RL},'IgnoreCase',true) && isempty(CategoryStr{LP}) % to only assign the first one (to avoid precuneus for being classified as cuneus)
            cate=ChanColorSch(RL);
            cate(cate==0)=maxColorValue; % kept for historical reasons - could probably remove
            cate(isnan(cate)==1)=maxColorValue;% kept for historical reasons - could probably remove
            CategoryValues(LP,:)=[RL cate];
            CategoryStr{LP}= CombinedRegionAccr{RL};
        end
    end
end
