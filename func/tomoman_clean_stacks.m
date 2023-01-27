function tomolist = tomoman_clean_stacks(tomolist,p,c,write_list)
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

%% Clean stacks
n_stacks = size(tomolist,2);

for i = 1:n_stacks
    
    % Check for skip
    if (tomolist(i).skip == false)
        process = true;
    else
        process = false;
    end
    % Check for previous alignment
    if (process == true) && (tomolist(i).clean_stack == false)
        process = true;
    else
        process = false;
    end        
    % Check for force_realign
    if (logical(c.force_cleaning) == true) && (tomolist(i).skip == false)
        process = true;
    end

    
    % Process stack
    if process
        
        % Parse tomogram string
        tomo_str = strrep(tomolist(i).mdoc_name, '.st.mdoc', '');
        
        if c.denovo
            % Determine tilts in stack
            tilts = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);

            % Launch tilt-stack in 3dmod
            system(['3dmod -b ',num2str(c.clean_binning),' ',tomolist(i).stack_dir,tomolist(i).stack_name]);


            % Ask for input about bad tilts
            wait = 0;
            while wait == 0
                % Wait for user input
                disp('Press enter for no cleaning, give tilt numbers to remove (space separated), or skip, to prevent further processing of stack');
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
            
        else
            
            if tomolist(i).skip
                assess_string = 'skip';
                
            else

                % unsorted index (important for getting right file index for motion corrected mrc)
                [sorted_tilts, ~] = sortrows(tomolist(i).collected_tilts);
                [~,sort_tilt_idx] = setdiff(sorted_tilts,tomolist(i).removed_tilts); 
                
                n_collected_tilts = numel(sorted_tilts);
                collected_tilts_idx = 1:n_collected_tilts';

                exclude_idx = ~ismember(collected_tilts_idx,sort_tilt_idx);
                bad_tilts = collected_tilts_idx(exclude_idx);
                assess_string = sprintf('%2d',bad_tilts);
                
                

%                 % Check if the tilts are same as aligned tilts from tlt file.
%                 [~,imod_name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
%                 tlt_sourcefile = [tomolist(i).stack_dir,'/',imod_name,'.tlt'];
%                 aligned_tilts = dlmread(tlt_sourcefile);
%                 n_alitilts = numel(aligned_tilts);
% 
%                 if n_alitilts ~= n_tilts
%                     error("Achtung!!! Number of aligned tilts and cleaned tilts do not match!!!!")
%                 end
                
                %assess_string

            end
            
        end


        % If there are bad tilts, fix the stack
        if strcmp(assess_string,'skip')
            
            % Set tomolist to skip
            tomolist(i).skip = true;
            disp(['Stack ',tomo_str,' set to skip!!!']);
            
        else
            
            % Parse stack name
            [~,st_name,st_ext] = fileparts(tomolist(i).stack_name);
            
            if isempty(assess_string)
            
                disp('No bad tilts... moving on to next stack!!!');
                
                if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')                
                    [~,df_st_name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
                end

            
            elseif ~isempty(assess_string)

                disp(['Removing bad tilts in stack ',tomo_str]);

                % Parse exclusion array into string
                exclude_list = sprintf('%.0f,',bad_tilts-1);
                exclude_list = exclude_list(1:end-1);

                % Write out cleaned frame stack using newstack                
                newstack_name = [st_name,c.clean_append,st_ext];  
                disp(['newstack -input ',tomolist(i).stack_dir,tomolist(i).stack_name,...
                    ' -output ',tomolist(i).stack_dir,newstack_name,...
                    ' -exclude ',exclude_list]);
                system(['newstack -input ',tomolist(i).stack_dir,tomolist(i).stack_name,...
                    ' -output ',tomolist(i).stack_dir,newstack_name,...
                    ' -exclude ',exclude_list]);
                
                % How to calculate exclude list from already existing
                % tomolist (implement and option in parser!!!!)
%                 [~,exclude_list]=setdiff(sort(tomolist(i).collected_tilts),tomolist(i).rawtlt,'stable','rows')

                tomolist(i).stack_name = newstack_name;
                
                % Check for dose-filtered stack
                if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')                
                    [~,df_st_name,df_st_ext] = fileparts(tomolist(i).dose_filtered_stack_name);
                    df_newstack_name = [df_st_name,c.clean_append,df_st_ext];                    
                    system(['newstack -input ',tomolist(i).stack_dir,tomolist(i).dose_filtered_stack_name,...
                            ' -output ',tomolist(i).stack_dir,df_newstack_name,...
                            ' -exclude ',exclude_list]);
                    tomolist(i).dose_filtered_stack_name = df_newstack_name;
                end

                
                % Check for odd-even stacks
                [~,st_name,st_ext] = fileparts(tomolist(i).stack_name);
                stack_types = {'ODD','EVN'};
                for j=1:2
                    stack_name = [st_name,'_',stack_types{j},st_ext];
                    newstack_name = [st_name,'_',stack_types{j},c.clean_append,st_ext]; 
                    if isfile([tomolist(i).stack_dir,'/',stack_name])
                        disp(['Found ', stack_name, ' stack. cleaning....'])
                        system(['newstack -input ',tomolist(i).stack_dir,stack_name,...
                            ' -output ',tomolist(i).stack_dir,newstack_name,...
                            ' -exclude ',exclude_list]);
                    end
                end
                
                % Append removed_tilts
                
                if c.denovo
                    bad_angles = tilts(bad_tilts);
                    tomolist(i).removed_tilts = sort(cat(1,tomolist(i).removed_tilts,bad_angles'));
                end
                tilts = setdiff(tomolist(i).collected_tilts,tomolist(i).removed_tilts);
                
            end
            
            % Update remaining tomolist parameters
            tomolist(i).clean_stack = true;

            if c.denovo
                tomolist(i).rawtlt = sort(tilts);
                tomolist(i).min_tilt = min(tilts);
                tomolist(i).max_tilt = max(tilts);
            end
            
            % Write rawtilt file
            dlmwrite([tomolist(i).stack_dir,st_name,c.clean_append,'.rawtlt'],tomolist(i).rawtlt);
            if ~strcmp(tomolist(i).dose_filtered_stack_name,'none')    
                dlmwrite([tomolist(i).stack_dir,df_st_name,c.clean_append,'.rawtlt'],tomolist(i).rawtlt);
            end
          
        end
        
        % Save tomolist
        if write_list
            save([root_dir,tomolist_name],'tomolist');
        end
        
    end
    
end