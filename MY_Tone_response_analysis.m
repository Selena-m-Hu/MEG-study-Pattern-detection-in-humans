%% Tone response analysis
%----Edited by Mingyue Hu, 07/02/2023

clear all;clc;
%% Parameter
hpfreq          = 2;
lpfreq          = 30;
baseline        = '_toneOnset'; %select the baseline scheme： 'toneOnset'； 'none'
fs              = 600; % Sampling frequency
pre_estim       = 0.2; % Prestimuli time (in second). In our case, 200ms.
window_size     = 0.250*fs; % 250 ms, the length of the stimuli (50ms signal + 200ms silence).
trigger_list    =[10 20];
subject_list = [2 3 4 5 6 7 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24];
addpath('D:\fieldtrip-20220707'); 
lastEight = 0; %average the mean response of last 6 tones in each cycle
%% Compute the last 8 tones in each cycle; (to avoid the onset response effects)
if lastEight
% TOI = [0.5 2.5;
%        3 5;
%        5.5 7.5;
%        8 10;
%        10.5 12.5;
%        13 15]; %time interval of interest
else 
%% Compute the whole cycle/10 tones
TOI = [0 2.5;
       2.5 5;
       5 7.5;
       7.5 10;
       10 12.5;
       12.5 15]; %time interval of interest
end 

compute = 1;
plotData = 0;

if compute
 for time_ind = 1:length(TOI)
%     define the time interval of interest
      cycle           = TOI(time_ind,:);
      T_init          = cycle(1);
      T_end           = cycle(2);

  for trigger_ind = 1:length(trigger_list)
   
    for subject_ind = 1:length(subject_list)

    % load the data
        load(fullfile('D:','Results','Trigger_analysis_PRE_HP2_LP30','Preprocessed_data_AllChannels',sprintf('data_subject-TRIG_%d-SUBJ_%d.mat',...
        trigger_list(trigger_ind), subject_list(subject_ind))),'data_subject'); 
        timelock = ft_timelockanalysis([],data_subject);

    % load the selected channels
        load(fullfile('D:\MEGGAP\Channels_DSS',sprintf('Channels-SUBJ_%d',subject_list(subject_ind))),...
        'channels', 'channels_num');
         counter = 1;
                
            for t_ind = 1:window_size:length(timelock.time)
                % We fill the first one (which will not be used) with
                % zeros, since it will be incomplete. This way, the
                % structure of the data is easier and we consider a 50ms
                % to baseline and 200ms of signal. (so the trial structure is pre-stim(50 ms) + tone(50ms) + silence(150ms) =
                % 150 ms). Here we use the pre-stim to conduct 'tone'
                % baseline 
        
                if t_ind == 1                 
                    trigger_shape(:,:,counter) = zeros(length(channels_num),150); %first counter include no information
                else  %[-0.2,0] include no information,the tone onset corresponding to time point of 120, 90 is -0.5 sec(no signal), followed with 200 ms signal
                    trigger_shape(:,:,counter) = timelock.avg(channels_num,t_ind-.1*fs:t_ind+0.15*fs-1); %second counter(first tone), information should start from -0.05
                end
                counter = counter + 1;
            end
            
%            Multiply by a constant in order to get the units into
            % femtoTeslas.
            trigger_shape = trigger_shape*1e15;
%             trigger_shape275 = trigger_shape275*1e15;

            % We get the value of the initial time (0 seconds).
            t0 = 0.25/(window_size/fs);
            
            % We get the temporal index of the beginning and the end of our
            % data from the global matrix.
            t_stable = max(t0,1) + (((T_init/(window_size/fs))+1):(T_end/(window_size/fs))); %the first position does not store data, we start from position 2
            average_shape(:,:)    = squeeze(mean(trigger_shape(:,:,t_stable),3));

            % stable_average_shape275(:,:,subject_ind, trigger_ind)  = mean(trigger_shape275(:,:,t_stable),3);            
            %% We baseline the data according to the criteria we want to use.
            % 'tone onset': each tone is baselined using the activity of the onset of the tone.
                         
            bl_window = 30;  % define the time window you want to use for tone baseline
            bl_tone = '-30'; %useful for saving file name 
            baseline_data = squeeze(mean(average_shape(:,bl_window), 2)); % we only baseline from -30ms from the onset of the tone
