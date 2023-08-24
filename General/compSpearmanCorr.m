function [rho, pVal] = compSpearmanCorr(dependVars, IndepVars, depLabels, indepLabels, dirImages, titName,alphaVal,xLabels)

%Computes Spearman pairwise linear correlation between each pair of column
%in matrix [IndepVars dependVars]
if nargin<5
    dirImages=[];
end

if ~exist('xLabels','var'), xLabels=[];end
    
    
    
%options:
%Spearman rho
%'complete': exclude rows with NaNs 

[rho, pVal] = corr(dependVars, IndepVars,'type','Spearman','rows','complete');
%[rho pVal] = corr(dependVars, IndepVars,'type','Pearson','rows','complete');

if ~isempty(dirImages) && ischar(dirImages)
    dependVars1=dependVars;
    dependVars1(dependVars1==Inf)=NaN; %ONLY to PLOT!
    indepVars1=IndepVars;
    indepVars1(indepVars1==Inf)= NaN; %ONLY to PLOT!    
    for iDep=1:size(dependVars1,2)
        for iIndep=1:size(indepVars1,2)
            if sum(~isnan(indepVars1(:,iIndep)))>=1 && sum(~isnan(dependVars1(:,iDep)))>=1
            b(iDep,iIndep,:) = regress(dependVars1(:,iDep), [ones(size(indepVars1,1),1) ,indepVars1(:,iIndep)]);
            lineFit(iDep,iIndep,:) = b(iDep,iIndep,1) + b(iDep,iIndep,2) * indepVars1(:,iIndep);
            else
                lineFit(iDep,iIndep,:) = NaN(1,size(indepVars1,1));
            end
        end
    end

    %path onlyName]= strtok(imageGralFileName,'_');
    figure('Name',titName);
    scrsz = get(0,'ScreenSize');
    set(gcf,'Position',[0 0 scrsz(3) scrsz(4)]);
    %[h,ax,bigax] = gplotmatrix(dependVars,IndepVars,[],[],'x',[],[],[],depLabels, indepLabels);
    [h,ax,bigax] = gplotmatrix(IndepVars,dependVars,[],[],'x',[],[],[], indepLabels,depLabels);
    for iAx=1:size(ax,2), 
        uVar = unique(IndepVars(:,iAx));
        set(ax(iAx),'xTick',uVar); 
        if ~isempty(xLabels),set(ax(iAx),'xTickLabel',xLabels{iAx}(uVar)); end
    end
    %title('Rates vs. Stimulation Features')
    [iDep iIndep] = find(pVal<alphaVal);
    for i=1:length(iDep)
        legend(ax(iDep(i),iIndep(i)), ['rho:', num2str(rho(iDep(i),iIndep(i))),' pVal:',num2str(pVal(iDep(i),iIndep(i)))])
        hold(ax(iDep(i),iIndep(i)),'on')
        %lineFit = b(iDep(i),iIndep(i),1) + b(iDep(i),iIndep(i),2) * IndepVars(
        plot(ax(iDep(i),iIndep(i)),indepVars1(:,iIndep(i)),squeeze(lineFit(iDep(i),iIndep(i),:)),'k')
    end
    suptitle(titName);
    name4Save = regexprep(titName,'\s','');
    savefig(gcf,[dirImages, filesep, name4Save,'.fig'],'compact');
    saveas(gcf, [dirImages,filesep, name4Save,'.png']);
end
