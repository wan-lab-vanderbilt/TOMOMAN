function tomolist =tomoman_motioncor2_newstack(tomolist,p,a,mc2,write_list)
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
    if (mc2.force_realign == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    
    % Process stack
    if process        
        
        % Parse tomogram string
        tomo_str = sprintf(['%0',num2str(p.digits),'d'],tomolist(i).tomo_num);
        
        
        % Number of tilts
        n_tilts = size(tomolist(i).collected_tilts,1);
        
        % Generate stack order
        [sorted_tilts, sorted_idx] = sortrows(tomolist(i).collected_tilts);
        [~, unsorted_idx] = sortrows(sorted_idx,1);
        
        % Generate temporary output names
        mc2_dir = [tomolist(i).stack_dir,'MotionCor2/'];
        if ~exist(mc2_dir,'dir')
            mkdir(mc2_dir);
        end
        ali_names = cell(n_tilts,1);
        for j = 1:n_tilts
            ali_names{j} = [mc2_dir,tomo_str,'_',num2str(unsorted_idx(j)),'.mrc'];
        end
        
        % Generate input names
        input_names = cell(n_tilts,1);
        for j = 1:n_tilts
            input_names{j} = [tomolist(i).frame_dir,tomolist(i).frame_names{j}];
        end
        
        
        
        % Run motioncor2
        disp(['Running MotionCor2 on stack ',tomo_str]);
        tomoman_motioncor2_batch_wrapper(input_names, ali_names, tomolist(i), mc2)
        
        
        
        
        % Assemble new stack
        disp(['MotionCor2 complete on stack ',tomo_str,'... Generating new stack!!!']);        
        
        
        % New stack parameters
        if a.stack_prefix
            stack_names = {[p.prefix,tomo_str,'.st']};
        else
            stack_names = {[tomo_str,'.st']};
        end
        stack_types = {'normal'};
        num_stacks = 1;            
        
        
        % Additional stack parameters for dose filtering
        if mc2.dose_filter
            stack_names = cat(1,stack_names,[stack_names{1}(1:end-3),mc2.dose_filter_suffix,'.st']);
            stack_types = cat(1,stack_types,'dose_filt');
            num_stacks = 2;
        end

        
        % Generate stacks
        new_stack = struct;
        for j = 1:num_stacks
            
            for k = 1:n_tilts

                % Read image
                img = sg_mrcread([mc2_dir,tomo_str,'_',num2str(k),'.mrc']);

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
            header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with MotionCor2.');
            sg_mrcwrite([tomolist(i).stack_dir,stack_names{j}],new_stack.(stack_types{j}),header,'pixelsize',tomolist(i).pixelsize);
            [~,stname,~] = fileparts(stack_names{j});
            dlmwrite([tomolist(i).stack_dir,stname,'.rawtlt'],sorted_tilts);
        
        end
        
        
        
        % Update tomolist
        tomolist(i).image_size = a.image_size;
        tomolist(i).frames_aligned = true;
        tomolist(i).frame_alignment_algorithm = 'MotionCor2';        
        tomolist(i).stack_name = stack_names{1};
        if mc2.dose_filter
            tomolist(i).dose_filtered = true;
            tomolist(i).dose_filtered_stack_name = stack_names{2};
            tomolist(i).dose_filter_algorithm = 'MotionCor2';
        end
        
        % Save tomolist
        if write_list
            save([p.root_dir,p.tomolist_name],'tomolist');
        end
        
        
        
        % Clean temporary files
        for j = 1:n_tilts
            system(['rm -rf ',ali_names{j}]);
        end
        if mc2.dose_filter
            for j = 1:n_tilts
                [path,name,~] = fileparts(ali_names{j});
                system(['rm -rf ',path,'/',name,'_DW.mrc']);
            end
        end
        
    end
    
end

        
