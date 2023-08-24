function [parcelationLabelPerCh, ProbabilityMapping, RASCoordPerCh, parcelationLabelPerCh_stimCh, ProbabilityMapping_stimCh, RASCoordPerCh_stimCh, ProbabilityMappingHeader, TargetLabels] = parcellationMappingBipolar(fileNameParc,fileNameRAS,chNamesSelectedCh2Ch1, stimSiteNamesCh2Ch1, flag_bip)

%% CONFIG
% Regions/labels of interest - set empty to show all 
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
    'precuneus'
    'parietal' % inferiorparietal superiorparietal
    'cuneus'
    'lingual' % put together with occipital
    'occipital' %lateraloccipital
    'calcarine' % put together with occipital
    'thalamus'
    };


%% Read RAS coordinates - in referential
dataTableRAS = readtable(fileNameRAS,'ReadRowNames',true);
RASlabelsOrig = dataTableRAS.Properties.RowNames;
RASlabels = regexprep(RASlabelsOrig, {'_', ' '},'');
RASCoordNames = dataTableRAS.Properties.VariableNames;
cRASCoord = table2array(dataTableRAS);
RASCoord=zeros(size(cRASCoord));
if iscell(cRASCoord)
    for iCh=1:length(RASlabels)
        for iCoord=1:3
            RASCoord(iCh,iCoord) = str2double(cRASCoord{iCh,iCoord});
        end
    end
else
    RASCoord = cRASCoord;
end

%% Read Parcellations - in Bipolar Ch2-Ch1
dataTableParc = readtable(fileNameParc,'ReadRowNames',true);
ElecParcOrig = dataTableParc.Properties.RowNames;
BrainLocationLabels = dataTableParc.Properties.VariableNames;
BrainLocationProbabilities = table2array(dataTableParc);
ElecParc = regexprep(ElecParcOrig, {'_', ' '},'');
    

%% remove "_" from chNamesSelectedCh2Ch1 to compare to ElecParc
chNamesSelectedCh2Ch1 = regexprep(chNamesSelectedCh2Ch1, {'_', ' '},'');
stimSiteNamesCh2Ch1 = regexprep(stimSiteNamesCh2Ch1, {'_', ' '},'');

%% SOME DETAILS

%find white matter prob
%    WMidxs = find(ismember(BrainLocationLabels, {'cerebral-white-matter-lh','cerebral-white-matter-rh'}));
WMidxs = find(strncmpi(BrainLocationLabels, 'cerebral_white_matter',length('cerebral_white_matter')));
WMLocationProbabilities = BrainLocationProbabilities(:,WMidxs);


%find regions with higher probabilities (except white matter)
% excLabels = find(ismember(BrainLocationLabels, {'cerebral-white-matter-lh','cerebral-white-matter-rh','approx', 'elc_length'}));
excLabels = find(ismember(BrainLocationLabels, {'approx', 'elc_length'}));
BrainLocationProbabilities(:,[WMidxs, excLabels]) = [];
BrainLocationLabels([WMidxs, excLabels]) = [];

    
    %% GET REGION PROBABILITY FOR EACH CHANNEL
    parcelationLabelPerCh = cell(size(chNamesSelectedCh2Ch1));
    RASCoordPerCh  = zeros(length(chNamesSelectedCh2Ch1),3);
    ProbabilityMapping = zeros(length(chNamesSelectedCh2Ch1),8);
    ProbabilityMappingHeader={'Gonogo(found a matching parcellation label)', 'Probability of belonging to that label','Probability of belonging in white matter',...
        'log(label probability/white matter probability)','RAS coordinate 1','RAS coordinate 2',...
        'RAS coordinate 3','which label in the TargetLabels list of regions'};    

    for iCh = 1:length(chNamesSelectedCh2Ch1)
    
        % Channel index in the Parcellation file
        indChInParc = find(strcmpi(ElecParc, chNamesSelectedCh2Ch1{iCh}));
        
        % If isempty, the entire line is going to be zero for this channel.
        if ~isempty(indChInParc)
            ProbabilityMapping(iCh,1) = 1; % TODO: to be changed when this code is implemented with the PhysiologyScripts

            %find region with greatest probability
            [MX,IX]= max(BrainLocationProbabilities(indChInParc,:));

            if MX>0 %TODO - use a threshold???
                BrainReg=BrainLocationLabels{IX};
                Elecprob=MX;
                ProbabilityMapping(iCh,2) = MX;
            else
                BrainReg='unk';
                Elecprob=MX;
                ProbabilityMapping(iCh,2) = MX;
            end
            %check if region is within target labels
            if ~isempty(TargetLabels)
                 targetIdx = cellfun(@(x) contains(BrainReg,lower(x)),lower(TargetLabels),'UniformOutput',false);
                 targetIdx = find([targetIdx{:}],1); % this implies that the order of labels matters: e.g. precuneus MUST be before cuneus
                if isempty(targetIdx) % maching region is not a target region
                    ProbabilityMapping(iCh,8) = 0;
                else
                    ProbabilityMapping(iCh,8) = targetIdx;
                end
            else
                ProbabilityMapping(iCh,8) = 0;
            end

            ProbabilityMapping(iCh,3) = max(WMLocationProbabilities(indChInParc,:));
            ProbabilityMapping(iCh,4) = log(ProbabilityMapping(iCh,2)/ProbabilityMapping(iCh,3));
            parcelationLabelPerCh{iCh} = BrainReg;
            
            % Add RAS information
            if flag_bip == 1
                chNamesRef = split(ElecParc{indChInParc},'-');
                ref_elec1 = chNamesRef{1};
                ref_elec2 = chNamesRef{2};

