function tomolist = tm_tiltctf_ctffind4(tomolist,p,tctf,ctffind4,dep,write_list)
%% tm_tiltctf_ctffind4
% A wrapper script for calculating a tiltctf power spectrum and determining
% the CTF parameters of that power spectrum using CTFFIND4.
%
% WW 06-2022

%% Initalize

% % Read lookup table
% [self_path,~,~] = fileparts(which('tm_tiltctf_ctffind4'));
% lut_name = [self_path,'tiltctf_lut.csv'];

% % Read motl (__UNDER_CONSTRUCTION__)
% motl = sg_motl_read(tctf.motl_name);

% % Check debug
% if tctf.visualdebug
%     ifvisualdebug = 1;
% else
%     ifvisualdebug = 0;
% end


%% Determine CTF Parameters
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
%     % Check for skip
%     if (tomolist(i).skip == false)
%         process = true;
%     else
%         process = false;
%     end
%     % Check for previous alignment
%     if (process == true) && (tomolist(i).ctf_determined == false)
%         process = true;
%     else
%         process = false;
%     end        
%     % Check for force
%     if (logical(tctf.force_run) == true) && (tomolist(i).skip == false)
%         process = true;
%     end
    
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
    elseif tomolist(i).ctf_determined
        if ~tctf.force_tiltctf
            process = false;
        end
    end
    
    if process                
        
        
        %%%%% Parse inputs %%%%%
        
        % Parse name of stack used for alignment
        switch tomolist(i).alignment_stack
            case 'unfiltered'
                process_stack = tomolist(i).stack_name;
            case 'dose-filtered'
                process_stack = tomolist(i).dose_filtered_stack_name;
            otherwise
                error([p.name,'ACTHUNG!!! Unsuppored stack!!! Only "unfiltered" and "dose-filtered" supported!!!']);
        end        
        [~,name,~] = fileparts(process_stack);
       

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

        
        % Parse xtilt        
        switch tomolist(i).alignment_software
            
            case 'AreTomo'
                % AreTomo doesn't solve for xtilt, so default is zero
                xtilt = 0;
            
            case 'imod'
                
                if tctf.use_xtilt

                    % Parse xtilt; I'm assuming that the tomopitch solution
                    % is a refined one, so that one is taken if available.
                    % -WW
                    tomopitchlog_name = [tomolist(i).stack_dir,'imod/tomopitch.log'];
                    if exist(tomopitchlog_name,'file')
                        % Parse and store value
                        tomopitchlog = tm_imod_parse_tomopitchlog(tomopitchlog_name);
                        xtilt = tomopitchlog.XAXISTILT;
                    else
                       tiltcom = tm_imod_parse_tiltcom([tomolist(i).stack_dir,'imod/tilt.com']); 
                       xtilt =  tiltcom.XAXISTILT;
                    end
                    
                else
                    xtilt = 0;
                end
        end
        
        
        
        
        
        % Calculate power spectrum
        if tctf.calc_ps
%             tomoman_tiltctf_calculate_powerspectrum(tomolist(i).stack_dir,...
%                 tomolist(i).stack_name,output_name,...
%                 tomolist(i).target_defocus,tomolist(i).pixelsize,...
%                 xf_name,tlt_name,lut,tctf.ps_size,tctf.def_tol,...
%                 tctf.fscaling,tctf.write_unstretched,tctf.write_negative,ifvisualdebug,tctf.xtiltoption);
                        
            % Write tiltctf-ps param file
            [tiltctf_paramfilename, ps_name] = tm_tiltctf_write_ps_param(tomolist(i),tctf,xtilt);
            
            % Calculate PS
            tm_tiltctf_calculate_ps(p,tiltctf_paramfilename);
           
        else
            ps_name = [tomolist(i).stack_dir,'tiltctf/',name,'_tiltctf_ps.mrc'];
        end
        
        % Update CTFFIND parameters for stack
        ctffind4 = tm_ctffind4_check_params(ctffind4,tomolist(i));
        ctffind4.pixelsize = tomolist.pixelsize*tctf.fscaling;
