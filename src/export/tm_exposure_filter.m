function tomolist = tm_exposure_filter(tomolist,p,df,write_list)
%% tm_exposure_filter
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

% Check for subset_list
if sg_check_param(df,'subset_list')
    subset_list = dlmread([p.root_dir,df.subset_list]);
else
    subset_list = [];
end

%% Dose filter
n_stacks = numel(tomolist);

for i = 1:n_stacks
    
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;    
        disp([p.name,tomolist(i).stack_name,' set to skip... Moving on to next stack...']);
    elseif tomolist(i).dose_filtered
        if ~df.force_dfilt
            process = false;
            disp([p.name,tomolist(i).stack_name,' has already been dose filtered... Moving on to next stack...']);
        end
    end
    
    % Check subset_list
    if ~isempty(subset_list)
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
            disp([p.name,tomolist(i).stack_name,' is not in the subset_list... Moving on to next stack...']);
        end
    end
    
    
    if process        
        disp([p.name,'Dose filtereing stack: ',tomolist(i).stack_name]);
        
        % Find tilts
        
        [tilts,tilt_idx] = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);
        
        n_tilts = numel(tilts);
        
        % Parse doses and order with respect to stack
        dose_array = zeros(n_tilts,2);
        dose_array(:,1) = tilts;
        dose_array(:,2) = tomolist(i).dose(tilt_idx) + df.preexposure;
        
        
        % Parse stack names
        [~,st_name,st_ext] = fileparts(tomolist(i).stack_name);
        
        newstack_name = [st_name,df.dfilt_append,st_ext];
        
        % Apply exposure filters
        switch df.filter_frames
            
            % Apply filter to stack
            case 0
                disp([p.name,'Exposure filtering image stack...'])
                
                % Read stack
                disp([p.name,'Reading stack ',tomolist(i).stack_name,'...']);
                
                [stack,header] = sg_mrcread([tomolist(i).stack_dir,tomolist(i).stack_name]);
                
                disp([p.name,tomolist(i).stack_name,' read!!!']);

                
                % Force correct dose order
                sorted_dose = sortrows(dose_array,1);
                
                % Exposure filter
                df_stack = tm_function_dose_filter_stack(p,stack, tomolist(i).pixelsize, sorted_dose(:,2), a, b, c);
                
                % Header label
                dose_str = sprintf('%.4f',tomolist(i).dose(1)./tomolist(i).cumulative_exposure_time(1));
                
                label = ['TOMOMAN: Exposure filtered on images with ',dose_str,' e/(A^2)/s'];
                
                % Updatre tomolist
                tomolist(i).dose_filter_algorithm ='TOMOMAN-images';
                                
                
            case 1
                disp([p.name,'Exposure filtering frame stacks...'])
                
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
                    disp([p.name,'Reading stack ',frame_name,'...']);
                    try
                        frame_stack = sg_mrcread([tomolist(i).stack_dir,'MotionCor2/',frame_name]);
                    catch
                        error([p.name,'ACHTUNG!!! Frame stack ',tomolist(i).stack_dir,'MotionCor2/',frame_name,' not found!!! Did you remember to generate aligned frame stacks with MotionCor2???']);
                    end
                    
                    
                    filt_img = tm_function_dose_filter_frame_stack(p,frame_stack, tomolist(i).pixelsize, init_dose, dpf, a, b, c);
                    filt_img = tm_resize_stack(filt_img,tomolist(i).image_size(1),tomolist(i).image_size(2),true);
                   
                    if sg_check_param(tomolist(i),'mirror_stack')
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
        disp([p.name,'Saving dose filtered stack ',newstack_name,'!!!']);
        
        sg_mrcwrite([tomolist(i).stack_dir,newstack_name],df_stack,header,'pixelsize',tomolist(i).pixelsize);

        
        % Filter odd/even stacks
        if df.check_oddeven
            
            %%%%% Check for odd/even stacks %%%%%
            
            % Odd/even suffix
            oe_suffix = {'_ODD','_EVN'};
            
            % Array to check for stacks
            oe_array = false(2,1);
            
            % Check stacks
            for j = 1:2
                oe_array(j) = exist([tomolist(i).stack_dir,st_name,oe_suffix{j},st_ext],'file');
            end
            
            % Dose filter stacks
            if all(oe_array)
                
                % Split total dose in half
                sorted_dose = sortrows(dose_array,1);
                oe_dose = sorted_dose(:,2)./2;
                
                % Loop through stacks
                for j = 1:2
                    % Read stack
                    disp([p.name,'Reading stack ',st_name,oe_suffix{j},st_ext,'...']);
                    [stack,header] = sg_mrcread([tomolist(i).stack_dir,st_name,oe_suffix{j},st_ext]);
                    disp([p.name,st_name,oe_suffix{j},st_ext,' read!!!']);

                    % Exposure filter
                    df_stack = tm_function_dose_filter_stack(p,stack, tomolist(i).pixelsize, oe_dose, a, b, c);

                    % Header label
                    dose_str = sprintf('%.4f',tomolist(i).dose(1)./tomolist(i).cumulative_exposure_time(1));
                    label = ['TOMOMAN: Exposure filtered on images with ',dose_str,' e/(A^2)/s'];
                    
                    % Append header        
                    header = sg_append_mrc_label(header,label);

                    % Write stack
                    oe_newstack_name = [st_name,df.dfilt_append,oe_suffix{j},st_ext];
                    disp([p.name,'Saving dose filtered stack ',oe_newstack_name,'!!!']);

                    sg_mrcwrite([tomolist(i).stack_dir,oe_newstack_name],df_stack,header,'pixelsize',tomolist(i).pixelsize);
                end
                
                
            else
                for j = 1:2
                    warning([p.name,'ACHTUNG!!! ',st_name,oe_suffix{j},st_ext,' missing!!!'])
                end
                warning([p.name,'ACHTUNG!!! Skipping dose filtering of odd/even stacks!!!'])
            end
            
            
            
            
        end
        
        
        
        
        % Update tomolist
        tomolist(i).dose_filtered = true;
        tomolist(i).dose_filtered_stack_name = newstack_name;
        
        
        % Write rawtilt file
        dlmwrite([tomolist(i).stack_dir,st_name,df.dfilt_append,'.rawtlt'],tomolist(i).rawtlt);
        
        % Save tomolist
        if write_list
            tm_save_tomolist(p.root_dir,p.tomolist_name,tomolist);
        end
        
        % Cleanup
        if df.filter_frames && df.remove_frames
            system(['rm ',tomolist(i).stack_dir,'MotionCor2/*_Stk.mrc']);
        end
            
              
    end
    
end




