function tomolist = tm_motioncor3_newstack(tomolist,p,dep,mc3,write_list)
%% tm_motioncor3_newstack
% A function for looping through a tomolist and running MotionCor3 on the
% frames and generating a new, properly ordered, stack.
%
%
% WW 08-2025


%% Generate new stacks

% Number of stacks in tomolist
n_stacks = size(tomolist,1);

% Check for subset_list
if sg_check_param(mc3,'subset_list')
    subset_list = dlmread([p.root_dir,mc3.subset_list]);
else
    subset_list = [];
end


for i = 1:n_stacks
    
    % Parse tomogram string
    tomo_str = strrep(tomolist(i).mdoc_name, '.mdoc', '');
    tomo_str = strrep(tomo_str,'.mrc','');
    
    % Check to see if stack should be processed
    process = true;
    if tomolist(i).skip == true
        process = false;
        disp([p.name,tomo_str,' set to skip... Moving on to next stack...']);
    else
        if tomolist(i).frames_aligned && ~mc3.force_realign
            process = false;
            disp([p.name,tomo_str,' has already been motion corrected... Moving on to next stack...']);
        end
            
    end
    
    % Check subset_list
    if ~isempty(subset_list)
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
            disp([p.name,tomo_str,' is not in the subset_list... Moving on to next stack...']);
        end
    end
    
    
    % Process stack
    if process        
        disp([p.name,'Preparing to run MotionCor3 on stack: ',tomo_str]);
        
        %%%%% Parse Inputs %%%%%                
        
        % Number of tilts
        n_tilts = numel(tomolist(i).collected_tilts);
        
        % Generate stack order
        [sorted_tilts, sorted_idx] = sortrows(tomolist(i).collected_tilts);
        [~, unsorted_idx] = sortrows(sorted_idx,1);
        
        % Generate temporary output names
        mc3_dir = [tomolist(i).stack_dir,'MotionCor3/'];        
        if ~exist(mc3_dir,'dir')
            mkdir(mc3_dir);
        end
        
        % Parse names for temporary aligned images
        ali_names = cell(n_tilts,1);
        for j = 1:n_tilts
            ali_names{j} = [mc3_dir,tomo_str,'_',num2str(unsorted_idx(j)),'.mrc'];
        end
        
        
        % Generate input names
        input_names = cell(n_tilts,1);
        for j = 1:n_tilts
            input_names{j} = [tomolist(i).frame_dir,tomolist(i).frame_names{j}];
        end
        
        
        %%%%% Run MotionCor3 and Assembles Stacks %%%%%
        
        % Run MotionCor3
        disp([p.name,'Running MotionCor3 on stack ',tomo_str]);
        tm_motioncor3_batch_wrapper(p,input_names, ali_names, tomolist(i), mc3, dep);
        disp([p.name,'MotionCor3 complete on stack ',tomo_str,'... Generating new stack!!!']);        
        
        
        
        % New stack parameters
        if mc3.dose_filter
            % Generate both filtered and unfiltered stacks
            stack_name = {[tomo_str,'.st'],[tomo_str,mc3.dose_filter_suffix,'.st']};
            suffixes = {'','_DW'};
            num_stacks = 2; 
        else
            stack_name = {[tomo_str,'.st']};            
            suffixes = {''};
            num_stacks = 1;  
        end
        
        
        % Generate stacks
        for j = 1:num_stacks
            
            % Build stack
            new_stack = tm_build_new_stack(p,tomolist(i),[mc3_dir,tomo_str],n_tilts,suffixes{j},mc3.image_size);             
            
            % Write outputs        
            header = sg_generate_mrc_header;
            header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with MotionCor3.');
            sg_mrcwrite([tomolist(i).stack_dir,stack_name{j}],new_stack,header,'pixelsize',tomolist(i).pixelsize);
            [~,stname,~] = fileparts(stack_name{j});
            dlmwrite([tomolist(i).stack_dir,stname,'.rawtlt'],sorted_tilts);
            
            disp([p.name,'Stack ',stack_name{j},' written!!!']);
        
        end
                        
        
        %%%%% Assemble Odd/Even Stacks %%%%%
        
        
        % Generate odd/even stacks
        if mc3.SplitSum == 1
            
            % Name of odd/even stacks
            stack_names = {[tomo_str,'_ODD.st'],[tomo_str,'_EVN.st']};                        
            stack_types = {'ODD','EVN'};
            
            % Build odd/even stacks
            for j = 1:2

                % Build stacks
                new_stack = tm_build_new_stack(p,tomolist(i),[mc3_dir,tomo_str],n_tilts,['_',stack_types{j}],mc3.image_size);                 

                % Write outputs        
                header = sg_generate_mrc_header;
                header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with MotionCor3.');
                sg_mrcwrite([tomolist(i).stack_dir,stack_names{j}],new_stack,header,'pixelsize',tomolist(i).pixelsize);
                
                disp([p.name,'Stack ',stack_names{j},' written!!!']);
            end
        end
        
        
        %%%%% Assemble CTF Parameters %%%%%
        if sg_check_param(mc3,'CTF_est')
           tomolist(i) = tm_mc3_compile_ctf_output(p,tomolist(i),mc3,mc3_dir,tomo_str,n_tilts); 
        end
        
        
        %%%%% Update and Save Tomolist %%%%%
        
        % Update tomolist
        tomolist(i).image_size = mc3.image_size;
        tomolist(i).frames_aligned = true;
        tomolist(i).frame_alignment_algorithm = 'MotionCor3';        
        tomolist(i).stack_name = stack_name{1};
        if mc3.dose_filter
            tomolist(i).dose_filtered = true;
            tomolist(i).dose_filtered_stack_name = stack_name{2};
            tomolist(i).dose_filter_algorithm = 'MotionCor3';
        end
        
        % Save tomolist
        if write_list
            tm_save_tomolist(p.root_dir,p.tomolist_name,tomolist);
        end
        
   
        %%%%% Cleanup %%%%%
        
        % Clean temporary files
        for j = 1:n_tilts
            
            % Single aligned images
            system(['rm -rf ',ali_names{j}]);
            
            % Dose filtered images
            if mc3.dose_filter
                [path,name,~] = fileparts(ali_names{j});
                system(['rm -rf ',path,'/',name,'_DW.mrc']);
            end
            
            % Odd/Even images
            if mc3.SplitSum
                [path,name,~] = fileparts(ali_names{j});
                system(['rm -rf ',path,'/',name,'_ODD.mrc']);
                system(['rm -rf ',path,'/',name,'_EVN.mrc']);
            end
            
        end
        
        
        
        
    end
    
end

        
