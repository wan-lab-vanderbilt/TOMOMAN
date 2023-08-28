function tomolist = tomoman_exposure_filter(tomolist,p,df,write_list)
%% tomoman_exposure_filter
% A function to take a tomolist and exposure filter stacks using the Grant and
% Grigorieff exposure filters. 
%
% WW 12-2017

%% Check check

if isempty(df.a) || isempty(df.b) || isempty(df.c)
    % Hard-coded resolution-dependent critical exposures 
    a = 0.245;
    b = -1.665;
    c = 2.81;
else
    a = df.a;
    b = df.b;
    c = df.c;    
end


%% Dose filter
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    % Check for skip
    if (tomolist(i).skip == false)
        process = true;
    else
        process = false;
    end
    
    % Check for previous alignment
    if (process == true) && (tomolist(i).dose_filtered == false)
        process = true;
    else
        process = false;
    end        
    % Check for force_realign
    if (logical(df.force_dfilt) == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    if process        
        disp(['TOMOMAN: Dose filtereing stack: ',tomolist(i).stack_name]);
        
        % Find tilts
        
        [tilts,tilt_idx] = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);
        
        n_tilts = numel(tilts);
        
        % Parse doses and order with respect to stack
        dose_array = zeros(n_tilts,2);
        dose_array(:,1) = tilts;
        dose_array(:,2) = tomolist(i).dose(tilt_idx) + df.preexposure;
        
        
        % Parse stack names
        [~,st_name,st_ext] = fileparts(tomolist(i).stack_name);
        
        newstack_name = [st_name,df.dfilt_append,p.stack_suffix,st_ext];
        
        % Apply exposure filters
        switch df.filter_frames
            
            % Apply filter to stack
            case 0
                disp('TOMOMAN: Exposure filtering image stack...')
                
                % Read stack
                disp(['TOMOMAN: Reading stack ',st_name,p.stack_suffix,st_ext,'...']);
                
                [stack,header] = sg_mrcread([tomolist(i).stack_dir,st_name,p.stack_suffix,st_ext]);
                                
                % Force correct dose order
                sorted_dose = sortrows(dose_array,1);
                
                % Exposure filter
                df_stack = tomoman_function_dose_filter_stack(stack, tomolist(i).pixelsize, sorted_dose(:,2), a, b, c);
                
                % Header label
                dose_str = sprintf('%.4f',tomolist(i).dose(1)./tomolist(i).cumulative_exposure_time(1));
                
                label = ['TOMOMAN: Exposure filtered on images with ',dose_str,' e/(A^2)/s'];
                
                % Updatre tomolist
                tomolist(i).dose_filter_algorithm ='TOMOMAN-images';
                                
                
            case 1
                disp('TOMOMAN: Exposure filtering frame stacks...')
                
                % Initialize stack
                df_stack = zeros(tomolist(i).image_size(1),tomolist(i).image_size(2),n_tilts);
                
                % Loop through frame stacks
                for j = 1:n_tilts
                    
                    % Generate stack order
                    [~, sorted_idx] = sortrows(tomolist(i).collected_tilts);
                    
                    frame_idx = find(sorted_idx==tilt_idx(j));
                    
                    % Frame stack name
                    
                    tomo_str = st_name;
                    
                    frame_name = [tomo_str,'_',num2str(frame_idx),'_Stk.mrc'];
                    
                    % Final dose
                    final_dose = dose_array(j,2);
                    
                    % Initial dose
                    if tilt_idx(j) == 1
                        init_dose = df.preexposure;
                    else
                        init_dose = tomolist(i).dose(tilt_idx(j)-1) + df.preexposure;
                    end
                    
                    % Calculate dose per frame
                    if numel(tomolist(i).n_frames) == 1
                        dpf = (final_dose-init_dose)./tomolist(i).n_frames;
                    else
                        dpf = (final_dose-init_dose)./tomolist(i).n_frames(j);
                    end
                    
                    % Read frame stack
                    disp(['TOMOMAN: Reading stack ',frame_name,'...']);
                    try
                        frame_stack = sg_mrcread([tomolist(i).stack_dir,'MotionCor2/',frame_name]);
                    catch
                        error(['ACHTUNG!!! Frame stack ',tomolist(i).stack_dir,'MotionCor2/',frame_name,' not found!!! Did you remember to generate aligned frame stacks with MotionCor2???']);
                    end
                    
                    
                    filt_img = tomoman_function_dose_filter_frame_stack(frame_stack, tomolist(i).pixelsize, init_dose, dpf, a, b, c);
                    filt_img = tomoman_resize_stack(filt_img,tomolist(i).image_size(1),tomolist(i).image_size(2),true);
                   
                    if ~strcmp(tomolist(i).mirror_stack,'none')
                        filt_img = tom_mirror(filt_img,tomolist(i).mirror_stack);
                    end

                    df_stack(:,:,j) = filt_img;
  
                end
                
                % Grab header from stack
                try
                    header = sg_read_mrc_header([tomolist(i).stack_dir,tomolist(i).stack_name]);
                catch
                    header = sg_generate_mrc_header();
                end
                % Header label
                dose_str = sprintf('%.4f',tomolist(i).dose(1)./tomolist(i).cumulative_exposure_time(1));
                label = ['TOMOMAN: Exposure filtered on frames with ',dose_str,' e/(A^2)/s'];

                % Updatre tomolist
                tomolist(i).dose_filter_algorithm ='TOMOMAN-frames';
        end

        % Append header        
        header = sg_append_mrc_label(header,label);
        
        % Write stack
        disp(['TOMOMAN: Saving dose filterd stack ',newstack_name,'!!!']);
        
        sg_mrcwrite([tomolist(i).stack_dir,newstack_name],df_stack,header,'pixelsize',tomolist(i).pixelsize);

        
        % Update tomolist
        if isempty(p.stack_suffix)
            tomolist(i).dose_filtered = true;
            tomolist(i).dose_filtered_stack_name = newstack_name;
        
        
            % Write rawtilt file
            dlmwrite([tomolist(i).stack_dir,st_name,df.dfilt_append,'.rawtlt'],tomolist(i).rawtlt);
        
            % Save tomolist
            if write_list
                save([p.root_dir,p.tomolist_name],'tomolist');
            end
        end
        
                      
    end
    
end




