function tomolist = tm_ctffind4(tomolist, p, ctffind4, dep, write_list)
%% tm_ctffind4
% A function for taking a tomolist and running CTFFIND.
% 
% SK, WW 07-2025

% Check for subset_list
if sg_check_param(ctffind4,'subset_list')
    subset_list = dlmread([p.root_dir,ctffind4.subset_list]);
else
    subset_list = [];
end

%% Run CTFFIND4

% Determine number of stacks
n_stacks = numel(tomolist);

for i = 1:n_stacks
    
    
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
        disp([p.name,tomolist(i).stack_name,' set to skip... Moving on to next stack...']);
    elseif tomolist(i).ctf_determined
        if ~ctffind4.force_ctffind
            process = false;
            disp([p.name,tomolist(i).stack_name,' has already been through CTF estimation... Moving on to next stack...']);
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
        disp([p.name,'Determining defocus of stack ',tomolist(i).stack_name,' with CTFFIND4!!!']);
        
        %%%%% Prepare file names %%%%%
        
        % Parse stack name for processing
%         switch tomolist(i).alignment_stack
%             case 'unfiltered'
%                 stack_name = tomolist(i).stack_name;
%             case 'dose-filtered'
%                 stack_name = tomolist(i).dose_filtered_stack_name;
%             otherwise
%                 error(['TOMOMAN: ACHTUNG!!! ',are.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
%         end
        stack_name = tomolist(i).stack_name;
        
        
        
        %%%%% Prepare output folder %%%%%
        
        % Check CTFFIND4 folder
        if exist([tomolist(i).stack_dir,'/ctffind4/'],'dir')
            system(['rm -rf ',tomolist(i).stack_dir,'/ctffind4/']);
        end
        mkdir([tomolist(i).stack_dir,'/ctffind4/']);
        
        
         % Link .st stack to temp .mrc stack in ctffind4 folder
        [~,st_name,~] = fileparts(stack_name);
        input_stack_name = [tomolist(i).stack_dir,'/ctffind4/',st_name,'.mrc'];
        system(['ln -sf ',tomolist(i).stack_dir,stack_name,' ',input_stack_name]);
        
        % Diagnostic stack name
        diag_name = [tomolist(i).stack_dir,'/ctffind4/','diagnostic_',st_name,'.mrc'];

        
        
        
        %%%%% Prepare running CTFFIND4 %%%%%
        
        % Check and update parameters
        ctffind4 = tm_ctffind4_check_params(ctffind4,tomolist(i));
                
        % Run CTFFIND4
        tm_run_ctffind_stack(tomolist(i),input_stack_name,ctffind4,dep,diag_name);
        
        
        
        
        
        %%%%% Parse and store outputs %%%%%

        % Read in CTFFIND4 diagnostic output
        fit_array = tm_read_ctffind4([tomolist(i).stack_dir,'/ctffind4/','diagnostic_',st_name,'.txt']);        
        n_tilts = numel(fit_array);
        
        % Check for phase shift
        if strcmp(ctffind4.det_pshift,'no')
            fit_array = rmfield(fit_array,'pshift');
        end
        
        % Fix units
        for j = 1:n_tilts
            fit_array(j).defocus_1 = fit_array(j).defocus_1/10000;
            fit_array(j).defocus_2 = fit_array(j).defocus_2/10000;
        end
                       
        
        % Update tomolist
        tomolist(i).ctf_determined = true;
%         switch ctffind4.process_stack
%             case 'unfiltered'
%                 ctf_determination_method = 'CTFFIND4_unfiltered';
%             case 'dose-filtered'
%                 ctf_determination_method = 'CTFFIND4_dose-filtered';
%         end
        ctf_determination_method = 'ctffind4';
        tomolist(i).ctf_parameters = struct('cs',ctffind4.cs,'famp',ctffind4.famp);
        tomolist(i) = tm_store_ctf_param(tomolist(i),fit_array,ctf_determination_method);
                
        % Save tomolist
        if write_list
            tm_save_tomolist(p.root_dir,p.tomolist_name,tomolist);
        end
        
        % Write ctfphaseflip file
        tm_write_ctfphaseflip(tomolist(i),'ctffind4');
        
        
        disp([p.name,'Defocus of stack "',tomolist(i).stack_name,'" determined using CTFFIND4!!!']);
        
    end
end


