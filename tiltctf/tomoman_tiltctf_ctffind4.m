function tomolist = tomoman_tiltctf_ctffind4(tomolist,p,tctf,ctffind,write_list)
%% tomoman_tiltctf_ctffind4
% A wrapper script for calculating a tiltctf power spectrum and determining
% the CTF parameters of that power spectrum using CTFFIND4.
%
% WW 08-2018


%% Check check!!!
if (nargin < 4)
    error('ACHTUNG!!! Incorrect number of inputs!!!');
end

%% Initalize

% Read lookup table
lut_path = which('tiltctf_lut.csv');
lut = csvread(lut_path);

% Parse tiltctf parameters
tctf = tomoman_tiltctf_parser(tctf);

% Parse CTFFIND4 parameters
ctffind = tomoman_ctffind4_parser(ctffind);

% Check whether to use GPU and set the GPU device
if tctf.ifgpu
 gpuDevice(tctf.gpudevice);
end

% % Read motl (__UNDER_CONSTRUCTION__)
% motl = sg_motl_read(tctf.motl_name);

if logical(tctf.visualdebug) == true
    ifvisualdebug = 1;
else
    ifvisualdebug = 0;
end

%% Determine CTF Parameters
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
    if (logical(tctf.force_run) == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    if process                
        
        % Parse imod name
        switch tctf.imod_stack
            case 'unfiltered'
                imod_name = tomolist(i).stack_name;
            case 'dose_filt'
                imod_name = tomolist(i).dose_filtered_stack_name;
            otherwise
                error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
        end
        
        
        [dir,name,~] = fileparts(imod_name);
        if ~isempty(dir)
            dir = [dir,'/']; %#ok<AGROW>
        end
        
        % IMOD files
        xf_name = [dir,name,'.xf'];
        tlt_name = [dir,name,'.tlt'];
        
        % Check tiltctf folder
        if tctf.calc_ps
            if exist([tomolist(i).stack_dir,'/tiltctf/'],'dir')
                system(['rm -rf ',tomolist(i).stack_dir,'/tiltctf/']);
            end
            mkdir([tomolist(i).stack_dir,'/tiltctf/']);
        end
        
        
%         %particle based sample geometry (__UNDER_CONSTRUCTION__)
%         
%         % Parse particle coordinates for current tomogram
%         tomo_idx = [motl.tomo_num] == tomolist(i).tomo_num;
%         n_motls = sum(tomo_idx);
% 
%         % Parse tomogram motl
%         tomo_motl = allmotl(tomo_idx);
%         pos = zeros(3,n_motls);
%         n_particle = size(pos,2);
%         pos(1,:) = [tomo_motl.orig_x] + [tomo_motl.x_shift];
%         pos(2,:) = [tomo_motl.orig_y] + [tomo_motl.y_shift];
%         pos(3,:) = [tomo_motl.orig_z] + [tomo_motl.z_shift];

        
        
        % Output name        
        output_name = ['tiltctf/tiltctf-ps_',num2str(tomolist(i).tomo_num),'.mrc'];
        
        
        % Calculate power spectrum
        if tctf.calc_ps
            tomoman_tiltctf_calculate_powerspectrum(tomolist(i).stack_dir,...
                tomolist(i).stack_name,output_name,...
                tomolist(i).target_defocus,tomolist(i).pixelsize,...
                xf_name,tlt_name,lut,tctf.ps_size,tctf.def_tol,...
                tctf.fscaling,tctf.write_unstretched,tctf.write_negative,ifvisualdebug,tctf.xtiltoption,tctf.invert_tiltangle_sign,tctf.ifgpu);
        end
        
        % Update CTFFIND parameters for stack
        temp_ctffind = tomoman_tiltctf_update_ctffind_param_for_stack(tomolist(i),tctf,ctffind);

        % Array to store CTFFIND fits
        if tctf.write_negative && tctf.write_unstretched
            fit_array = cell(3,1);
        elseif tctf.write_negative || tctf.write_unstretched
            fit_array = cell(2,1);
        else
            fit_array = cell(1,1);            
        end        
        
        
        
        % Generate diagnostic name
        [psdir,psname,~] = fileparts(output_name);
        if ~isempty(psdir)
            psdir = [psdir,'/']; %#ok<AGROW>
        end
        diag_name = [tomolist(i).stack_dir,psdir,'diagnostic_',psname,'.mrc'];
        
        % Run CTFFIND4
        tomoman_tiltctf_run_ctffind_stack(tomolist(i),output_name,temp_ctffind,diag_name);
        fit_array{1} = tomoman_read_ctffind4([tomolist(i).stack_dir,'/',psdir,'diagnostic_',psname,'.txt']);
        
        
        
        % Negative stack
        if tctf.write_negative
            n_output_name = ['tiltctf/tiltctf-ps_',num2str(tomolist(i).tomo_num),'_negative.mrc'];
            [n_psdir,n_psname,~] = fileparts(n_output_name);
            if ~isempty(n_psdir)
                n_psdir = [n_psdir,'/']; %#ok<AGROW>
            end
            n_diag_name = [tomolist(i).stack_dir,n_psdir,'diagnostic_',n_psname,'.mrc'];
            tomoman_tiltctf_run_ctffind_stack(tomolist(i),n_output_name,temp_ctffind,n_diag_name);
            fit_array{2} = tomoman_read_ctffind4([tomolist(i).stack_dir,'/',n_psdir,'diagnostic_',n_psname,'.txt']);
        end
        
        
        
        % Unstretched stack
        if tctf.write_negative
            u_output_name = ['tiltctf/tiltctf-ps_',num2str(tomolist(i).tomo_num),'_unstretched.mrc'];
            [u_psdir,u_psname,~] = fileparts(u_output_name);
            if ~isempty(u_psdir)
                u_psdir = [u_psdir,'/']; %#ok<AGROW>
            end
            u_diag_name = [tomolist(i).stack_dir,u_psdir,'diagnostic_',u_psname,'.mrc'];
            tomoman_tiltctf_run_ctffind_stack(tomolist(i),u_output_name,temp_ctffind,u_diag_name);
            fit_array{end} = tomoman_read_ctffind4([tomolist(i).stack_dir,'/',u_psdir,'diagnostic_',u_psname,'.txt']);
        end
        
        
        
        % Check CC scores and convert optimal to ctfphaseflip format
        n_tilts = numel(fit_array{1});
        if ~tctf.write_negative && ~tctf.write_unstretched
            max_idx = 1;
        else
            % Concatenate CC values
            cc_array = zeros(n_tilts,numel(fit_array));
            for j = 1:numel(fit_array)
                cc_array(:,j) = [fit_array{j}.cc];
            end
            % Find array with top CC values
            max_array = zeros(n_tilts,1);
            for j = 1:n_tilts
                [~,max_array(j)] = max(cc_array(j,:));
            end
            max_idx = mode(max_array);
        end
        
        % Display best fit
        switch max_idx
            case 1
                disp(['Best fit  for tomogram ',num2str(tomolist(i).tomo_num),' was from the positively stretched power-spectrum!']);
            case 2
                if tctf.write_negative
                    disp(['Best fit  for tomogram ',num2str(tomolist(i).tomo_num),' was from the negatively stretched power-spectrum!']);
                else
                    disp(['Best fit  for tomogram ',num2str(tomolist(i).tomo_num),' was from the unstretched power-spectrum!']);
                end
            case 3
                disp(['Best fit  for tomogram ',num2str(tomolist(i).tomo_num),' was from the unstretched power-spectrum!']);
        end
            
        % Check for phase shift
        if strcmp(temp_ctffind.det_pshift,'no')
            fit_array{max_idx} = rmfield(fit_array{max_idx},'pshift');
        end
        
        % Fix units
        for j = 1:n_tilts
            fit_array{max_idx}(j).defocus_1 = fit_array{max_idx}(j).defocus_1/10000;
            fit_array{max_idx}(j).defocus_2 = fit_array{max_idx}(j).defocus_2/10000;
        end
        
        % Update tomolist
        tomolist(i).ctf_determined = true;
        switch tctf.imod_stack
            case 'unfiltered'
                tomolist(i) = tomoman_tiltctf_store_ctf_param(tomolist(i),fit_array{max_idx},'TILTCTF-unfiltered');
            case 'dose_filt'
                tomolist(i) = tomoman_tiltctf_store_ctf_param(tomolist(i),fit_array{max_idx},'TILTCTF-dose_filt');
        end
                
        % Save tomolist
        if write_list
            save([p.root_dir,tomolist_name],'tomolist');
        end
        
        % Write file
        tomoman_write_ctfphaseflip(tomolist(i),tctf.imod_stack);
        
        disp(['TOMOMAN: Defocus determination of stack "',tomolist(i).stack_name,'" complete!!!']);
        
        
    end
end

end




        




