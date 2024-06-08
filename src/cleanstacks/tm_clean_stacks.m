function tomolist = tm_clean_stacks(tomolist,p,c,dep,par)
%% tomoman_clean_stacks
% A function for launching a tilt-stack in 3dmod, and waiting for input
% tilts to remove. Tilts are then removed, and rawtlt files are updated.
%
% By running this command, the remove tilts are appended to the
% removed_tilts field of the tomolist, while the stack_name is updated to
% the cleaned stack. The tilts of the stack denoted by stack_name is the
% set difference between collected_tilts and removed_tilts. Therefore, this
% command can be run serially to re-clean stacks. 
%
% If dose-filtered stacks have already been generated, those stacks are
% also cleaned to match the unfiltered stacks.
%
% WW 04-2018


%% Parallel processing

% Check for parallel processing
par_proc = false;
if nargin == 5
    if ~isempty(par)
        par_proc = true;        
    end
else
    par = [];
end



%% Clean stacks

% Check cleaning mode
if c.check_cleaning
    cleaning_mode = 'check';
else
    cleaning_mode = 'input';
end


% Loop through stacks
n_stacks = size(tomolist,2);
for i = 1:n_stacks
    
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
    elseif tomolist(i).clean_stack
        if ~c.force_cleaning && ~c.check_cleaning
            process = false;
        end        
    end
    

    
    % Process stack
    if process
        % Clean unless exception occurs
        clean = true;
        
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
                
                
            
            case 'input'
        
                % Launch tilt-stack in 3dmod
                system([dep.imod_3dmod,' -b ',num2str(c.clean_binning),' ',tomolist(i).stack_dir,tomolist(i).stack_name]);


                % Ask for input about bad tilts
                wait = 0;
                while wait == 0

                    % Wait for user input
                    disp([p.name,'Press enter for no cleaning, give tilt numbers to remove (space separated), or skip, to prevent further processing of stack']);
                    assess_string = input('Which tilts should I remove? (Start counting at one) \n','s'); 

                    % Empty string is no bad tilts, skip sets the skip value in the tomolist
                    if isempty(assess_string) || strcmp(assess_string,'skip')
                        wait = 1;
                    else

                        % Check input is only numbers and whitespace
                        input_check = isstrprop(assess_string, 'digit') + isstrprop(assess_string, 'wspace');
                        if ~all(input_check)
                            disp('Your input is unacceptable!!!')
                        else
                            bad_tilts = str2num(assess_string); %#ok<ST2NM>
                            wait = 1;
                        end
                    end
                end
                
                %%%%% Skip Stack %%%%%
                if strcmp(assess_string,'skip')

                    % Set tomolist to skip
                    tomolist(i).skip = true;
                    disp([p.name,'Stack ',tomolist(i).stack_name,' set to skip!!!']);

                    clean = false;                    
                end


                %%%%% Empty String %%%%%
                if isempty(assess_string)
                    disp([p.name,'No bad tilts... moving on to next stack!!!']);

                    clean = false;
                end
                
        end


        
        
        % Parse stack names
       [~,st_name,~] = fileparts(tomolist(i).stack_name);         
        if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')                
            [~,df_st_name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
        end

                

        % Clean stacks
        if clean
            disp([p.name,'Removing bad tilts in stack ',tomolist(i).stack_name]);
            tomolist(i) = tm_clean_stacks_newstack(tomolist(i),c,dep,bad_tilts,n_tilts);
        end
        
        
        %%%%% Update tomolist %%%%%
        
        % Update tomolist with new bad tilts
        if clean && strcmp(cleaning_mode,'input')

            % Append removed_tilts
            bad_angles = tilts(bad_tilts);
%             tomolist(i).removed_tilts = sort(cat(1,tomolist(i).removed_tilts,bad_angles'));
            tomolist(i).removed_tilts = sort(cat(1,tomolist(i).removed_tilts,bad_angles));
            tilts = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);

        end       
        
        % Update remaining tomolist parameters
        tomolist(i).clean_stack = true;
        tomolist(i).rawtlt = sort(tilts);
        tomolist(i).min_tilt = min(tilts);
        tomolist(i).max_tilt = max(tilts);

        % Write rawtilt file
        dlmwrite([tomolist(i).stack_dir,st_name,c.clean_append,'.rawtlt'],tomolist(i).rawtlt);
        if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')    
            dlmwrite([tomolist(i).stack_dir,df_st_name,c.clean_append,'.rawtlt'],tomolist(i).rawtlt);
        end

                
    end
        
        
    
    
end


% Write parallel completion file    
if par_proc
    system(['touch ',par.comm_dir,'tomoman_clean_stacks']);
end


