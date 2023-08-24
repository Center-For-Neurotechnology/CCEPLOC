function plotValuesOnAtlasBrainAsBubbles(plotVar, fileNameRASInAtlas, chNamesPNamesToPlot, titName, FaceLabels,VertexLabel, COLVar, valSteps, bubbleSize)
% To plot (Left / Right / Subcortical) - call separately

% faceAlphaVal makes it more transparent - useful to show sub-cortical regions  with cortical in background

% load RAS location of all channels -- from Colin27 MMVT parcellation - but could be anything
stRAS = load(fileNameRASInAtlas);
allRefChNames = stRAS.allChNames;
allChNamesPNames = stRAS.alChNamesPNames;
allContactNames = stRAS.allContactNames;
allPatientNames = stRAS.allPatientNames;
allRAS = stRAS.allRAS;

% Plot EACH channel's value at their location
ME=plotVar; %medianVal; %
gname=chNamesPNamesToPlot;
% divide in channels (contacts) and patient names - since RAS are in referential we need to move it to bipolar
[spChPat, marker] = split(chNamesPNamesToPlot,{'p','sub'});  % SPECIFIC to participant ID
pNamesToPlot = strcat(marker, spChPat(:,2));
chNamesToPlot = regexprep(spChPat(:,1),'_','');
contactsToPlot = split(chNamesToPlot,'-'); % assumes bipolar and names separated by '-'

% Get location from RAS convert to biploar location as center of the 2
coordRASBipolar = zeros(length(chNamesPNamesToPlot),3);
for iCh=1:length(chNamesPNamesToPlot)
    indPName = find(~cellfun(@isempty,strfind(allPatientNames, pNamesToPlot{iCh})));
    indContact = cell(1,2);
    for iContact=1:2
        indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, contactsToPlot{iCh, iContact})));
        if isempty(indContact{iContact}) % Change RFP to RPF
            ch_32 = contactsToPlot{iCh,iContact}([1,3,2,4:end]);
            indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, ch_32)));
        end
        if isempty(indContact{iContact}) % Change 01 to 1
            ch_01 = regexprep(contactsToPlot{iCh,iContact},'0(?=\d)','');
            indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, ch_01)));
        end
        if isempty(indContact{iContact}) % Change 1 to 01
            indChWithout0 = regexp(contactsToPlot{iCh,iContact},'\D\d$')+1;
            if ~isempty(indChWithout0)
                ch_1 = strcat(contactsToPlot{iCh,iContact}(1:indChWithout0-1),'0',contactsToPlot{iCh,iContact}(indChWithout0:end));
                indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, ch_1)));
            end
        end
        if isempty(indContact{iContact}) % Change RFP to RPF & 01 to 1
            ch_01 = regexprep(ch_32,'0(?=\d)','');
            indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, ch_01)));
        end
        if isempty(indContact{iContact}) % Change 1 to 01
            indChWithout0 = regexp(ch_32,'\D\d$')+1;
            if ~isempty(indChWithout0)
                ch_1 = strcat(contactsToPlot{iCh,iContact}(1:indChWithout0-1),'0',contactsToPlot{iCh,iContact}(indChWithout0:end));
                indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, ch_1)));
            end
        end
        if isempty(indContact{iContact}) % Change RFP to RPF
            ch_32 = strcat(contactsToPlot{iCh,iContact}([1,2]),'I',contactsToPlot{iCh,iContact}(4:end));
            ch_01 = regexprep(ch_32,'0(?=\d)','');
            indContact{iContact} =  intersect(indPName, find(strcmpi(allRefChNames, ch_01)));
        end
    end
    if ~isempty(indContact{1})
         coordRASBipolar(iCh,:) = mean([allRAS(indContact{2},:);allRAS(indContact{1},:)],1);
    else
        disp(['Channel ' ,chNamesToPlot{iCh},' ',pNamesToPlot{iCh}, ' not found'])
    end
end


% Plot brain location of channels
hold on
if ~isempty(FaceLabels) % if empty it can be used to add more bbubles to the same plots
    patch('Faces',FaceLabels{1},'Vertices',VertexLabel{1}, 'FaceColor',[.8 .8 .8],'FaceAlpha',.1,'EdgeColor','none')
    patch('Faces',FaceLabels{2},'Vertices',VertexLabel{2}, 'FaceColor',[.8 .8 .8],'FaceAlpha',.1,'EdgeColor','none')
end

scatter3(coordRASBipolar(:,1), coordRASBipolar(:,2), coordRASBipolar(:,3),...
    round(bubbleSize*1.3), zeros(size(coordRASBipolar,1),3),'filled') % 

% % find color for plotVars
for iCh=1:length(gname)
    [valDist indInStep] =min(abs(valSteps-plotVar(iCh)));
  %  indInStep=  intersect(find(plotVar(iCh)>=valSteps), find(plotVar(iCh)<valSteps));
    COLORPATCH= COLVar(indInStep,:);
    h(iCh) = scatter3(coordRASBipolar(iCh,1), coordRASBipolar(iCh,2), coordRASBipolar(iCh,3),...
        bubbleSize, COLORPATCH,'filled');
end

% if ~isempty(plotVar)
%     for iCh=1:length(gname)
%         COLORPATCH=[.8 .8 .8];
%         for hn=1:length(valSteps)-1
%             if plotVar(iCh)>valSteps(hn) && plotVar(iCh)<=valSteps(hn+1)
%                 COLORPATCH= COLVar(hn,:);
%             end
%         end
%         h(iCh)=scatter3(coordRASBipolar(iCh,1), coordRASBipolar(iCh,2), coordRASBipolar(iCh,3),...
%             bubbleSize, COLORPATCH,'filled');
%     end
% end



% change view
view(90,0)
camlight headlight
lighting gouraud
axis off
daspect([1 1 1])

title(titName,'FontSize',12)

legend(h,gname)
