function tm_must_reconstruct(tomolist, p, must, dep)
%% tm_must_reconstruct
% A function to run MUST reconstruction. TOMOMAN wrapping provides extra
% parameters including tilt-series binning prior to reconstruction, gold
% bead erasing if an appropriate .fid is available, and additional tomogram
% binning after reconstruction. 
%
% NOTES: As of version 2.1.0, it appears that when MUST is operating on an
% unaligned stack, it doesn't crop to the original dimensions. As such,
% output dimensions are not known a prior, so TOMOMAN first generates an
% aligned stack. Binning within must sseems fine. 
%
% WW 08-2025

%% Initialize

% Number of stacks
n_stacks = numel(tomolist);

% Check for subset_listedit tm_imod_recon
if sg_check_param(must,'subset_list')
    subset_list = dlmread(tm_check_absolute_path(p.root_dir,must.subset_list));
else
    subset_list = [];
end

% Check binnings
must.tomo_bin = sort(must.tomo_bin);  % Resort to ensure order from lowest to highest binning        

% Parse tomogram output directories
n_binnings = numel(must.tomo_bin);
tomo_dir = cell(n_binnings,1);
for i = 1:n_binnings
    tomo_dir{i} = [p.root_dir,must.output_dir_prefix,'bin',num2str(must.tomo_bin(i)),'/'];
    % Check if directories exist
    if ~exist(tomo_dir{i},'dir')
        mkdir(tomo_dir{i});
    end    
end

% Fudge factor to wait for MUST output
wait_time = 10;

%% Write and run processing scripts for each tomogram

