function p_fields = tm_get_basic_p()
%% tm_get_basic_p
% Return the fields for the basic p-struct. Used in most tomoman functions
% except sortnew.
%
% WW 05-2022

%% Fields


p_fields = {'root_dir','str';...            % Root folder for dataset; stack directories will be generated here.
            'tomolist_name','str';...       % Relative to root_dir
            'log_name','str'};              % Relative to root_dir

           
        
end
