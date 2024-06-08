function tomolist = tm_relion_motioncorr_newstack(tomolist,p,a,relionmc,dep,write_list,par)
%% tm_relion_motioncorr_newstack
% A function for looping through a tomolist and running MotionCor2 on the
% frames and generating a new, properly ordered, stack.
%
% WW 05-2022

%% Generate new stacks

% Number of stacks in tomolist
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    % Check to see if stack should be processed
    process = true;
    if tomolist(i).skip == true
        process = false;
    else
        if tomolist(i).frames_aligned && ~a.force_realign
            process = false;
        end
            
    end


    % Continue loop if not processing
    if ~process
        continue
    end
    
    
     
        
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
    relionmc_dir = [tomolist(i).stack_dir,'RelionMotioncorr/'];
    
    
    % Parse names for temporary aligned images
    ali_names = cell(n_tilts,1);
    for j = 1:n_tilts
        ali_names{j} = [relionmc_dir,tomo_str,'_',num2str(unsorted_idx(j)),'.mrc'];
    end

    % Generate input names
    input_names = cell(n_tilts,1);
    for j = 1:n_tilts
        input_names{j} = [tomolist(i).frame_dir,tomolist(i).frame_names{j}];
    end



    % Run Relion MotionCor2
    disp([p.name,'Running the Relion implementation of MotionCorr2 on ',relionmc.input_format,' stack ',tomo_str]);

    tm_relion_motioncorr_batch_wrapper(p,input_names, ali_names, tomolist(i), relionmc,relionmc_dir,dep,par);

           

    % Assemble new stack
    disp([p.name,'Motion correction complete on stack ',tomo_str,'... Generating new stack!!!']);        

    % New stack parameters
    stack_name = [tomo_str,'.st'];    

    % Generate stacks
    new_stack = tm_build_new_stack(p,tomolist(i),[relionmc_dir,tomo_str],n_tilts,'',a.image_size);    
    
    
    % Write outputs      
    disp([p.name,'TOMOMAN: Writing output stack: ',stack_name]);
    header = sg_generate_mrc_header;
    header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with Relion''s implementation of MotionCorr2. Modified to save Odd-Even sums.');
    sg_mrcwrite([tomolist(i).stack_dir,stack_name],new_stack,header,'pixelsize',tomolist(i).pixelsize);
    [~,stname,~] = fileparts(stack_name);
    dlmwrite([tomolist(i).stack_dir,stname,'.rawtlt'],sorted_tilts);

    
    %%%%% Assemble Odd/Even Stacks %%%%%
    % Generate odd/even stacks
    if relionmc.save_OddEven == 1
        disp([p.name,'Found Odd Even sums for ',tomo_str,'... Generating new stacks!!!']);        

        % Name of odd/even stacks
        stack_names = {[tomo_str,'_ODD.st'],[tomo_str,'_EVN.st']};                        
        stack_types = {'ODD','EVN'};
        
        % Build odd/even stacks
        for j = 1:2

            % Build stacks
            new_stack = tm_build_new_stack(p,tomolist(i),[relionmc_dir,tomo_str],n_tilts,['_',stack_types{j}],a.image_size);                 

            % Write outputs        
            header = sg_generate_mrc_header;
            header = sg_append_mrc_label(header,'TOMOMAN: Frames aligned with Relion''s implementation of MotionCorr2. Modified to save Odd-Even sums.');
            sg_mrcwrite([tomolist(i).stack_dir,stack_names{j}],new_stack,header,'pixelsize',tomolist(i).pixelsize);
            
            disp([p.name,'Stack ',stack_names{j},' written!!!']);
        end
    end

    % Clear temporary .mrc
    system(['rm -f ',relionmc_dir,'*.mrc']);

    % Update tomolist
    tomolist(i).image_size = a.image_size;
    tomolist(i).frames_aligned = true;
    tomolist(i).frame_alignment_algorithm = 'RelionMotionCor';        
    tomolist(i).stack_name = stack_name;

    % Save tomolist
    if write_list
        save([p.root_dir,p.tomolist_name],'tomolist');
    end
        
        
    disp([p.name,'TOMOMAN: Relion MotionCorr2 on ',stack_name,' complete!!!1!']);
end

        
