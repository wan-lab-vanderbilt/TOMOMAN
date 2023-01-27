function tomolist = tomoman_targetdefocus_ctffind4(tomolist, p, ctf, ctffind, write_list)
%% tomoman_gctf
% A function for taking a tomolist and running CTFFIND.
% WW 12-2017
% SK 01-2020


%% Run GCTF
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    % Check for skip
    if (tomolist(i).skip == false)
        process = true;
    else
        process = false;
    end
    % Check for previous alignment
    if (process == true) && (tomolist(i).ctf_determined == false)
        process = true;
    else
        process = false;
    end        
    % Check for force_realign
    if (logical(ctf.force_ctffind) == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    if process
        disp(['TOMOMAN: Determining target defocus of stack ',tomolist(i).stack_name,' with CTFFIND4!!!']);        
        
        % Check CTFFIND4 folder
        if ~exist([tomolist(i).stack_dir,'/ctffind4/'],'dir')
            mkdir([tomolist(i).stack_dir,'/ctffind4/']);
        end
        
        % Copy  first tilt angle stack to temp .mrc stack in ctffind4 folder
        % Parse tomogram string
        tomo_str = strrep(tomolist(i).mdoc_name, '.mdoc', '');
        tomo_str = strrep(tomo_str, '.st', '');
        % Generate stack order
        [~, sorted_idx] = sortrows(tomolist(i).collected_tilts);       
        [~, unsorted_idx] = sortrows(sorted_idx,1);
        
        % Check which motion correction algorithm was used 
        switch tomolist(i).frame_alignment_algorithm
            case 'RelionMotionCor'
                motioncor_dir = [tomolist(i).stack_dir,'RelionMotioncor/'];
            case 'MotionCor2'
                motioncor_dir = [tomolist(i).stack_dir,'MotionCor2/'];
            otherwise
                 error('ACTHUNG!!! Unsuppored frame alignment algorithm "RelionMotionCor" and "MotionCor2" supported!!!');
        end
                
        init_tilt_stackname = [motioncor_dir,tomo_str,'_',num2str(unsorted_idx(1)),'.mrc'];
         
        
        [~,st_name,~] = fileparts(init_tilt_stackname);
        input_stack_name = [tomolist(i).stack_dir,'/ctffind4/',st_name,'.mrc'];
        link_cmd = ['ln -sf ' init_tilt_stackname  ' ' input_stack_name];
        system(link_cmd);
        
        % Parse parameters
        ctffind = tomoman_ctffind4_parser(ctffind);
        
        % Update pixelsize
        ctffind.pixelsize = tomolist(i).pixelsize;

        % Update defocus range
        ctffind.min_def = (abs(tomolist(i).target_defocus)-ctf.init_def_range)*10000;
        ctffind.max_def = (abs(tomolist(i).target_defocus)+ctf.init_def_range)*10000;
        
        %diagnostic stack name
        
        diag_name = [tomolist(i).stack_dir,'/ctffind4/','diagnostic_',st_name,'.mrc'];
             
        % Run CTFFIND4
        tomoman_run_ctffind_single(tomolist(i),input_stack_name,ctffind,diag_name);
        
        fit_array = cell(1,1);
        fit_array{1} = tomoman_read_ctffind4([tomolist(i).stack_dir,'/ctffind4/','diagnostic_',st_name,'.txt']);
        
        
        % Check for phase shift
        if strcmp(ctffind.det_pshift,'no')
            fit_array{1} = rmfield(fit_array{1},'pshift');
        end
        
        % Fix units
        defocus_1 = fit_array{1}(1).defocus_1/10000;
        defocus_2 = fit_array{1}(1).defocus_2/10000;
        defocus_mean = (defocus_1 + defocus_2)./2;            
        
        % Update target
        disp(['TOMOMAN: Target defocus  of stack "',tomolist(i).stack_name,'" changed from  ', num2str(tomolist(i).target_defocus), ' to ' , num2str(defocus_mean)]);              

        tomolist(i).target_defocus = defocus_mean;
        % Save tomolist
        if write_list
            save([p.root_dir,tomolist_name],'tomolist');
        end
                        
        disp(['TOMOMAN: Target defocus determination of stack "',tomolist(i).stack_name,'" complete!!!']);
        
    end
end


