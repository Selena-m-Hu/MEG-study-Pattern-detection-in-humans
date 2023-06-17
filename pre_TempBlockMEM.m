 function data_store = pre_TempBlockMEM(trigger_list, subject, config)
    % Function designed to group the trial information from blocks for a
    % subject/trigger combo. In particular, this function applies our
    % standard preprocessing (baselining and filtering), but it also can
    % apply DETRENDING over the whole data file under consideration
    % (block-wise). In order to accelerate the process, we can use the
    % information from the CHANNELS that we obtained in previous analysis
    % (btw for PSD analysis).
    %
    % We also preprocess the information:
    % * Block-wise detrending (if it was not done before).
    % * Filtering (before OR after epoching).
    % * Pre-stim and post-stim epoching depending on the modality that we 
    %       are using.
    % * Data baselined using the pre-stim average value.
    % * Append the trials of all the blocks concatenation.
    % * Visual rejection.
    %
    % trigger: in couples, (5,15) or (10, 20)
    % * 5 : 3 second RAND sequences.
    % * 10: 15 second RAND sequences.
    % * 15: 3 second REG sequences.
    % * 20: 15 second REG sequences.
    %
    % subject:
    % * 2-15, the index of the subject.
    %
    % config: allows for certain configurations.
    %   .out_folder: name of the folder where data will be stored.
    %   .reject_visual: set to 1 if we want to reject trials visually once
    %       that we have grouped them.
    %   .store_data: set to 1 to store in a .mat file the whole data of the
    %       subject once that it has been processed.
    %   .load_channels: set to 1 to load the channels from a file (in our
    %       case, computed in a previous analysis). Set to 0  to use all
    %       the channels available.
    %   .channels_path: path indicating where to find the channel
    %       information file.
    % 
    % OUTPUT FOLDER (depending on .load_channels):
    % * load_channels = 1 : ../Results/***/Preprocessed_data
    % * load_channels = 0 : ../Results/***/Preprocessed_data_AllChannels
    %
    % Visitor: 
    % Antonio Rodriguez Hidalgo 
    % Dept. of Signal Theory and Communications
    % Universidad Carlos III de Madrid
    % arodh91@gmail.com
    %
    % Principal Investigator:
    % Maria Chait 
    % Ear Institute
    % University College London
    % m.chait@ucl.ac.uk
    %
    % Last update: 06/August/2018
    
    
    % Some internal paramters.
    out_folder      =           config.out_folder;          % Output data folder
    reject_visual   =           config.reject_visual;       % Set to 1 if we want to reject trials visually.
    store_output    =           config.store_data;          % Set to 1 if we want to store a .mat file with the output block data.
    load_channels   =           config.load_channels;
    channels_path   =           config.channels_path;
    hpfreq          =           config.hpfreq;
    lpfreq          =           config.lpfreq;
    pre_filter      =           config.pre_filter;          % Set to 1 to filter the whole data. Set to 0 to filter on the Epoched data.
    
