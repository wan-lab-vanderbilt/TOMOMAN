function t = tm_clean_stacks_newstack(t,c,dep,bad_tilts,n_good_tilts)
%% tm_clean_stacks_newstack
% Using a tomolist entry and a set of bad tilt indices, clean a stack using
% IMOD's newstack command. 
%
% WW 07-2023

%% Check for cleaning
if c.check_cleaning
    check = true;
    if nargin == 3
        error('TOMOMAN: ACHTUNG!!! When checking for cleaning, n_good_tilts is a required parameter!!!')
    end
else
    check = false;
end


%% Clean stacks

% Parse stack name
[~,st_name,st_ext] = fileparts(t.stack_name);

%%%%% Clean unfiltered stack %%%%%

% Parse exclusion array into string
exclude_list = sprintf('%.0f,',bad_tilts-1);
exclude_list = exclude_list(1:end-1);

% Write out cleaned frame stack using newstack  
in_stack_name = [t.stack_dir,t.stack_name];
clean_stack = true;
if check
    clean_stack = ~tm_check_stack_for_cleaning(in_stack_name, n_good_tilts);    
end
if clean_stack
    newstack_name = [st_name,c.clean_append,st_ext];                
    system([dep.newstack,' -input ',in_stack_name,...
        ' -output ',t.stack_dir,newstack_name,...
        ' -exclude ',exclude_list]);
    t.stack_name = newstack_name;
end



%%%%% Check for dose-filtered stack %%%%%
if ~strcmp(t.dose_filtered_stack_name,'none')  
    clean_df_stack = true; 
    if check
        clean_df_stack = ~tm_check_stack_for_cleaning([t.stack_dir,t.dose_filtered_stack_name], n_good_tilts);    
    end
    if clean_df_stack
        [~,df_st_name,df_st_ext] = fileparts(t.dose_filtered_stack_name);
        df_newstack_name = [df_st_name,c.clean_append,df_st_ext];                    
        system(['newstack -input ',t.stack_dir,t.dose_filtered_stack_name,...
                ' -output ',t.stack_dir,df_newstack_name,...
                ' -exclude ',exclude_list]);
        t.dose_filtered_stack_name = df_newstack_name;
    end
else
    clean_df_stack = false;
end



%%%%% Check for odd/even stacks %%%%%

% Name of odd/even stacks
stack_names = {[st_name,'_ODD.st'],[st_name,'_EVN.st']};                        
stack_types = {'_ODD','_EVN'};
if clean_df_stack
    df_stack_names = {[df_st_name,'_ODD',df_st_ext],[df_st_name,'_EVN',df_st_ext]};                        
end

% Check for existence of odd/even stacks
odd_exist = exist([t.stack_dir,stack_names{1}],'file');
evn_exist = exist([t.stack_dir,stack_names{2}],'file');
if ~odd_exist && ~evn_exist
    return
elseif ~odd_exist && evn_exist
    error(['TOMOMAN: ACHTUNG!!! Missing odd stack: ',stack_names{1}]);
elseif odd_exist && ~evn_exist
    error(['TOMOMAN: ACHTUNG!!! Missing even stack: ',stack_names{2}]);
end

% Build odd/even stacks
for j = 1:2

    % Parse stack name
    in_oe_name = [t.stack_dir,stack_names{j}];
    clean_oe_stack = true;
    if check
        clean_oe_stack = ~tm_check_stack_for_cleaning(in_oe_name, n_good_tilts);    
    end
    
    if clean_oe_stack
        % New name for cleaned stacks
        oe_newstack_name = [st_name,stack_types{j},c.clean_append,st_ext];                

        system(['newstack -input ',in_oe_name,...
                ' -output ',t.stack_dir,oe_newstack_name,...
                ' -exclude ',exclude_list]);
    end
    
    % Check for dose filtered stack
    if clean_df_stack
        df_oe_newstack_name = [df_st_name,stack_types{j},c.clean_append,df_st_ext];                    
        system(['newstack -input ',t.stack_dir,df_stack_names{j},...
                ' -output ',t.stack_dir,df_oe_newstack_name,...
                ' -exclude ',exclude_list]);
    end
    
end

end
