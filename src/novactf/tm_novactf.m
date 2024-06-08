function tomolist = tm_novactf(tomolist, p, novactf, dep, write_list)
%% tm_novactf
% A function for taking a tomolist and running batched initial IMOD 
% preprocessing.
%
% WW 12-2017


%% Initialize

% Number of stacks
n_stacks = numel(tomolist);

% Check for recons_list
if ~isempty(novactf.recons_list)
    recons_list = dlmread(novactf.recons_list);
end

% Check binnings
novactf.tomo_bin = sort(novactf.tomo_bin);  % Resort to ensure order from lowest to highest binning
if ~isempty(novactf.ali_stack_bin)          % The ali_stack_bin should match the lowest output tomogram binning
    if novactf.tomo_bin(1) ~= novactf.ali_stack_bin
        error([p.name,'ACHTUNG!!! There is a mismatch between ali_stack_bin and lowest output tomogram binning!!!']);
    end
else
    if novactf.tomo_bin(1) ~= 1
        error([p.name,'ACHTUNG!!! There is a mismatch between ali_stack_bin and lowest output tomogram binning!!!']);
    end
end
        

% Parse tomogram output directories
n_binnings = numel(novactf.tomo_bin);
tomo_dir = cell(n_binnings,1);
for i = 1:n_binnings
    tomo_dir{i} = [p.root_dir,novactf.output_dir_prefix,'bin',num2str(novactf.tomo_bin(i)),'/'];
    % Check if directories exist
    if ~exist(tomo_dir{i},'dir')
        mkdir(tomo_dir{i});
    end    
end

% Check for center of mass file
if sg_check_param(novactf,'cen_mass_name')
    disp([p.name,'Center of mass file detected...']);
    novactf.cen_mass = dlmread(novactf.cen_mass_name);
end


%% Write directive file and preprocess for each tomogram

for i = 1:n_stacks
        
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
    elseif tomolist(i).tomo_recons
        if ~novactf.force_novactf
            process = false;
        end
    end
        
    
    % Check recons_list
    if exist('recons_list','var')
        if ~any(recons_list == tomolist(i).tomo_num)
            process = false;
        end
    end
    
    
    % Perform tomogram reconstruction with novaCTF
    if process        
        disp([p.name,'Preparing scripts for tomogram reconstruction using NovaCTF on ',tomolist(i).stack_name]);
        
        %%%%% PREPARE DEFOCUS FILES %%%%%
        
        % Parse stack name
        switch novactf.process_stack
            case 'unfiltered'
                stack_name = tomolist(i).stack_name;
            case 'dose-filtered'
                stack_name = tomolist(i).dose_filtered_stack_name;
            otherwise
                error([p.name,'ACHTUNG!!! ',novactf.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
        end
        [~,name,~] = fileparts(stack_name);

        
        
        % Initialize novaCTF directories
        tm_novactf_generate_directories(tomolist(i).stack_dir);

        
        % Parse alignment filenames
        switch tomolist(i).alignment_software
            case 'AreTomo'
                ali_dir = 'AreTomo/';                
            case 'imod'
                ali_dir = 'imod/';                
            otherwise
                error([p.name,'ACHTUNG!!! ',tomolist(i).alignment_software,' is unsupported!!!']);
        end
        tiltcom_name = [tomolist(i).stack_dir,ali_dir,'tilt.com'];
        tlt_name = [ali_dir,name,'.tlt'];
        xf_name = [ali_dir,name,'.xf'];
        efid_name = [ali_dir,name,'_erase.fid'];
        
        % Read tilt.com        
        tiltcom = tm_imod_parse_tiltcom(tiltcom_name);
        
        
        
        % Generate defocus files and determine number of stacks
        n_stacks = tm_novactf_generate_defocus_files(p,tomolist(i),novactf,dep,tiltcom,tlt_name);
        
        
        %%%%% PERFORM PARALLEL PROCESSING %%%%%
        
        % Generate parallel stack-processing scripts
        tm_novactf_generate_parallel_scripts(p,tomolist(i),novactf,dep,n_stacks,tiltcom,tlt_name,xf_name,efid_name);
        
        % Run parallel operations
        tm_novactf_run_parallel_scripts(p,tomolist,n_stacks);
        
        
        %%%%% PERFORM RECONSTRUCTION %%%%%
        
        % Generate script for tomogram reconstruction
        tm_novactf_generate_tomogram_runscript(tomolist(i),novactf,dep,n_stacks,tlt_name,tiltcom,tomo_dir);
               
        % Run novaCTF
        disp([p.name,'Running novaCTF on ',tomolist(i).stack_name,'...']);
        status = system([tomolist.stack_dir,'/novaCTF/run_novaCTF.sh']);
        if status ~= 0
            error(p.name,'ACHTUNG!!! novaCTF reconstruction failed!!!')
        end
        disp([p.name,'NovaCTF reconstruction of ',tomolist(i).stack_name,' complete!!!']);
        
        
        
        
        % Update tomolist
        tomolist(i).tomo_recons = true;
        tomolist(i).tomo_recons_algorithm = 'novaCTF';
        
        
        % Save tomolist
        if write_list
            save([p.root_dir,p.tomolist_name],'tomolist');
    
        end

    end 
end


