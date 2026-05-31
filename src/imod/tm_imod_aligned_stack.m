function tm_imod_aligned_stack(tomolist, p, imod)
%% tm_imod_aligned_stack
% Batch generation of aligned stacks using IMOD. 
%
% WW 10-2025


%% Initialize

% Number of stacks
n_stacks = numel(tomolist);

% Check for subset_list
if sg_check_param(imod,'subset_list')
    subset_list = dlmread(tm_check_absolute_path(p.root_dir,imod.subset_list));
else
    subset_list = [];
end

% Check for output directory
output_dir = [p.root_dir,imod.output_dir];
if ~exist(output_dir,'dir')
    system(['mkdir -p ',output_dir]);
end

%% Write directive file and preprocess for each tomogram

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
    
    
    % Generate aligned stacks
    if process        
        disp([p.name,'Generating aligned stack for ',tomolist(i).stack_name,' ...']);
        
        %%%%% Initialize parameters %%%%%
        
        % Initialize temporary directory
        temp_dir = [tomolist(i).stack_dir,'imod_aligned_stack/'];
        if ~exist(temp_dir,'dir')
            system(['mkdir -p ',temp_dir]);
        end
        

        % Parse name of stack used for tilt series alignment
        switch tomolist(i).alignment_stack
            case 'unfiltered'
                stack_name = tomolist(i).stack_name;
            case 'dose-filtered'
                stack_name = tomolist(i).dose_filtered_stack_name;
        end
        [~,name,~] = fileparts(stack_name);

        % Parse alignment subfolder by software
        switch tomolist(i).alignment_software
            case 'AreTomo'
                ali_dir = 'AreTomo/';                
            case 'imod'
                ali_dir = 'imod/';                
            otherwise
                if startsWith(t.alignment_software,'sg_refine_')
                    ali_dir = [t.alignment_software,'/'];
                else
                    error(['ACHTUNG !!! ',t.alignment_software,' is an unsupported alignment_software type!!!']);
                end
        end
        

        % Parse name of .xf file 
        xf_name = [tomolist(i).stack_dir,ali_dir,name,'.xf'];
        
        % Parse name of stack for processing
        switch imod.process_stack
            case 'unfiltered'
                input_stack = [tomolist(i).stack_dir,tomolist(i).stack_name];
            case 'dose-filtered'
                input_stack = [tomolist(i).stack_dir,tomolist(i).dose_filtered_stack_name];
            otherwise
                error([p.name,'ACHTUNG!!! ',process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
        end
               
        
        % Parse name and read tiltcom
        tiltcom_name = [tomolist(i).stack_dir,ali_dir,'tilt.com'];
        tiltcom = sg_read_IMOD_tiltcom(tiltcom_name);                   % We use the tilt.com because it contains the final dimensions of the tomogram; this accounts for isues with image rotations

        
        % Parse name of output stack
        [~,oname,~] = fileparts(input_stack);
        output_stack = [temp_dir,oname,'.ali'];                 % Temporary stack
        final_output_stack = [output_dir,oname,'.ali'];    % Final output stack location
        
        
        
        %%%%% Write Processing Script %%%%%
        
        % Open reconstruction script
        script_name = [temp_dir,'/imod_aligned_stack.sh'];
        script = fopen(script_name,'w');

        % Write initial lines
        fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
        fprintf(script,['echo "##### Processing stack ',oname,' #####"','\n\n\n']);


        %%%%% Prepare aligned stack %%%%%
        
        % Generate aligned stack
        fprintf(script,['echo "TOMOMAN: Generating aligned stack for ',oname,'..."\n']);
        fprintf(script,['newstack -in ',input_stack,' ',...
                        '-ou ',output_stack,' ',...
                        '-xform ',xf_name,' ',...
                        '-si ',num2str(tiltcom.FULLIMAGE(1)),',',num2str(tiltcom.FULLIMAGE(2)),' ',...
                        '-or -ta 1,0 \n\n']);
                    
        % Erase gold
        if sg_check_param(imod,'erase_radius')
            efid_name = [tomolist(i).stack_dir,ali_dir,name,'_erase.fid'];
            if exist(efid_name,'file')
                fprintf(script,['echo "TOMOMAN: Erasing gold beads in for',oname,'..."\n']);
                fprintf(script,['ccderaser -input ',output_stack,' ',...
                                '-output ',output_stack,' ',...
                                '-mo ',efid_name,' ',...
                                '-be ',num2str(imod.erase_radius),' ',...
                                '-or 0 -me -exc -c / ','\n\n']);
            end
        end
        
        % CTF correction
        if sg_check_param(imod,'ctfphaseflip')

            % Parse defocus file name
            ctfphaseflipname = tm_get_ctfphaseflip_filename(p,tomolist(i));
            
            % Parse tlt file name
            tlt_name = [tomolist(i).stack_dir,ali_dir,name,'.tlt'];

            % Check default parameters
            if ~sg_check_param(imod,'deftolerance')
                imod.deftolerance = 25;
            end
            if ~sg_check_param(imod,'interwidth')
                imod.interwidth = 4;
            end
            if ~sg_check_param(imod,'maxwidth')
                imod.maxwidth = 1024;
            end

            % Write ctfphaseflip command
            fprintf(script,['echo "TOMOMAN: Running CTFphaseflip on ',oname,'..."\n']);
            fprintf(script,['ctfphaseflip -input ',output_stack,' ',...
                            '-output ',output_stack,' ',...
                            '-angleFn ',tlt_name,' ',...
                            '-defFn ',ctfphaseflipname,' ',...
                            '-defTol ',num2str(imod.deftolerance),' ',...
                            '-iWidth ',num2str(imod.interwidth),' ',...
                            '-maxWidth ',num2str(imod.maxwidth),' ',...
                            '-pixelSize ',num2str(tomolist(i).pixelsize),' ',...
                            '-volt ',num2str(tomolist(i).voltage),' ',...
                            '-cs ',num2str(tomolist(i).ctf_parameters.cs),' ',...
                            '-ampContrast ',num2str(tomolist(i).ctf_parameters.famp),' ']);
            if sg_check_param(imod,'gpu_id')
                fprintf(script,['-gpu ',num2str(imod.gpu_id)]);
            end
            fprintf(script,'\n\n');
        %     if copy_headers == 1
        %         fprintf(script_output,['copyheader ',st_dir,'/',st_name,'_ctfcorr.ali ',st_dir,'/headers/',st_name,'_ctfcorr.ali.header','\n']);
        %     end
        end
        
        
        % Bin stack
        if imod.ali_stack_bin > 1
            fprintf(script,['echo "TOMOMAN: Fourier cropping ',oname,' at binning factor ',num2str(imod.ali_stack_bin),'..."\n']);
            fprintf(script,['newstack -InputFile ',output_stack,' ',...
                                    ' -OutputFile ',output_stack,' ',...
                                    ' -FourierReduceByFactor ', num2str(imod.ali_stack_bin),'\n\n']);
        end
        
        % Move stack and cleanup
        fprintf(script,['mv ',output_stack,' ',final_output_stack,' \n\n']);
        fprintf(script,['rm ',temp_dir,'*~']);
        fclose(script);
        
        % Run script
        system(['chmod +x ',script_name]);
        system(script_name);


    end 

end


