function p_fields = tm_get_relionmc_p()
%% tm_get_relionmc_p
% Return the fields for the relion motioncor p-struct.
%
% WW 05-2022

%% Fields


p_fields = {'root_dir','str';...            % Root folder for dataset; stack directories will be generated here.
            'tomolist_name','str';...       % Relative to root_dir
            'log_name','str'};              % Relative to root_dir

           
        
end