%                 name = ElecParc{indChInParc}(isstrprop(ElecParc{indChInParc},'alpha'));
%                 nb = ElecParc{indChInParc}(isstrprop(ElecParc{indChInParc},'digit'));
%                 nb1 = nb(1:2); nb2 = nb(3:4);
%                 ref_elec1 = [name nb1];
%                 ref_elec2 = [name nb2];

                targetIdx1 = cellfun(@(x) isequal(ref_elec1,x),RASlabels,'UniformOutput',false);
                targetIdx1 = find([targetIdx1{:}]);
                targetIdx2 = cellfun(@(x) isequal(ref_elec2,x),RASlabels,'UniformOutput',false);
                targetIdx2 = find([targetIdx2{:}]);
                
                if isempty(targetIdx1) && isequal(ref_elec1(end-1), '0') % Outlier: case of mismatch in the RAS excel file
                    ref_elec1 = [ref_elec1(1:end-2) ref_elec1(end)];
                    targetIdx1 = cellfun(@(x) isequal(ref_elec1,x),RASlabels,'UniformOutput',false);
                    targetIdx1 = find([targetIdx1{:}]);
                end
                if isempty(targetIdx2) && isequal(ref_elec2(end-1), '0') % Outlier: case of mismatch in the RAS excel file
                    ref_elec2 = [ref_elec2(1:end-2) ref_elec2(end)];
                    targetIdx2 = cellfun(@(x) isequal(ref_elec2,x),RASlabels,'UniformOutput',false);
                    targetIdx2 = find([targetIdx2{:}]);
                end


                RASCoordPerCh(iCh,:) = mean([RASCoord(targetIdx1,:); RASCoord(targetIdx2,:)],1);
                ProbabilityMapping(iCh,5) = mean([RASCoord(targetIdx1,1) RASCoord(targetIdx2,1)]);
                ProbabilityMapping(iCh,6) = mean([RASCoord(targetIdx1,2) RASCoord(targetIdx2,2)]);
                ProbabilityMapping(iCh,7) = mean([RASCoord(targetIdx1,3) RASCoord(targetIdx2,3)]);
            else
                targetIdx1 = cellfun(@(x) isequal(chNamesSelectedCh2Ch1{iCh},x),RASlabels,'UniformOutput',false);
                targetIdx1 = find([targetIdx1{:}]);
                ProbabilityMapping(iCh,5) = RASCoord(targetIdx1,1);
                ProbabilityMapping(iCh,6) = RASCoord(targetIdx1,2);
                ProbabilityMapping(iCh,7) = RASCoord(targetIdx1,3);
                RASCoordPerCh(iCh,:) = RASCoord(targetIdx1,:);
            end 
        end        
    end
     
        
