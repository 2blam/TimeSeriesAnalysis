%%data collected info
% channels per frame: 57
% frames per epoch: 1500
% epochs: 337
% sampling rate (Hz): 500
% epoch start (sec): -1
% epoch end (sec): 1.998
dataDir = 'D:\ROY\EEG Data for King & Toby\EEG data after IC removal\';
dirlist = dir(dataDir);
eegFileName = 'NoFB_MonoVFB_Mono.set';
eventTypeVal_A = 2;
eventTypeVal_B = 4;
outputDir = 'D:\ROY\EEG Data for King & Toby\EEG data after IC removal_processed\';

for k = 1:size(dirlist, 1)
   %if it is not . or ..
   if strcmp(dirlist(k).name, '.') == 0 & strcmp(dirlist(k).name, '..') == 0
        dirName = dirlist(k).name;
        filepath = [dataDir dirName];
       
        %read eeg file
        eegset = pop_loadset([filepath '\' eegFileName]);
        eegdata = eegset.data; %57 channels x 1500 time tick x 337 epochs
        channel_labels = char(eegset.chanlocs.labels); 
        numOfChannel = size(channel_labels,1);
        
        %get the event info
        eventType = [eegset.event.type];
        eventLatency = [eegset.event.latency];
        eventInEpoch = [eegset.event.epoch];

        %get the ephoch number of the specific event (2, 4) 
        ephocNumWithEventA = unique(eventInEpoch(eventType == eventTypeVal_A));
        ephocNumWithEventB = unique(eventInEpoch(eventType == eventTypeVal_B));
        
        %subset the data for further processing
        eventA = eegdata(:, :, ephocNumWithEventA);
        eventB = eegdata(:, :, ephocNumWithEventB);
        
        %get the mean
        eventAMean = mean(eventA, 3);
        eventBMean = mean(eventB, 3);
        
        %for each channel, normalized with zero mean and unit variance
        for r = 1:size(eventAMean, 1)
            eventAMean(r, :) = (eventAMean(r, :) - mean(eventAMean(r, :))) ./ sqrt(sum(eventAMean(r, :).^2));
        end
        
        for r = 1:size(eventBMean, 1)
            eventBMean(r, :) = (eventBMean(r, :) - mean(eventBMean(r, :))) ./ sqrt(sum(eventBMean(r, :).^2));
        end
        
        eventAMean = eventAMean';
        eventBMean = eventBMean';
        
        %save the mat file - eventTypeVal_A 
        
        data.input = eventAMean;
        data.channel_labels = channel_labels;
        data.chanlocs = eegset.chanlocs;
        %create outputdir
        mkdir([outputDir dirName]);
        outputFileName = [outputDir dirName '\e' num2str(eventTypeVal_A) '.mat'];
        save(outputFileName, 'data');
        
        %save the mat file - eventTypeVal_B 
        data.input = eventBMean;
        data.channel_labels = channel_labels;
        data.chanlocs = eegset.chanlocs;
        outputFileName = [outputDir dirName '\e' num2str(eventTypeVal_B) '.mat'];
        save(outputFileName, 'data'); 
   end
end