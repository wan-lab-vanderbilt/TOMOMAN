function tomolist = tomoman_gctf(tomolist, p, gctf_param, write_list)
%% tomoman_gctf
% A function for taking a tomolist and running GCTF. GCTF is run by first
% splitting the non-dose-filtered stack, running GCTF, and contenating the
% results. The results are also converted into IMOD/ctfphaseflip format.
% 
% WW 12-2017


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
    if (logical(gctf_param.force_gctf) == true) && (tomolist(i).skip == false)
        process = true;
    end
    
    if process
        disp(['TOMOMAN: Determining defocus of stack ',tomolist(i).stack_name,' with GCTF!!!']);

        % Parse stack name
        [~,st_name,st_ext] = fileparts(tomolist(i).stack_name);

        % Make GCTF folder
        if ~exist([tomolist(i).stack_dir,'/gctf/'],'dir')
            mkdir([tomolist(i).stack_dir,'/gctf/']);
            mkdir([tomolist(i).stack_dir,'/gctf/temp/']);
        elseif ~exist([tomolist(i).stack_dir,'/gctf/temp/'],'dir')
            mkdir([tomolist(i).stack_dir,'/gctf/temp/']);
        end

        % Parse parameters
        gctf_param.apix = tomolist(i).pixelsize;
        param_str = tomoman_gctf_parser(gctf_param);

        
        % Defocus options
        defL = (tomolist(i).target_defocus(1)*-10000)-gctf_param.defWidth;
        defH = (tomolist(i).target_defocus(1)*-10000)+gctf_param.defWidth;
        def_param = [' --defL ',num2str(defL),' --defH ',num2str(defH)];
        
        % Number of images
        n_img = numel(tomolist(i).rawtlt);
        % Digits for leading zeros
        digits = ceil(log10(n_img+1));


        % Prepare inputs for GCTF
        switch gctf_param.input_type
            
            case 'stack'
                
                % Split stack
                disp('TOMOMAN: Splitting stack!!!');
                temp_n_img = tomoman_mrc_split([tomolist(i).stack_dir,'/',tomolist(i).stack_name], 'outname', [tomolist(i).stack_dir,'/gctf/temp/',st_name], 'digits', -1);
                if n_img ~= temp_n_img
                    error(['ACHTUNG!!! Number of tilts in stack "',tomolist(i).stack_name,'" do not match the tomolist rawtlt!!!']);
                end                                   

                
                
            case 'frames'
                disp('TOMOMAN: Preparing frames!!!');
                
                % Find frames in stack
                [~,frame_idx] = intersect(tomolist(i).collected_tilts,tomolist(i).rawtlt);
                
                % Convert frames to .mrc files
                for j = 1:n_img
                    
                    % Check if tiff
                    [~,~,frame_ext] = fileparts(tomolist(i).frame_names{frame_idx(j)});                    
                    if any(strcmp(frame_ext,{'.tif','.tiff'}));
                        
                        % Options for conversion
                        clip_opt1 = ' ';
                        clip_opt2 = ' ';
                        clip_opt3 = ' ';
                        % Check for defects
                        if ~isempty(tomolist(i).defects_file)
                            clip_opt = [clip_opt1,' -D ',tomolist(i).defects_file];
                        end
                        % Check for gainref
                        if  ~isempty(tomolist(i).defects_file)
                            clip_opt2 = [clip_opt2,'-R ',num2str(tomolist(i).rotate_gain)];
                            clip_opt3 = [clip_opt3,tomolist(i).gainref];
                        end
                        
                        
                        system(['clip unpack',clip_opt1,...
                            clip_opt2,' ',...
                            tomolist(i) .frame_dir,tomolist(i).frame_names{frame_idx(j)},...
                            clip_opt3,' ',tomolist(i).stack_dir,'/gctf/temp/',st_name,'_',sprintf(['%0',num2str(digits),'d'],j),'.st']);
                    end
                end                                                                
        end
        
        % Run GCTF
        system(['gctf ',def_param,param_str,' ',tomolist(i).stack_dir,'/gctf/temp/',st_name,'_*']);
        
        % Copy .star file
        movefile('./micrographs_all_gctf.star',[tomolist(i).stack_dir,'/gctf/']);

        % Concatenate log files
        system(['cat ',tomolist(i).stack_dir,'/gctf/temp/*_gctf.log > ',tomolist(i).stack_dir,'/gctf/',st_name,'_gctf.log']);

        % Concatenate EPA log files
        if gctf_param.do_EPA == 1
            system(['cat ',tomolist(i).stack_dir,'/gctf/temp/*_gctf.log > ',tomolist(i).stack_dir,'/gctf/',st_name,'_EPA.log']);
        end

        % Concatenate .ctf files
        ctf_stack = zeros(gctf_param.boxsize,gctf_param.boxsize,n_img);
        for j = 1:n_img
            % String of image number
            num_str = sprintf(['%0',num2str(digits),'d'],j);
            % Read image
            [temp_img,header] = sg_mrcread([tomolist(i).stack_dir,'/gctf/temp/',st_name,'_',num_str,st_ext,'.ctf']);
            ctf_stack(:,:,j) = temp_img;
        end
        sg_mrcwrite([tomolist(i).stack_dir,'/gctf/',st_name,'.ctf'],ctf_stack,header);
        clear ctf_stack temp_img

        % Convert .star to ctfphaseflip file
        defocii = tomoman_gctf_star_to_ctfphaseflip([tomolist(i).stack_dir,'/',st_name,'.rawtlt'],[tomolist(i).stack_dir,'/gctf/micrographs_all_gctf.star'],[tomolist(i).stack_dir,'/ctfphaseflip.txt']);

        % Cleanup
        system(['rm -rf ',tomolist(i).stack_dir,'/gctf/temp/']);
        disp(['TOMOMAN: Defocus determination of stack "',tomolist(i).stack_name,'" complete!!!']);
        
        % Update tomolist
        tomolist(i).ctf_determined = true;
        switch gctf_param.input_type
            case 'stack'
                tomolist(i).ctf_determination_algorithm = 'GCTF-stack';
            case 'frames'
                tomolist(i).ctf_determination_algorithm = 'GCTF-frames';
        end
        tomolist(i).determined_defocii = defocii;
                
        % Save tomolist
        if write_list
            save([root_dir,tomolist_name],'tomolist');
        end
        
    end
end