%           baseline_data275 = mean(stable_average_shape275(:,1:30,subject_ind, trigger_ind), 2);
            output_appendix = baseline;
                
           % stable_shape(:,:,:,subject_ind, trigger_ind) = trigger_shape - repmat(mean(stable_average_shape(:,1:30,subject_ind, trigger_ind) ,2), 1, 150, size(trigger_shape,3));
            stable_average_shape(:,:,subject_ind, trigger_ind)  =  average_shape(:,:) - repmat(baseline_data, 1, 150);
%            stable_average_shape275(:,:,subject_ind, trigger_ind)  =  stable_average_shape275(:,:,subject_ind, trigger_ind) - repmat(baseline_data275, 1, 150);
            
            clear trigger_shape
            clear baseline_data
            clear data_subject
            clear timelock
            clear channels_num
            clear average_shape
    end 
  end 
      if lastEight
            save(fullfile('D:\Results','Trigger_analysis_PRE_HP2_LP30','Tone_Trials_BLrawdata/',...
            sprintf('lastEIGHTtones_allsub_40chann_toneresponse_TRIG_10_20-Time_%s_%s-BL%s.mat',mat2str(T_init),mat2str(T_end),...
            output_appendix)),'stable_average_shape'); 
            clear stable_average_shape
      else
          save(fullfile('D:\Results','Trigger_analysis_PRE_HP2_LP30','Tone_Trials_BLrawdata/',...
            sprintf('allsub_40chann_toneresponse_TRIG_10_20-Time_%s_%s-BL%s.mat',mat2str(T_init),mat2str(T_end),...
            output_appendix)),'stable_average_shape'); 
            clear stable_average_shape
      end 

 end 
end   


%% quick plot
if plotData
% clear all; clc;

 baseline  = '_toneOnset'; %select the baseline scheme： 'toneOnset'； 'none'
 filename = ['allsub_40chann_toneresponse_TRIG_10_20-Time_%s_%s-BL%s.mat'];
%  for time_ind = 1:length(TOI)
TOI = [0 2.5;
       2.5 5;
       5 7.5;
       7.5 10;
       10 12.5;
       12.5 15];
    % TOI = [0.5 2.5;
    %        3 5;
    %        5.5 7.5;
    %        8 10;
    %        10.5 12.5;
    %        13 15]; %time interval of interest
    %define the time interval of interest
 for time_ind = 1:length(TOI)
 %   define the time interval of interest
      cycle           = TOI(time_ind,:);
      t1          = cycle(1);
      t2           = cycle(2);
  
   % load data
   load(fullfile('D:\Results','Trigger_analysis_PRE_HP2_LP30','Tone_Trials_BLrawdata/',...
   sprintf(filename,mat2str(t1),mat2str(t2),baseline)),'stable_average_shape'); 

   cycleData = squeeze(rms(stable_average_shape,1));
   save('cycle_8_rms_toneresponse_TRIG_10_20-Time_13_15-BL_toneOnset.mat', 'cycleData');
        
   mean_subjects_data = squeeze(rms(stable_average_shape(:,:,:,:),1));
   Diff=mean_subjects_data(:,:,1) - mean_subjects_data(:,:,2); 


    %stats/bootstrap
    perc = 0.05;
    perc2 = 0.01;
    dataB=bootstrap(Diff'); 
    s=findSigDiff(dataB, perc);
    s2=findSigDiff(dataB, perc2);
    k1 = 1;
    k2 = 3;
    
    %mean and standard error
    condi = squeeze(mean(mean_subjects_data(:,:,:),2));
    REG = condi(:,2);
    RAND = condi(:,1);
    REGall = mean_subjects_data(:,:,2);
    RANall = mean_subjects_data(:,:,1);
    REGstd = std(REGall')/sqrt(size(REGall,2));
    RANstd = std(RANall')/sqrt(size(RANall,2));
    
    %Making plot
    time = (1:150)/150*250-50;
    timeind = 30:150;    
    figure(time_ind);
    shadedErrorBar(time(timeind),RAND(timeind),RANstd(timeind),'lineProps','k');
    hold on 
    shadedErrorBar(time(timeind),REG(timeind),REGstd(timeind),'lineProps','r');
    xlim([-0.5,200])
    
    hold on
    plot(time(timeind), k1*abs(s(timeind)),'Linewidth', 12, 'color', 'k');
    hold on
    plot(time(timeind), k2*abs(s2(timeind)),'Linewidth', 12, 'color', 'r');
    xlabel('Time (ms)')
    ylabel('Magnitude (fT)')
    title(sprintf('All subjects. Baseline: %s. Time interval %s-%s', 'baselined', mat2str(t1), mat2str(t2)));
 end 

end 

% end 





