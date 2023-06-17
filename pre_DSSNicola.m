function pre_DSSNicola(trigger_list, subject_list, config)
    % Here we compute and project the data into the DSS space keeping all
    % the components. The projection into the channel space is performed in
    % another script (pre_DSSprojection.m).
    %
    % trigger_list: couples (5,15) or (10, 20).
    % * 5 : 3 second RAND sequences.
    % * 10: 15 second RAND sequences.
    % * 15: 3 second REG sequences.
    % * 20: 15 second REG sequences.
    %
    % subject_list:
    % * 2-15, the index of the subject.
    %
    % config: allows for certain configurations.
    %   .out_folder: name of the folder where data will be stored.
    %   .store_data: set to 1 to store in a .mat file the whole data of the
    %       subject once that it has been processed.
    %   .channels_path: path indicating where to find the channel
    %       information file.
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
    

    out_folder = config.out_folder;
    compute = 1; % If it set to 1, we compute ALWAYS the DSS projection (slow).
%     store_data = config.store_data;
%     single = config.single;
    %%       
    % First we check if the transformed data exists. If it does, we do
    % nothing ( we save time).
    if  compute == 1% | isdir(fullfile('..','Results',out_folder,'DSS_components','Transformed')) == 0 | exist(fullfile('..','Results',out_folder,'DSS_components','Transformed',sprintf('Xdss-TRIG_%d-%d-COMP_%d.mat',trigger_list(1), trigger_list(2), n_components))) == 0
        for subject_ind = 1:length(subject_list)
            % We read the data from both triggers and use it to compute the
            % DSS transformation matrix.
            for trigger_ind = 1:length(trigger_list)
                load(fullfile('D:\Results',out_folder,'Preprocessed_data_AllChannels',...
                sprintf('data_subject-TRIG_%d-SUBJ_%d.mat',trigger_list(trigger_ind), subject_list(subject_ind))),'data_subject');
                
                % In order to get the DSS matrix we limit the temporal data
                % to use (depending on the SHORT/LONG modality).
%                 cfg = [];
%                 if trigger_list(trigger_ind) == 5 | trigger_list(trigger_ind) == 15
%                     cfg.toilim = [-0.2, 4]; % From -200ms to 4 seconds for SHORT.
%                 else
%                     cfg.toilim = [-0.2,16]; % From -200ms to 16 seconds for LONG.
%                 end 
%                 data_subject = ft_redefinetrial(cfg,data_subject );
                

                % We baseline using the average value of the pre-stimuli
                % information. This is useful if we want to change the
                % baseline.
%                 cfg = [];
%                 cfg.demean = 'yes'; % Necessary to baseline.
%                 cfg.baselinewindow = [-0.2 0];% in seconds
%                 data_subject_BS = ft_preprocessing(cfg, data_subject);

                % We store the data for both conditions in a cell matrix.
                x_orig{trigger_ind} = cat(3,data_subject_BS.trial{:});
            end

        
                % We reshape the data to fit the structure of DSS (NoiseTools)
%                 t = data_subject.time{1};
                
                
                % We don't collapse the subjects.
                x1 = permute(x_orig{1},[2,1,3]);
                x2 = permute(x_orig{2},[2,1,3]);
                
                c0=nt_cov(x1)+nt_cov(x2); % c0: baseline covariance
                c1=nt_cov(mean(x1,3))+nt_cov(mean(x2,3)); % c1: biased covariance

                % DSS
                [todss,pwr0,pwr1]=nt_dss0(c0,c1); 
                
                NKEEP = 12;
                xx1=nt_mmat(x1,todss(:,1:NKEEP));
                xx2=nt_mmat(x2,todss(:,1:NKEEP));

                TIME = [421:721];
                c0=nt_cov(xx1(TIME,:,:))+nt_cov(xx2(TIME,:,:));
                c1=nt_cov(mean(xx1(TIME,:,:),3)-mean(xx2(TIME,:,:),3));
                [todss,pwr0,pwr1]=nt_dss0(c0,c1);              
                % todss: matrix to convert data to normalized DSS components
                % pwr0: power per component (baseline)
                % pwr1: power per component (biased)

                z1=nt_mmat(xx1,todss);
                z2=nt_mmat(xx2,todss);
                
                zz=cat(3,z1,z2); %dss components
                x=cat(3,x1,x2); %raw data
                
                
                NKEEP=2;
                C=nt_regcov(nt_xcov(x,zz(:,1:NKEEP,:)),nt_cov(zz(:,1:NKEEP,:)));
                
                av1=nt_mmat(z1(:,1:NKEEP,:),C); av1 = permute(av1(:,:,:), [2,1,3]);                    
                av2=nt_mmat(z2(:,1:NKEEP,:),C); av2 = permute(av2(:,:,:), [2,1,3]);
                %av is the output data(components) of DSS analysis, 
                dss_comp(:,:,subject_ind,1) = mean(av1,3);
                dss_comp(:,:,subject_ind,2) = mean(av2,3);
               
                DSSdata_subject1 = nt_mat2trial(av1);
                DSSdata_subject2 = nt_mat2trial(av2);
                
                DSS_timelock1 = mean(av1,3);
                DSS_timelock2 = mean(av2,3);
                
                mkdir(fullfile('D:\Results',out_folder,'DSS_components','DSS_data'));

                %save trigger 1
                save(fullfile('D:\Results',out_folder,'DSS_components','DSS_data',sprintf('Xdss-TRIG_%d-COMP_%d_NBprocedure.mat',...
                trigger_list(1), NKEEP)),'DSSdata_subject1','DSS_timelock1');
                %save trigger 2
                save(fullfile('D:\Results',out_folder,'DSS_components','DSS_data',sprintf('Xdss-TRIG_%d-COMP_%d_NBprocedure.mat',...
                trigger_list(1), NKEEP)),'DSSdata_subject2','DSS_timelock2');

%                 plot(mean(rms(x1,2),3)); hold on; plot(mean(rms(av1,1),3));
%                 plot(mean(rms(x2,2),3)); hold on; plot(mean(rms(av2,1),3));
%                 
%                 clear z_timelock z
%                 plot(rms(mean(av1,3),1)); hold on; plot(rms(mean(av2,3),1));
%                 legend('RAND','REG')
%                 plot(rms(mean(av1,3),1)); hold on; plot(rms(mean(permute(x1,[2,1,3]),3),1))
%                 legend('Projected','Original')
%             end                     
          end
                
%         if store_data == 1
% 
%             mkdir(fullfile('D:\Results',out_folder,'DSS_components'));           
%             save(fullfile('D:\Results',out_folder,'DSS_components',sprintf('Xdss-TRIG_%d-%d-COMP_%d_MAX.mat',trigger_list(1), trigger_list(2), NKEEP)),'dss_comp', '-v7.3');
%             
%         end
    end

        
end