%     mkdir(fullfile('D:\Results'));
    mkdir(fullfile('D:\Results',out_folder));

    
    
    % Input data information.
    % We get the names of the files, considering that are some files with a
    % '.' in the beginning of their name. (Hidden files)
    data_folder = fullfile('D:\MEGGAP','data_longshort', sprintf('Subj%d/',subject));
    filelist_bad = dir([data_folder,'*.ds']);
    counter = 1;
    for ind = 1:length(filelist_bad)
        if filelist_bad(ind).name(1)~= '.'
            filelist{counter} = filelist_bad(ind).name; % This variable contains the names of the MEG data files.
            counter = counter+1;
        end
    end
    clear counter filelist_bad
        
    %% Data preprocessing and merging
    % We load the information of each one of the blocks using a loop.
    % ** WARNING ** 
    % This loop can be integrated with the previous one, but we leave it
    % here for the sake of clarity.
    % *************
    data_store = []; % We use this variable to concatenate the blocks.
     for ind = 2:length(filelist) % We start in the second file, since the first one is the LOC one.
        % We check if the detrended files exist. If they don't, we compute
        % them.
        if isdir(fullfile('D:\Results','Detrended',sprintf('SUBJ_%d', subject))) == 0 | exist(fullfile('D:\Results','Detrended',sprintf('SUBJ_%d', subject), sprintf('BLOCK_%d.mat',ind))) == 0
      
            % We load the whole MEG file, which means that we consider the
            % whole block instead of its trials.
            cfg = [];
            cfg.feedback = 'no';
            cfg.channel = 'MEG';  % We capture all the MEG channels.
            cfg.trialdef.triallength = Inf;
            cfg.trialdef.ntrials = 1;
            cfg.dataset = fullfile(data_folder, filelist{ind});  % File to read.

            cfg = ft_definetrial(cfg);
            data = ft_preprocessing(cfg);

            % If the block is broken for some reason, we don't process it.
            if isempty(data.trial{1}) == 1 
                continue
            end


            % We load the channels that we obtained during the PSD analysis.
            if load_channels == 1
                load(fullfile(channels_path, sprintf('Channels-SUBJ_%d', subject)));
            else
                channels_num = 1:size(data.trial{1},1);
            end

            % Since there exist a peak at the end of the block, we won't
            % consider its information during the detrending process. We simply
            % keep the temporal information from the beggining until just
            % before it occurs. This peak probably has to do with the
            % acquisition process, and it does not interfere with the data
            % under analysis.
            end_block = cfg.event(end).sample + 20*data.fsample;


            fs = data.fsample; % sampling rate
        
        
        
            mkdir(fullfile('D:\Results','Detrended',sprintf('SUBJ_%d', subject)));
            % We use only the channels of interest.
            x = data.trial{1}(channels_num,1:min(end_block+1, length(data.trial{1}))); % extract data from fieldtrip structure
            x = x';

            % We use Noisetools toolbox to smoth and detrend the whole block 
            % information.       
            x = nt_smooth(x,fs/50,3,1);   % smooth with 1/50 Hz kernel (similar to Low-Pass 50Hz)

            w = ones(size(x,1),1);
            x_dt = nt_detrend(x,10,w);     % remove polynomial fit over entire data

            % We organize the processed data according to the Fieldtrip
            % structure.
            data.trial = {x_dt'};
            data.time =  {data.time{1}(1:min(end_block+1, length(data.trial{1})))};
            data.sampleinfo = [1 min(end_block+1, length(data.trial{1}))];
            data.label = data.label(channels_num);
            clear x x_dt w
            
            save(fullfile('D:\Results','Detrended',sprintf('SUBJ_%d', subject), sprintf('BLOCK_%d',ind)), 'data');
            
        else 
            load(fullfile('D:\Results','Detrended',sprintf('SUBJ_%d', subject), sprintf('BLOCK_%d',ind)), 'data');
           
        end
      
        if pre_filter == 1
            cfg=[];
            
            cfg.lpfilter = 'yes';
            cfg.lpfreq = lpfreq;
            if hpfreq > 0
                cfg.hpfilter = 'yes';
                cfg.hpfreq = hpfreq;
            end
            data = ft_preprocessing(cfg, data);
        end

        
        
        for trigger_ind = 1:length(trigger_list)
            % Here, we split our block file into trials after it has been
            % detrended and smoothed.
            cfg = []; 
            cfg.feedback = 'no';
            cfg.channel = 'MEG';  % We capture all the MEG channels.
            cfg.trialdef.eventtype  = 'UPPT001'; 
            cfg.trialdef.eventvalue = trigger_list(trigger_ind);
            cfg.dataset = fullfile(data_folder, filelist{ind});  % File to read.

            % Depending on the trigger we consider a different post-stimuli
            % time.

%             if trigger_list(trigger_ind) == 5 | trigger_list(trigger_ind) == 15
%             cfg.toilim = [-0.2, 5];   % fast trial
%             else
%             cfg.toilim = [-0.2, 18];  % slow trial
%             end
%             data_short = ft_redefinetrial(cfg,data_short);
            prestim =  0.2;
            if (trigger_list(trigger_ind) == 5) || (trigger_list(trigger_ind) == 15)
                cfg.trialdef.prestim    = prestim;  
                cfg.trialdef.poststim   = 4;
            else
                cfg.trialdef.prestim    = prestim;
                cfg.trialdef.poststim   = 16;
            end
            try
                cfg = ft_definetrial(cfg);
            catch
               continue
            end

            data_short = ft_redefinetrial(cfg, data);

            % We baseline using the average value of the pre-stimuli
            % information.
            cfg = [];
            cfg.preproc.demean= 'yes'; % Necessary to baseline.
            cfg.preproc.baselinewindow = [-prestim 0];% in seconds
            data_short = ft_preprocessing(cfg, data_short);

%             cfg = [];
%             cfg.demean = 'yes'; % Necessary to baseline.
%             cfg.baselinewindow = [-prestim 0];% in seconds
%             data_short = ft_preprocessing(cfg, data_short);


            % We low-pass filter the information. In our example, the cutoff
            % freq is on 30 Hz.

            if pre_filter == 0
                cfg=[];
                cfg.lpfilter = 'yes';
                cfg.lpfreq = lpfreq;
                if hpfreq > 0
                    cfg.hpfilter = 'yes';
                    cfg.hpfreq = hpfreq;
                end
                data_short = ft_preprocessing(cfg, data_short);    
            end

    %           cfg=[];
    %         timelock = ft_timelockanalysis(cfg, data_short);
    %         figure;plot(timelock.time, rms(timelock.avg))
            % Once that we have all the data of the block, we concatenate it
            % with the previous ones.
            if isempty(data_store) || length(data_store) < length(trigger_list)
                data_store{trigger_ind} = data_short;
            else
                data_store{trigger_ind} = ft_appenddata(cfg, data_store{trigger_ind}, data_short);
            end
            clear data_short
        end
        
    end
    
    
    
    for trigger_ind = 1:length(trigger_list)
        %% We can reject some of the trials visually.
        if reject_visual == 1
            cfg.channel = 'all';
            data_store{trigger_ind} = ft_rejectvisual(cfg,data_store{trigger_ind});   
        end

        data_subject = data_store{trigger_ind};
        
        %% We can store the block information in a .mat file.
        if store_output == 1
            if load_channels == 1
                mkdir(fullfile('D:\Results',out_folder,'Preprocessed_data'));
                save(fullfile('D:\Results',out_folder,'Preprocessed_data',sprintf('data_subject-TRIG_%d-SUBJ_%d.mat',trigger_list(trigger_ind),subject)),'data_subject')
            else
                cfg = [];


                % We compute the average and other statistics from the trials using
                % ft_timelockanalysis.
                timelock = ft_timelockanalysis(cfg, data_subject);

                mkdir(fullfile('D:\Results',out_folder,'Preprocessed_data_AllChannels'))
                save(fullfile('D:\Results',out_folder,'Preprocessed_data_AllChannels',sprintf('data_subject-TRIG_%d-SUBJ_%d.mat',trigger_list(trigger_ind),subject)),'timelock','data_subject','-v7.3')
            end
        end
    
    end
        
end