for i = 1:n_stacks
        
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false; 
        disp([p.name,tomolist(i).stack_name,' set to skip... Moving on to next stack...']);
    end
        
    % Check if aligned
    if ~tm_check_if_aligned(tomolist(i))
        process = false;
        disp([p.name,tomolist(i).stack_name,' has not been aligned... Moving on to next stack...']);
    end
    
    % Check subset_list
    if ~isempty(subset_list)
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
            disp([p.name,tomolist(i).stack_name,' is not in the subset_list... Moving on to next stack...']);
        end
    end
    
    
    % Reconstruct tomograms
    if process        
        disp([p.name,'Reconstructing ',tomolist(i).stack_name,' ...']);
        
        % Generate must directory
        stack_dir = tm_check_absolute_path(p.root_dir,tomolist(i).stack_dir);
        must_dir = [stack_dir,'MUST/'];
        system(['mkdir -p ',must_dir]);
        
        % Open run script
        run_name = [must_dir,'run_must.sh'];
        script = fopen(run_name,'w');
            
        % Write initial lines
        fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
        fprintf(script,['export CUDA_VISIBLE_DEVICES=',char(strjoin(string(must.gpu_id), ',')),'\n\n']);
        
        
        % Check stack type
        switch must.process_stack
            case 'unfiltered'
                stack_type = 'uf';
            case 'dose-filtered'
                stack_type = 'df';
        end
        
        % Parse stack basename
        switch stack_type(1:2)
            case 'df'
                [~,tomo_name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
            otherwise
                [~,tomo_name,~] = fileparts(tomolist(i).stack_name);
        end
        
        % Parse IMOD-formatted Alignment Filenames
        switch tomolist(i).alignment_software
            case 'AreTomo'
                subfolder = 'AreTomo/';
            case 'imod'
                subfolder = 'imod/';
            otherwise  % Assume IMOD
                subfolder = 'imod/';
        end
        % [~,name,~] = fileparts(t.dose_filtered_stack_name);         % Assume alignment using dose filtered stack
        tiltcom_name = [stack_dir,subfolder,'tilt.com'];
        tilt_name = [stack_dir,subfolder,tomo_name,'.tlt'];
        xf_name = [stack_dir,subfolder,tomo_name,'.xf'];
        
        % Load and parse tiltcom
        tiltcom = tm_imod_parse_tiltcom(tiltcom_name);
        
        % Parse defocus filename
        [~,stack_name,~] = fileparts(tomolist(i).stack_name);
        switch tomolist(i).ctf_determination_algorithm
            case 'ctffind4'
                defocus_name = [stack_dir,'ctffind4/diagnostic_',stack_name,'.txt'];
            case 'tiltctf'
                defocus_name = [stack_dir,'tiltctf/diagnostic_',stack_name,'.txt'];
            case 'sg_ctfrefine'
                defocus_name = [stack_dir,'sg_ctfrefine/diagnostic_',stack_name,'.txt'];
            case 'motioncor3'
                error([p.name,'ACHTUNG!!! MotionCor3 is currently unsupported...']);
%                 defocus_name = [stack_dir,'MotionCor3/ctfphaseflip_motioncor3.txt'];
            otherwise
                disp([p.name,'ACHTUNG!!! Unsupported ctf_determination_algorithm']);
        end
        % Strip comments from CTFFIND-formated file 
        system(['sed ''/^[[:blank:]]*#/d;s/#.*//'' ',defocus_name,' > ',must_dir,'defocus.txt']);
        
        % Generate aligned stack
        fprintf(script,['echo "##### Generating aligned stack... #####"','\n']);
        fprintf(script,'%s\n\n',[dep.newstack,' -in ',stack_dir,tomo_name,'.st -ou ',must_dir,tomo_name,'.ali -xform ',xf_name]);
        
        % Erase gold
        if sg_check_param(must,'erase_radius')
            efid_name = [tomolist(i).stack_dir,subfolder,tomo_name,'_erase.fid'];
            if exist(efid_name,'file')
                fprintf(script,['echo "TOMOMAN: Erasing gold beads in for',tomo_name,'..."\n']);
                fprintf(script,['ccderaser -input ',must_dir,tomo_name,'.ali ',...
                                '-output ',must_dir,tomo_name,'.ali ',...
                                '-mo ',efid_name,' ',...
                                '-be ',num2str(must.erase_radius),' ',...
                                '-or 0 -me -exc -c / ','\n\n']);
            end
        end
        
        % Generate micrograph list
        list_name = [tomo_name,'.list'];
        input_name = [tomo_name,'.ali'];
        fprintf(script,['echo "##### Generating input list... #####"','\n']);
        fprintf(script,'%s\n\n',[dep.generate_input_list_cpp,' --output ',must_dir,list_name,' --input ',must_dir,input_name,' --tilt ',tilt_name,' --defocus ',must_dir,'defocus.txt']);
        
        % Generate configuration files for each binning (MUST reconstruction is faster than Fourier3D binning...
        conf_name = cell(n_binnings,1);
        for j = 1:numel(must.tomo_bin)
            
            % Output tomogram name
            rec_name = [tomo_name,'_bin',num2str(must.tomo_bin(j)),'.rec'];
            
            % Open .conf file
            conf_name{j} = [must_dir,'must_bin',num2str(must.tomo_bin(j)),'.conf'];
            fid = fopen(conf_name{j},'w');
            
            % Basic Parameters
            fprintf(fid,'%s\n',['path=',must_dir]);
            fprintf(fid,'%s\n',['input_micrograph_list=',list_name]);
            fprintf(fid,'%s\n',['output_mrc=',rec_name]);
            fprintf(fid,'%s\n',['h=',num2str(floor(tiltcom.THICKNESS./must.tomo_bin(j)))]);
            fprintf(fid,'%s\n',['pixel_size=',num2str(tomolist(i).pixelsize.*must.tomo_bin(j))]);
            fprintf(fid,'%s\n',['j=',num2str(must.n_cores)]);
            
            % Parameters for CTF correction
            fprintf(fid,'%s\n',['skip_ctfcorrection=',num2str(must.skip_ctfcorrection)]);
            fprintf(fid,'%s\n',['ctf_deconvolve=',num2str(must.ctf_deconvolve)]);
            fprintf(fid,'%s\n',['ctf_phaseflip=',num2str(must.ctf_phaseflip)]);
            fprintf(fid,'%s\n',['ctfcorrection_3d=',num2str(must.ctfcorrection_3d)]);
            fprintf(fid,'%s\n',['Cs=',num2str(tomolist(i).ctf_parameters.cs)]);
            fprintf(fid,'%s\n',['voltage=',num2str(tomolist(i).voltage)]);
            fprintf(fid,'%s\n',['w=',num2str(tomolist(i).ctf_parameters.famp)]);
            
            % Advanced Parameters
            fprintf(fid,'%s\n',['h_offset=',num2str(tiltcom.SHIFT(2)./must.tomo_bin(j))]);
            fprintf(fid,'%s\n',['bin=',num2str(must.tomo_bin(j))]);
            if ~sg_check_param(must,'output_style')
                must.output_style = 1;  % Default setting
            end
            adv_param = {'output_style','output_style_para','tlt_offset',...
                         'it_sirt','padding','trimming','lp','h_padding',...
                         'N_block_fft','N_block_rec','N_block_linear_combination'};
            for k = 1:numel(adv_param)
                if sg_check_param(must,adv_param{k})
                    fprintf(fid,'%s\n',[adv_param{k},'=',num2str(must.(adv_param{k}))]);
                end
            end
            
            % Close .conf file
            fclose(fid);
            
            
            % Add to runscript
            fprintf(script,['echo "##### Run MUST Reconstruction at bin',num2str(must.tomo_bin(j)),' #####"','\n']);
            fprintf(script,'%s\n',[dep.must,' ',conf_name{j}]);
            
            % Move tomogram to final directory
%             fprintf(script,'%s\n',['until [ -f ',must_dir,rec_name,' ]']);
%             fprintf(script,'%s\n','do');
%             fprintf(script,'%s\n',['     sleep ',num2str(wait_time)]);
%             fprintf(script,'%s\n','done');
            fprintf(script,'%s\n\n',['mv ',must_dir,tomo_name,'_bin',num2str(must.tomo_bin(j)),'.rec ',tomo_dir{j},tomo_name,'.rec']);

        end
             
        
        
        % Cleanup and close
        fprintf(script,'%s\n',['rm -f ',must_dir,'*~ ',must_dir,'*.ali']);
        fclose(script);
        
        % Make exectuable and run
        system(['chmod +x ',run_name]);
        system(run_name);
            
       

    end 
    
%     % Save tomolist
%     if write_list
%         save([p.root_dir,p.tomolist_name],'tomolist');
% 
%     end
end

