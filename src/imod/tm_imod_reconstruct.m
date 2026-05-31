function tm_imod_reconstruct(tomolist, p, imod, dep)
%% tm_imod_reconstruct
% Batch reconstruction of tomograms using IMOD 
%
% WW 07-2023


%% Initialize

% Number of stacks
n_stacks = numel(tomolist);

% Check for subset_list
if sg_check_param(imod,'subset_list')
    subset_list = dlmread(tm_check_absolute_path(p.root_dir,imod.subset_list));
else
    subset_list = [];
end

% Check binnings
imod.tomo_bin = sort(imod.tomo_bin);  % Resort to ensure order from lowest to highest binning
if ~isempty(imod.ali_stack_bin)           % The ali_stack_bin should match the lowest output tomogram binning
    if imod.tomo_bin(1) ~= imod.ali_stack_bin
        error([p.name,'ACHTUNG!!! There is a mismatch between ali_stack_bin and lowest output tomogram binning!!!']);
    end
else
    if imod.tomo_bin(1) ~= 1
        error([p.name,'ACHTUNG!!! There is a mismatch between ali_stack_bin and lowest output tomogram binning!!!']);
    end
end
        

% Parse tomogram output directories
n_binnings = numel(imod.tomo_bin);
tomo_dir = cell(n_binnings,1);
for i = 1:n_binnings
    tomo_dir{i} = [p.root_dir,imod.output_dir_prefix,'bin',num2str(imod.tomo_bin(i)),'/'];
    % Check if directories exist
    if ~exist(tomo_dir{i},'dir')
        mkdir(tomo_dir{i});
    end    
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
    
    
    % Reconstruct tomograms
    if process        
        disp([p.name,'Reconstructing ',tomolist(i).stack_name,' ...']);

        % Check stack type
        switch imod.process_stack
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
        % Reconstruct tomogram
        tm_imod_reconstruct_tomogram(tomolist(i),imod,stack_type,'imod_recons/',imod.ali_stack_bin,tomo_dir{1},imod.gpu_id);
        
            
        % Bin tomograms serially
        if numel(imod.tomo_bin) > 1
            
            % Open binning script
            bscript_name = [tomolist(i).stack_dir,'imod_recons/tomo_binning.sh'];
            bscript = fopen(bscript_name,'w');
            
            % Write initial lines
            fprintf(bscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);

            for j = 2:numel(imod.tomo_bin)

                % Input tomogram name
%                 in_name = [tomo_dir{j-1},num2str(tomolist(i).tomo_num),'.rec'];
                in_name = [tomo_dir{j-1},tomo_name,'.rec'];

                % Ouptut tomogram name
%                 out_name = [tomo_dir{j},num2str(tomolist(i).tomo_num),'.rec'];
                out_name = [tomo_dir{j},tomo_name,'.rec'];

                % Bin factor
                bin_factor = imod.tomo_bin(j)/imod.tomo_bin(j-1);

                % Write script
                fprintf(bscript,['echo "TOMOMAN: Binning tomogram ',tomo_name,' by a factor of ',num2str(imod.tomo_bin(j)),' by Fourier cropping..."\n']);
                fprintf(bscript,[dep.fourier3d,' ',...
                                 '-InputFile ',in_name,' ',...
                                 '-OutputFile ',out_name,' ',...
                                 '-BinFactor ',num2str(bin_factor),' ',...
                                 '-MemoryLimit ',num2str(imod.f3d_memlimit),' ','\n\n']);
                             
                             
                             
            end
            
            % Close file
            fclose(bscript);
            
            % Make executable
            system(['chmod +x ',bscript_name]);

            % Run file
            system(bscript_name);
        end
                    


            
                       

    end 
    
%     % Save tomolist
%     if write_list
%         save([p.root_dir,p.tomolist_name],'tomolist');
% 
%     end
end


