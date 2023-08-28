function tomolist = tomoman_ctffind4(tomolist, p, ctf, ctffind, write_list)
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
    % Check for force
    if (logical(ctf.force_ctffind) == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    if process
        disp(['TOMOMAN: Determining defocus of stack ',tomolist(i).stack_name,' with CTFFIND4!!!']);
        
        % Parse imod name
        switch ctf.imod_stack
            case 'unfiltered'
                imod_name = tomolist(i).stack_name;
            case 'dose_filt'
                imod_name = tomolist(i).dose_filtered_stack_name;
            otherwise
                error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
        end
        
        
        % Check CTFFIND4 folder
        if exist([tomolist(i).stack_dir,'/ctffind4/'],'dir')
            system(['rm -rf ',tomolist(i).stack_dir,'/ctffind4/']);
        end
        mkdir([tomolist(i).stack_dir,'/ctffind4/']);
        
         % Copy .st stack to temp .mrc stack in ctffind4 folder
        [~,st_name,st_ext] = fileparts(imod_name);
        stack_name = [tomolist(i).stack_dir,'/',st_name,st_ext];
        input_stack_name = [tomolist(i).stack_dir,'/ctffind4/',st_name,'.mrc'];
        link_cmd = ['ln -sf ' stack_name  ' ' input_stack_name];
        system(link_cmd);
        
        % Parse parameters
        ctffind = tomoman_ctffind4_parser(ctffind);
        
        % Update pixelsize
        ctffind.pixelsize = tomolist(i).pixelsize;

        % Update defocus range
        ctffind.min_def = (abs(tomolist(i).target_defocus)-ctffind.def_range)*10000;
        ctffind.max_def = (abs(tomolist(i).target_defocus)+ctffind.def_range)*10000;
        
        %diagnostic stack name
        
        diag_name = [tomolist(i).stack_dir,'/ctffind4/','diagnostic_',st_name,'.mrc'];
             
        % Run CTFFIND4
        tomoman_run_ctffind_stack(tomolist(i),input_stack_name,ctffind,diag_name);
        
        fit_array = cell(1,1);
        fit_array{1} = tomoman_read_ctffind4([tomolist(i).stack_dir,'/ctffind4/','diagnostic_',st_name,'.txt']);
        
        
        n_tilts = numel(fit_array{1});
        % Check for phase shift
        if strcmp(ctffind.det_pshift,'no')
            fit_array{1} = rmfield(fit_array{1},'pshift');
        end
        
        % Fix units
        for j = 1:n_tilts
            fit_array{1}(j).defocus_1 = fit_array{1}(j).defocus_1/10000;
            fit_array{1}(j).defocus_2 = fit_array{1}(j).defocus_2/10000;
        end
                       
        
        % Update tomolist
        tomolist(i).ctf_determined = true;
        switch ctf.imod_stack
            case 'unfiltered'
                tomolist(i) = tomoman_store_ctf_param(tomolist(i),fit_array{1},'CTFFIND4-unfiltered');
            case 'dose_filt'
                tomolist(i) = tomoman_store_ctf_param(tomolist(i),fit_array{1},'CTFFIND4-dose_filt');
        end
                
        % Save tomolist
        if write_list
            save([p.root_dir,tomolist_name],'tomolist');
        end
        
        % Write ctfphaseflip file
        tomoman_write_ctfphaseflip(tomolist(i),ctf.imod_stack);
        
        %remove temp file
        %delete(sprintf('%s',input_stack_name));
        
        disp(['TOMOMAN: Defocus determination of stack "',tomolist(i).stack_name,'" complete!!!']);
        
    end
end


