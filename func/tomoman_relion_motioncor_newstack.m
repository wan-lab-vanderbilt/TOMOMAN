    function tomolist =tomoman_relion_motioncor_newstack(tomolist,p,a,relionmc,write_list)
%% tomoman_alignframes_newstack
% A function for looping through a tomolist and running MotionCor2 on the
% frames and generating a new, properly ordered, stack.
%
% WW 12-2017

%% Generate new stacks

% Number of stacks in tomolist
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    process = false;
    
    % Check for skip
    if (tomolist(i).skip == false)
        process = true;
    end
    % Check for previous alignment
    if (process == true) && (tomolist(i).frames_aligned == false)
        process = true;
    else
        process = false;
    end        
    % Check for force_realign
    if (a.force_realign == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    
    % Process stack
    if process        
        
        % Parse tomogram string
        % separated .st and .mdoc string replacement. for tomo5 and
        % serialEM 
        tomo_str = strrep(tomolist(i).mdoc_name, '.mdoc', '');
        tomo_str = strrep(tomo_str, '.st', '');
        
        % Number of tilts
        n_tilts = size(tomolist(i).collected_tilts,1);
        
        % Generate stack order
        [sorted_tilts, sorted_idx] = sortrows(tomolist(i).collected_tilts);
        
        [~, unsorted_idx] = sortrows(sorted_idx,1);
        
        % Generate temporary output names
        relionmc_dir = [tomolist(i).stack_dir,'RelionMotioncor/'];
        
        if ~exist(relionmc_dir,'dir')
            mkdir(relionmc_dir);
        end
        ali_names = cell(n_tilts,1);
        for j = 1:n_tilts
            ali_names{j} = [relionmc_dir,tomo_str,'_',num2str(unsorted_idx(j)),'.mrc'];
        end
        
        % Generate input names
        input_names = cell(n_tilts,1);
        for j = 1:n_tilts
            input_names{j} = [tomolist(i).frame_dir,tomolist(i).frame_names{j}];
        end
        
        
        
        % Run motioncor2
        disp(['Running Relion''s implementation of MotionCor2 on EER stack ',tomo_str]);
                
        tomoman_relion_motioncor_batch_wrapper(input_names, ali_names, tomolist(i), relionmc,relionmc_dir);
        
        cd(p.root_dir);        
        
        % Assemble new stack
        disp(['Motion correction complete on stack ',tomo_str,'... Generating new stack!!!']);        
        
        % Check for a suffix
        if ~isempty(a.stack_suffix)
            suffix = ['_',a.stack_suffix]; 
        else
            suffix = '';
        end
        
        % New stack parameters
        if ~isempty(a.stack_prefix) && (~strcmp(a.stack_prefix, 'AUTO'))
            stack_names = {[p.prefix,tomo_str,suffix,'.st']};
        else
            stack_names = {[tomo_str,suffix,'.st']};
        end
        stack_types = {'normal'};
        num_stacks = 1;            
        
        
        % Generate stacks
        new_stack = struct;
        for j = 1:num_stacks
            
            for k = 1:n_tilts

                % Read image
                img = sg_mrcread([relionmc_dir,tomo_str,'_',num2str(k),'.mrc']);

                % Initialize stacks
                if k == 1
                    new_stack.(stack_types{j}) = zeros(a.image_size(1),a.image_size(2),n_tilts,'like',img); % In the loop so that it picks up the datatype
                end

                % Resize image
                img = tomoman_resize_stack(img,a.image_size(1),a.image_size(2),true);
                if ~strcmp(tomolist(i).mirror_stack,'none') || isempty(tomolist(i).mirror_stack)
                    img = tom_mirror(img,tomolist(i).mirror_stack);
                end
                new_stack.(stack_types{j})(:,:,k) = img;
            end
            
            % Write outputs        
            header = sg_generate_mrc_header;
            header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with Relion''s implementation of MotionCor2.');
            sg_mrcwrite([tomolist(i).stack_dir,stack_names{j}],new_stack.(stack_types{j}),header,'pixelsize',tomolist(i).pixelsize);
            [~,stname,~] = fileparts(stack_names{j});
            dlmwrite([tomolist(i).stack_dir,stname,'.rawtlt'],sorted_tilts);
        
        end
        
        
        
        % Update tomolist
        tomolist(i).image_size = a.image_size;
        tomolist(i).frames_aligned = true;
        tomolist(i).frame_alignment_algorithm = 'RelionMotionCor';        
        tomolist(i).stack_name = stack_names{1};
        
        % Save tomolist
        if write_list
            save([p.root_dir,p.tomolist_name],'tomolist');
        end
        
        
        % Generate odd/even stacks
        if relionmc.save_OddEven == 1
            if ~isempty(a.stack_prefix) && (~strcmp(a.stack_prefix, 'AUTO'))
                stack_names = {[p.prefix,tomo_str,suffix,'_ODD.st'],[p.prefix,tomo_str,suffix,'_EVN.st']};
            else
                stack_names = {[tomo_str,suffix,'_ODD.st'],[tomo_str,suffix,'_EVN.st']};
            end
            
            num_stacks = 2;
            stack_types = {'ODD','EVN'};
            new_stack = struct;
            for j = 1:num_stacks

                for k = 1:n_tilts

                    % Read image
                    img = sg_mrcread([relionmc_dir,tomo_str,'_',num2str(k),'_',stack_types{j},'.mrc']);

                    % Initialize stacks
                    if k == 1
                        new_stack.(stack_types{j}) = zeros(a.image_size(1),a.image_size(2),n_tilts,'like',img); % In the loop so that it picks up the datatype
                    end

                    % Resize image
                    img = tomoman_resize_stack(img,a.image_size(1),a.image_size(2),true);
                    if ~strcmp(tomolist(i).mirror_stack,'none') || isempty(tomolist(i).mirror_stack)
                        img = tom_mirror(img,tomolist(i).mirror_stack);
                    end
                    new_stack.(stack_types{j})(:,:,k) = img;
                end

                % Write outputs        
                header = sg_generate_mrc_header;
                header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with Relion Motioncor implementation.');
                sg_mrcwrite([tomolist(i).stack_dir,stack_names{j}],new_stack.(stack_types{j}),header,'pixelsize',tomolist(i).pixelsize);
            end
        end
        
    end
    
end

        