%% Look for stim channels separately (it is not in the list of selChannels)
% dealing with the stim channel
% STIM channels are ALWAYS BIPOLAR!!!
parcelationLabelPerCh_stimCh=cell(size(stimSiteNamesCh2Ch1));
ProbabilityMapping_stimCh = zeros(length(stimSiteNamesCh2Ch1),8);
RASCoordPerCh_stimCh = zeros(length(stimSiteNamesCh2Ch1),3);
if ~isempty(stimSiteNamesCh2Ch1)
    ProbabilityMapping_stimCh = zeros(length(stimSiteNamesCh2Ch1),8);
    for iCh = 1:length(stimSiteNamesCh2Ch1)
        % Channel index in the Parcellation file
        indChInParc = find(strcmpi(ElecParc, stimSiteNamesCh2Ch1{iCh}));
        
        % If isempty, the entire line is going to be zero for this channel.
        if ~isempty(indChInParc)
            ProbabilityMapping_stimCh(iCh,1) = 1; % TODO: to be changed when this code is implemented with the PhysiologyScripts

            %find region with greatest probability
            [MX,IX]= max(BrainLocationProbabilities(indChInParc,:));

            if MX>0 %TODO - use a threshold???
                BrainReg=BrainLocationLabels{IX};
                Elecprob=MX;
                ProbabilityMapping_stimCh(iCh,2) = MX;
            else
                BrainReg='unk';
                Elecprob=MX;
                ProbabilityMapping_stimCh(iCh,2) = MX;
            end
            %check if region is within target labels
            if ~isempty(TargetLabels)
                targetIdx = cellfun(@(x) contains(BrainReg,lower(x)),TargetLabels,'UniformOutput',false);
                targetIdx = find([targetIdx{:}],1); % this implies that the order of labels matters: e.g. precuneus MUST be before cuneus
                if isempty(targetIdx) % maching region is not a target region
                    ProbabilityMapping_stimCh(iCh,8) = 0;
                else
                    ProbabilityMapping_stimCh(iCh,8) = targetIdx;
                end
            else
                ProbabilityMapping_stimCh(iCh,8) = 0;
            end
            
            ProbabilityMapping_stimCh(iCh,3) = max(WMLocationProbabilities(indChInParc,:));
            ProbabilityMapping_stimCh(iCh,4) = log(ProbabilityMapping_stimCh(iCh,2)/ProbabilityMapping_stimCh(iCh,3));
            parcelationLabelPerCh_stimCh{iCh} = BrainReg;
            
            % Find RAS value - STIM channels are ALWAYS BIPOLAR!
            chNamesRef = split(ElecParc{indChInParc},'-');
            ref_elec1 = chNamesRef{1};
            ref_elec2 = chNamesRef{2};
            
            targetIdx1 = cellfun(@(x) isequal(ref_elec1,x),RASlabels,'UniformOutput',false);
            targetIdx1 = find([targetIdx1{:}]);
            targetIdx2 = cellfun(@(x) isequal(ref_elec2,x),RASlabels,'UniformOutput',false);
            targetIdx2 = find([targetIdx2{:}]);
            
            if isempty(targetIdx1) && isequal(ref_elec1(end-1), '0') % Outlier: case of mismatch in the RAS excel file
                ref_elec1 = [ref_elec1(1:end-2) ref_elec1(end)];
                targetIdx1 = cellfun(@(x) isequal(ref_elec1,x),RASlabels,'UniformOutput',false);
                targetIdx1 = find([targetIdx1{:}]);
            end
            if isempty(targetIdx2) && isequal(ref_elec2(end-1), '0') % Outlier: case of mismatch in the RAS excel file
                ref_elec2 = [ref_elec2(1:end-2) ref_elec2(end)];
                targetIdx2 = cellfun(@(x) isequal(ref_elec2,x),RASlabels,'UniformOutput',false);
                targetIdx2 = find([targetIdx2{:}]);
            end
            
            RASCoordPerCh_stimCh(iCh,:) = mean([RASCoord(targetIdx1,:); RASCoord(targetIdx2,:)],1);
            ProbabilityMapping_stimCh(iCh,5) = mean([RASCoord(targetIdx1,1) RASCoord(targetIdx2,1)]);
            ProbabilityMapping_stimCh(iCh,6) = mean([RASCoord(targetIdx1,2) RASCoord(targetIdx2,2)]);
            ProbabilityMapping_stimCh(iCh,7) = mean([RASCoord(targetIdx1,3) RASCoord(targetIdx2,3)]);
        end        
        
        
        
    end
    
end

    
    
%% Orignal Taget regions
% TargetLabels={'rostralmiddlefrontal'% Regions/labels of interest - set empty to show all 
%     'superiorfrontal'
%     'caudalmiddlefrontal'
%     'medialorbitofrontal'
%     'lateralorbitofrontal'
%     'parstriangularis'
%     'Accumbens'
%     'parsopercularis'
%     'temporal'
%     'rostralanteriorcingulate'
%     'caudalanteriorcingulate'
%     'posteriorcingulate'
%     'Amygdala'
%     'Hippocampus'
%     'parahippocampal'
%     'insula'
%     'occipital'
%     'cuneus'
%     'Caudate'
%     };
% 
%     
%     
%     
    
    