%         temp_ctffind = tm_tiltctf_update_ctffind_param_for_stack(tomolist(i),tctf,ctffind4);

        % Array to store CTFFIND fits
        if sg_check_param(tctf,'write_unstretched') && sg_check_param(tctf,'write_negative')
            fit_array = cell(3,1);
        elseif sg_check_param(tctf,'write_unstretched') || sg_check_param(tctf,'write_negative')
            fit_array = cell(2,1);
        else
            fit_array = cell(1,1);            
        end        
        
        
        
        % Generate diagnostic name
        [~,psname,~] = fileparts(ps_name);
        diag_name = [tomolist(i).stack_dir,'tiltctf/diagnostic_',psname,'.mrc'];
        
        % Run CTFFIND4
        tm_tiltctf_run_ctffind_stack(tomolist(i),ps_name,ctffind4,diag_name,dep);
        
        % Store results
        fit_array{1} = tm_read_ctffind4([tomolist(i).stack_dir,'/tiltctf/diagnostic_',psname,'.txt']);
        
        
        
        % Negative stack
        if sg_check_param(tctf,'write_negative')
                     
            % Parse names
            n_ps_name = [tomolist(i).stack_dir,'tiltctf/',name,'_tiltctf_ps_negative.mrc'];
            n_diag_name = [tomolist(i).stack_dir,'tiltctf/diagnostic_',psname,'_negative.mrc'];
            n_results_name = [tomolist(i).stack_dir,'tiltctf/diagnostic_',psname,'_negative.txt'];
                        
            % Run CTFFIND4
            tm_tiltctf_run_ctffind_stack(tomolist(i),n_ps_name,ctffind4,n_diag_name,dep);

            % Store results
            fit_array{2} = tm_read_ctffind4(n_results_name);
        end
        
        
        
        % Unstretched stack
        if sg_check_param(tctf,'write_unstretched')
            
            % Parse names
            u_ps_name = [tomolist(i).stack_dir,'tiltctf/',name,'_tiltctf_ps_unstretched.mrc'];
            u_diag_name = [tomolist(i).stack_dir,'tiltctf/diagnostic_',psname,'_unstretched.mrc'];
            u_results_name = [tomolist(i).stack_dir,'tiltctf/diagnostic_',psname,'_unstretched.txt'];
      
            % Run CTFFIND4
            tm_tiltctf_run_ctffind_stack(tomolist(i),u_ps_name,ctffind4,u_diag_name,dep);

            % Store results
            fit_array{3} = tm_read_ctffind4(u_results_name);
        end
        
        
        
        % Check highest CC scores
        n_tilts = numel(fit_array{1});
        if ~sg_check_param(tctf,'write_unstretched') && ~sg_check_param(tctf,'write_negative')
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
            
            % Display best fit
            switch max_idx
                case 1
                    disp([p.name,'Best fit  for ',process_stack,' was from the positively stretched power-spectrum!']);
                case 2
                    disp([p.name,'Best fit  for ',process_stack,' was from the negatively stretched power-spectrum!']);
                case 3
                    disp([p.name,'Best fit  for ',process_stack,' was from the unstretched power-spectrum!']);
            end
        
        end
        
        
            
        % Check for phase shift
        if strcmp(ctffind4.det_pshift,'no')
            fit_array{max_idx} = rmfield(fit_array{max_idx},'pshift');
        end
        
        % Fix units
        for j = 1:n_tilts
            fit_array{max_idx}(j).defocus_1 = fit_array{max_idx}(j).defocus_1/10000;
            fit_array{max_idx}(j).defocus_2 = fit_array{max_idx}(j).defocus_2/10000;
        end
                
        % Update tomolist
        tomolist(i).ctf_determined = true;
        ctf_determination_method = 'tiltctf';
        tomolist(i).ctf_parameters = struct('cs',ctffind4.cs,'famp',ctffind4.famp);
        tomolist(i) = tm_tiltctf_store_ctf_param(tomolist(i),fit_array{max_idx},ctf_determination_method);
        
        % Write output ctfphaseflip file
        tm_write_ctfphaseflip(tomolist(i),'tiltctf');
        
        % Save tomolist
        if write_list
            save([p.root_dir,tomolist_name],'tomolist');
        end
        
        
        
        disp([p.name,'Defocus determination of stack "',tomolist(i).stack_name,'" complete!!!']);
        
        
    end
end

end




        




