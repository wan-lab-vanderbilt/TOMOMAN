function tomolist = tm_aretomo(tomolist,p,are,dep,write_list)
%% tm_aretomo
% Wrapper function to run AreTomo. 
%
% WW 05-2022

%% Check for input AreTomo list

% Check for aretomo_list
if sg_check_param(are,'aretomo_list')
    % Read aretomo list
    aretomo_list = dlmread(are.aretomo_list);
    
    % Per-tomo parameter flag
    per_tomo = true;
    
else
    % No per-tomo parameters
    per_tomo = false;
end


%% Align with AreTomo
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
    elseif tomolist(i).stack_aligned
        if ~are.force_align
            process = false;
        end
    end
    
    
    % Check aretomo_list
    if per_tomo
        
        % Look for tomo_num
        alist_idx = find(aretomo_list(:,1) == tomolist(i).tomo_num);
        
        % If alist_idx ~= 1
        if numel(alist_idx) > 1
            error([p.name,'ACHTUNG!!! Multiple entries for tomo_num ',num2str(tomolist(i).tomo_num),' in aretomo_list!!!']);
        elseif isempty(alist_idx)
            process = false;
        end
    end
    
    
    % Process 
    if process        
        disp(['TOMOMAN: Running AreTomo on stack: ',tomolist(i).stack_name]);
        
        % Parse stack name
        switch are.process_stack
            case 'unfiltered'
                stack_name = tomolist(i).stack_name;
            case 'dose-filtered'
                stack_name = tomolist(i).dose_filtered_stack_name;
            otherwise
                error(['TOMOMAN: ACHTUNG!!! ',are.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
        end
        [~,name,ext] = fileparts(stack_name);
        
        
        
        % Initialize processing script
        if exist([tomolist(i).stack_dir,'AreTomo/'],'dir')
            system(['rm -rf ',tomolist(i).stack_dir,'AreTomo/']);
        end
        mkdir([tomolist(i).stack_dir,'AreTomo/']);
        script_name = [tomolist(i).stack_dir,'AreTomo/run_aretomo.sh'];
        fid = fopen(script_name,'w');
        fprintf(fid,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
        fprintf(fid,'# Aligning tilt-series using AreTomo \n\n');
        
        
        
        % Check for input stack binning
        if are.InBin > 1
            
            % Parse binned stack name
            InMrc_name = [tomolist(i).stack_dir,'AreTomo/',name,'_bin',num2str(are.InBin),ext];
            
            % Bin stack
            fprintf(fid,['# Fourier crop aligned stack','\n']);
            fprintf(fid,['newstack -InputFile ',tomolist(i).stack_dir,stack_name,' ',...
                             ' -OutputFile ',InMrc_name,' ',...
                             ' -FourierReduceByFactor ', num2str(are.InBin),'\n\n']);
                         
        else
            
            % Parse input stack name
            InMrc_name = [tomolist(i).stack_dir,stack_name];
            
        end

        
        % Check output directory
        if ~exist([p.root_dir,are.out_dir],'dir')
            mkdir([p.root_dir,are.out_dir])
        end
            
        % Output tomogram name
        vol_name = [name,'_bin',num2str(are.OutBin),'.mrc'];
        OutMrc_name = [tomolist(i).stack_dir,'AreTomo/',vol_name];
                
        % AngleFile
        tlt_name = [tomolist(i).stack_dir,name,'.rawtlt'];

        
        % Check for per-tomo parameters
        if per_tomo
            
            % Check for AlignZ
            if size(aretomo_list,2) > 1
                if aretomo_list(alist_idx,2) == 0
                    warning([p.name,'ACHTUNG!!! AlignZ for tomo_num ',num2str(tomolist(i).tomo_num),' is set to zero!!! Using value from parameter file...']);
                else
                    alignZ = aretomo_list(alist_idx,2);                
                end
            end
            
            % Check for VolZ
            if size(aretomo_list,2) > 2
                if aretomo_list(alist_idx,3) == 0
                    warning([p.name,'ACHTUNG!!! VolZ for tomo_num ',num2str(tomolist(i).tomo_num),' is set to zero!!! Using value from parameter file...']);
                else
                    volZ = aretomo_list(alist_idx,3);                
                end
            else
                volZ = are.VolZ;
            end
        else
            % Copy binned AlignZ and VolZ
            alignZ = are.AlignZ;
            volZ = are.VolZ;
        end
        
        
        % Write AreTomo lines
        fprintf(fid,['# Run AreTomo','\n']);
        fprintf(fid,[dep.aretomo,' -InMrc ' , InMrc_name,...
                                 ' -OutMrc ', OutMrc_name,...
                                 ' -AngFile ', tlt_name,...
                                 ' -AlignZ ', num2str(alignZ/are.InBin),...
                                 ' -VolZ ', num2str(volZ/are.InBin),...                                 
                                 ' -Wbp ', num2str(are.Wbp),...
                                 ' -Outbin ',num2str(are.OutBin/are.InBin),...
                                 ' -TiltCor ',num2str(are.TiltCor),...
                                 ' -TiltAxis ',num2str(tomolist(i).tilt_axis_angle),...
                                 ' -OutXF ', num2str(are.OutXF),...
                                 ' -OutImod ', num2str(are.OutImod),...
                                 ' -Gpu ', num2str(are.Gpu)]);
%                                  ' -Gpu 0']);
         if ~isempty(are.Sart)
             fprintf(fid,[' -Sart ',num2str(are.Sart,'%5.2f,%-5.2f')]);
         end
         if ~isempty(are.Roi)
             fprintf(fid,[' -Roi ',num2str(are.Roi,'%5.2f,%-5.2f')]);
         end
         if ~isempty(are.Patch)
             fprintf(fid,[' -Patch ',num2str(are.Patch,'%5.2f,%-5.2f')]);
         end
         if ~isempty(are.DarkTol)
             fprintf(fid,[' -DarkTol ',num2str(are.DarkTol)]);
         end
         fprintf(fid,'\n\n');
        
%         % Write aligned stack
%         ali_name = [tomolist(i).stack_dir,'AreTomo/',name,'_bin',num2str(are.OutBin),'.ali'];
%         fprintf(fid,[dep.aretomo,' -InMrc ' , InMrc_name,...
%                                  ' -OutMrc ', ali_name,...
%                                  ' -AlnFile ', [InMrc_name,'.aln'],...
%                                  ' -Align 0 -VolZ 0 ',...                                 
%                                  ' -Gpu ', num2str(are.Gpu)]);
        fprintf(fid,'\n\n');
        
        % Check for IMOD output
        if are.OutImod
            
            % Directory of -OutImod outputs
            aretomo_dir = [tomolist(i).stack_dir,'AreTomo/'];
            
            % Rotate volume
%             fprintf(fid,[dep.clip,' flipyz ',imod_dir,'tomogram.mrc ',imod_dir,'tomogram.mrc','\n\n']);
%             fprintf(fid,[dep.clip,' rotx ',imod_dir,'tomogram.mrc ',imod_dir,'tomogram.mrc','\n\n']);   % For Aretomo > ver 1
            fprintf(fid,[dep.clip,' rotx ',aretomo_dir,vol_name,' ',aretomo_dir,vol_name,'\n\n']);   % For Aretomo > ver 1

            % Cleanup
            fprintf(fid,['rm -f ',tomolist(i).stack_dir,'AreTomo/*~ \n\n']);
            fprintf(fid,['rm -f ',aretomo_dir,'*~ \n\n']);

            % Move final tomogram
            fprintf(fid,['mv ',aretomo_dir,vol_name,' ',p.root_dir,are.out_dir,vol_name]);
            
        else
            
            % Rotate volume
            fprintf(fid,[dep.clip,' flipyz ',OutMrc_name, ' ', OutMrc_name,'\n\n']);

            % Cleanup
            fprintf(fid,['rm -f ',tomolist(i).stack_dir,'AreTomo/*~ \n\n']);

            % Move final tomogram
            fprintf(fid,['mv ',OutMrc_name,' ',p.root_dir,are.out_dir]);
            
        end        
        
        fclose(fid);
        
        % Run script
        system(['chmod +x ',script_name]);
        system(script_name);
        
        % Convert outputs to IMOD format
        tm_aretomo2imod(tomolist(i),are,volZ);
        
        
        % Check for aligned stack output
        if are.write_ali_stack
            
            % Open aligned stack script
            script_name = [tomolist(i).stack_dir,'AreTomo/run_ali_stack.sh'];
            fid = fopen(script_name,'w');
            fprintf(fid,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
           
            % Check output directory
            if ~exist([p.root_dir,are.ali_stack_dir],'dir')
                mkdir([p.root_dir,are.ali_stack_dir])
            end

            % Output aligned stack name
            ali_name = [name,'_bin',num2str(are.ali_stack_binning),'.ali'];
            
            % Parse xf file name
            xf_name = [tomolist(i).stack_dir,'AreTomo/',name,'.xf'];
            
            % Read tilt.com
            tiltcom_name = [tomolist(i).stack_dir,'AreTomo/','tilt.com'];
            tiltcom = sg_read_IMOD_tiltcom(tiltcom_name);
            
            % Write newstack lines
            fprintf(fid,['# Generate aligned stack with Newstack','\n']);
            fprintf(fid,[dep.newstack,' -InputFile ' , tomolist(i).stack_dir,stack_name,...
                                      ' -OutputFile ', p.root_dir, are.ali_stack_dir, ali_name,...
                                      ' -xform ', xf_name,...
                                      ' -ShrinkByFactor ', num2str(are.ali_stack_binning),...
                                      ' -si ',num2str(round_to_even(tiltcom.FULLIMAGE(1)/are.ali_stack_binning)),',',num2str(round_to_even(tiltcom.FULLIMAGE(2)/are.ali_stack_binning)),'\n\n']);
                                     
            fclose(fid);
            
            % Run script
            system(['chmod +x ',script_name]);
            system(script_name);

        end
        
        % Update tomolist
        tomolist(i).stack_aligned = true;
        tomolist(i).alignment_stack = are.process_stack;
        tomolist(i).alignment_software = 'AreTomo';
        
        
        
        % Save tomolist
        if write_list
            save([p.root_dir,p.tomolist_name],'tomolist');
        end
        
              
    end
    
end

