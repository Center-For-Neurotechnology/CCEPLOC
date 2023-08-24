function testStimSitesNetwork()
% For each pair send stim and display which is it, then pause before next

%%%%%% electrical stimulation set up %%%%%%%%%%%%
addpath(genpath('C:\Stimulation\CereLAB\'))
cerestim = BStimulator();
connx = connect(cerestim);
if connx < 0
    error('Can''t connect to cerestim')
end
res = configureStimulusPattern(cerestim, 1, 'AF', 1, ...
    7000, 7000, 90, 90, 100, 53);
res = configureStimulusPattern(cerestim, 2, 'CF', 1, ...
    7000, 7000, 90, 90, 100, 53);
pairs = [1 2; 3 4; 5 6; 7 8; 9 10];

%%%%%% Send STIM pulses one by one %%%%%%%%%%%%
disp(['****** Start of Stim Sites Test *******'])
disp([' Testing ',num2str(size(pairs,1)),' STIM pairs'])

for iPair=1:size(pairs,1)
     disp([num2str(iPair),': Stim on ',num2str(pairs(iPair,:))])
        %%%%%%%%%%%%%%%%%% prepares next electrical stimulation %%%%%%%%%%%
            res = beginningOfSequence(cerestim);
            res = wait(cerestim,1); %1750+randi(500));
            res = beginningOfGroup(cerestim);
            res = autoStimulus(cerestim, pairs(iPair,1), 1);
            res = autoStimulus(cerestim, pairs(iPair,2), 2);
            res = endOfGroup(cerestim);
            res = endOfSequence(cerestim);
            %res = cerestim.triggerStimulus('rising');
        res = cerestim.play(1);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    pause;
end
disp(['****** End of Stim Sites Test *******'])

