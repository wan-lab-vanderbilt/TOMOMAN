function tomolist = tm_arctic(tomolist,p,arctic,dep,par)
%% tomoman_clean_stacks
% A function to run the Turonova group's ARCTiC software for automated tilt
% series cleaning. 
%
% WW 08-2025


%% Parallel processing

% Check for subset_list
if sg_check_param(arctic,'subset_list')
    subset_list = dlmread([p.root_dir,arctic.subset_list]);
else
    subset_list = [];
end

%% Clean stacks

% Check cleaning mode
if arctic.check_cleaning
    cleaning_mode = 'check';
else
    cleaning_mode = 'clean';
end


% Loop through stacks
n_stacks = size(tomolist,2);
for i = 1:n_stacks
    
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
        disp([p.name,tomolist(i).stack_name,' set to skip... Moving on to next stack...']);
    elseif tomolist(i).clean_stack
        if ~arctic.force_cleaning && ~arctic.check_cleaning
            process = false;
            disp([p.name,tomolist(i).stack_name,' has already been cleaned... Moving on to next stack...']);
        end        
    end
    
    % Check subset_list
    if ~isempty(subset_list)
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
            disp([p.name,tomolist(i).stack_name,' is not in the subset_list... Moving on to next stack...']);
        end
    end
    
    
    % Process stack
    if process
        
        % Determine tilts in stack
        tilts = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);
        n_tilts = numel(tilts);
        
        
        %%%%% Get bad tilts %%%%%
        switch cleaning_mode
            
            case 'check'
                
                % Parse indices for removed tilts
                [sorted_tilts, ~] = sortrows(tomolist(i).collected_tilts);
                [~,sort_tilt_idx] = setdiff(sorted_tilts,tomolist(i).removed_tilts); 

                
                n_collected_tilts = numel(sorted_tilts);
                collected_tilts_idx = 1:n_collected_tilts';

                
                exclude_idx = ~ismember(collected_tilts_idx,sort_tilt_idx);
                bad_tilts = collected_tilts_idx(exclude_idx);
                
                
            
            case 'clean'
                disp([p.name,'Running ARCTiC on ',tomolist(i).stack_name,'...']);
                
                bad_tilts = tm_run_arctic(tomolist(i),arctic,dep);
                
        end


        
        
        % Parse stack names
       [~,st_name,~] = fileparts(tomolist(i).stack_name);         
        if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')                
            [~,df_st_name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
        end

                

        % Clean other stacks
        disp([p.name,'Checking for other stacks to clean...']);
        arctic.skip_unfilt = true;
        tomolist(i) = tm_clean_stacks_newstack(tomolist(i),arctic,dep,bad_tilts,n_tilts);
        
        
        %%%%% Update tomolist %%%%%

        % Append removed_tilts
        bad_angles = tilts(bad_tilts);
        tomolist(i).removed_tilts = sort(cat(1,tomolist(i).removed_tilts,bad_angles));
        tilts = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);

        
        % Update remaining tomolist parameters
        tomolist(i).clean_stack = true;
        tomolist(i).rawtlt = sort(tilts);
        tomolist(i).min_tilt = min(tilts);
        tomolist(i).max_tilt = max(tilts);

        % Write rawtilt file
        dlmwrite([tomolist(i).stack_dir,st_name,arctic.clean_append,'.rawtlt'],tomolist(i).rawtlt);
        if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')    
            dlmwrite([tomolist(i).stack_dir,df_st_name,arctic.clean_append,'.rawtlt'],tomolist(i).rawtlt);
        end

                
    end
        
        
    
    
end


% % Write parallel completion file    
% if par_proc
%     system(['touch ',par.comm_dir,'tomoman_clean_stacks']);
% end


