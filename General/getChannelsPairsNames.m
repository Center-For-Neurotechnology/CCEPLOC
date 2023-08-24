function [returnNumbers, returnNames, returnAllChNumbers] = getChannelsPairsNames(sessionDataConfig)

allChNumbers = [sessionDataConfig.sCoreParams.decoders.txDetector.channel1', sessionDataConfig.sCoreParams.decoders.txDetector.channel2'];
%Only keep detected channels
if strcmpi(sessionDataConfig.feature,'COHERENCE')
    %Coherence is pairs based -> get that info
    nChannels = size(allChNumbers);
    allPairChannels = getPairsChannels(1:nChannels);
    indSelPairs = sessionDataConfig.sCoreParams.viz.featureInds;  %sessionDataConfig.sCoreParams.decoders.txDetector.detectChannelInds;
    pairChannels = allPairChannels(indSelPairs, :);
    for iPair=1:size(pairChannels,1)
        pairNumbers{iPair} = [allChNumbers(pairChannels(iPair,1), :); allChNumbers(pairChannels(iPair,2),:)];
        pairNames{iPair} =  [num2str(allChNumbers(pairChannels(iPair,1), :)),' / ' num2str(allChNumbers(pairChannels(iPair,2),:))];
    end
    returnNames = pairNames;
    returnNumbers = pairNumbers;
    returnAllChNumbers = unique(allChNumbers(pairChannels,:),'rows');
else
    %Channel based analysis -> return channels
    indSelCh = sessionDataConfig.sCoreParams.viz.channelInds;  %sessionDataConfig.sCoreParams.decoders.txDetector.detectChannelInds;
    allChNumbers = allChNumbers(indSelCh,:);
    returnNames = sessionDataConfig.sCoreParams.viz.channelNames;
  %  returnNames = returnNames(sessionDataConfig.sCoreParams.decoders.txDetector.detectChannelInds); %Again ONLY keep detected channels
    returnNumbers = allChNumbers;
    returnAllChNumbers = allChNumbers;
end
