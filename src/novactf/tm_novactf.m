function tomolist = tm_novactf(tomolist, p, novactf, dep, write_list)
%% tm_novactf
% A function for taking a tomolist and running batched initial IMOD 
% preprocessing.
%
% WW 12-2017


%% Initialize

% Number of stacks
n_stacks = numel(tomolist);

% Check for subset_list
if ~isempty(novactf.subset_list)
    subset_list = dlmread(novactf.subset_list);
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
        disp([p.name,tomolist(i).stack_name,' set to skip... Moving on to next stack...']);
    elseif tomolist(i).tomo_recons
        if ~novactf.force_novactf
            process = false;
            disp([p.name,tomolist(i).stack_name,' has already been reconstructed... Moving on to next stack...']);
        end
    end
    
    % Check if aligned
    if ~tm_check_if_aligned(tomolist(i))
        process = false;
        disp([p.name,tomolist(i).stack_name,' has not been aligned... Moving on to next stack...']);
    end
    
    % Check subset_list
    if exist('subset_list','var')
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
            disp([p.name,tomolist(i).stack_name,' is not in the subset_list... Moving on to next stack...']);
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
                if startsWith(tomolist(i).alignment_software,'sg_refine_')
                    ali_dir = [tomolist(i).alignment_software,'/'];
                else
                    error(['ACHTUNG !!! ',tomolist(i).alignment_software,' is an unsupported alignment_software type!!!']);
                end
        end
        tiltcom_name = [tomolist(i).stack_dir,ali_dir,'tilt.com'];
        tlt_name = [ali_dir,name,'.tlt'];
        efid_name = [ali_dir,name,'_erase.fid'];
        
        % Check for xf file bining
        if novactf.ali_stack_bin > 1
            % Read xf
            xf = dlmread([tomolist(i).stack_dir,ali_dir,name,'.xf']);
            
            % Bin shifts
            xf(:,5:6) = xf(:,5:6)./novactf.ali_stack_bin;
            
            % Parse name to novaCTF folder and save
            xf_name = ['novaCTF/',name,'_bin',num2str(novactf.ali_stack_bin),'.xf'];
            dlmwrite([tomolist(i).stack_dir,xf_name],xf,' ');
            
        else
            
            % Parse name from alignment folder
            xf_name = [ali_dir,name,'.xf'];

        end
        
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
        tm_novactf_generate_tomogram_runscript(tomolist(i),novactf,dep,tlt_name,tiltcom,tomo_dir);
               
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
            tm_save_tomolist(p.root_dir,p.tomolist_name,tomolist);
    
        end

    end 
end


