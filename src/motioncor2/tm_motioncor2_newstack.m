function tomolist = tm_motioncor2_newstack(tomolist,p,dep,mc2,write_list)
%% tm_motioncor2_newstack
% A function for looping through a tomolist and running MotionCor2 on the
% frames and generating a new, properly ordered, stack.
%
% Edits made to match tm_relion_motioncorr_newstack.m
%
% WW 02-2022

%% Generate new stacks

% Number of stacks in tomolist
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    % Check to see if stack should be processed
    process = true;
    if tomolist(i).skip == true
        process = false;
    else
        if tomolist(i).frames_aligned && ~mc2.force_realign
            process = false;
        end
            
    end
    
    
    % Process stack
    if process        
        
        %%%%% Parse Inputs %%%%%
        
        % Parse tomogram string
        tomo_str = strrep(tomolist(i).mdoc_name, '.mdoc', '');
        tomo_str = strrep(tomo_str,'.mrc','');
        disp([p.name,'Preparing to run Relion MotionCorr on stack: ',tomo_str]);
        
        % Number of tilts
        n_tilts = numel(tomolist(i).collected_tilts);
        
        % Generate stack order
        [sorted_tilts, sorted_idx] = sortrows(tomolist(i).collected_tilts);
        [~, unsorted_idx] = sortrows(sorted_idx,1);
        
        % Generate temporary output names
        mc2_dir = [tomolist(i).stack_dir,'MotionCor2/'];        
        if ~exist(mc2_dir,'dir')
            mkdir(mc2_dir);
        end
        
        % Parse names for temporary aligned images
        ali_names = cell(n_tilts,1);
        for j = 1:n_tilts
            ali_names{j} = [mc2_dir,tomo_str,'_',num2str(unsorted_idx(j)),'.mrc'];
        end
        
        
        % Generate input names
        input_names = cell(n_tilts,1);
        for j = 1:n_tilts
            input_names{j} = [tomolist(i).frame_dir,tomolist(i).frame_names{j}];
        end
        
        
        %%%%% Run MotionCor2 and Assembles Stacks %%%%%
        
        % Run motioncor2
        disp([p.name,'Running MotionCor2 on stack ',tomo_str]);
        tm_motioncor2_batch_wrapper(p,input_names, ali_names, tomolist(i), mc2, dep);
        disp([p.name,'MotionCor2 complete on stack ',tomo_str,'... Generating new stack!!!']);        
        
        
        
        % New stack parameters
        if mc2.dose_filter
            % Generate both filtered and unfiltered stacks
            stack_name = {[tomo_str,'.st'],[tomo_str,mc2.dose_filter_suffix,'.st']};
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
            new_stack = tm_build_new_stack(p,tomolist(i),[mc2_dir,tomo_str],n_tilts,suffixes{j},mc2.image_size);             
            
            % Write outputs        
            header = sg_generate_mrc_header;
            header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with MotionCor2.');
            sg_mrcwrite([tomolist(i).stack_dir,stack_name{j}],new_stack,header,'pixelsize',tomolist(i).pixelsize);
            [~,stname,~] = fileparts(stack_name{j});
            dlmwrite([tomolist(i).stack_dir,stname,'.rawtlt'],sorted_tilts);
            
            disp([p.name,'Stack ',stack_name{j},' written!!!']);
        
        end
                        
        
        %%%%% Assemble Odd/Even Stacks %%%%%
        
        
        % Generate odd/even stacks
        if mc2.SplitSum == 1
            
            % Name of odd/even stacks
            stack_names = {[tomo_str,'_ODD.st'],[tomo_str,'_EVN.st']};                        
            stack_types = {'ODD','EVN'};
            
            % Build odd/even stacks
            for j = 1:2

                % Build stacks
                new_stack = tm_build_new_stack(p,tomolist(i),[mc2_dir,tomo_str],n_tilts,['_',stack_types{j}],mc2.image_size);                 

                % Write outputs        
                header = sg_generate_mrc_header;
                header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with MotionCor2.');
                sg_mrcwrite([tomolist(i).stack_dir,stack_names{j}],new_stack,header,'pixelsize',tomolist(i).pixelsize);
                
                disp([p.name,'Stack ',stack_names{j},' written!!!']);
            end
        end
        
        
        
        %%%%% Update and Save Tomolist %%%%%
        
        % Update tomolist
        tomolist(i).image_size = mc2.image_size;
        tomolist(i).frames_aligned = true;
        tomolist(i).frame_alignment_algorithm = 'MotionCor2';        
        tomolist(i).stack_name = stack_name{1};
        if mc2.dose_filter
            tomolist(i).dose_filtered = true;
            tomolist(i).dose_filtered_stack_name = stack_name{2};
            tomolist(i).dose_filter_algorithm = 'MotionCor2';
        end
        
        % Save tomolist
        if write_list
            save([p.root_dir,p.tomolist_name],'tomolist');
        end
        
   
        %%%%% Cleanup %%%%%
        
        % Clean temporary files
        for j = 1:n_tilts
            
            % Single aligned images
            system(['rm -rf ',ali_names{j}]);
            
            % Dose filtered images
            if mc2.dose_filter
                [path,name,~] = fileparts(ali_names{j});
                system(['rm -rf ',path,'/',name,'_DW.mrc']);
            end
            
            % Odd/Even images
            if mc2.SplitSum
                [path,name,~] = fileparts(ali_names{j});
                system(['rm -rf ',path,'/',name,'_ODD.mrc']);
                system(['rm -rf ',path,'/',name,'_EVN.mrc']);
            end
            
        end
        
        
        
        
    end
    
end

        
