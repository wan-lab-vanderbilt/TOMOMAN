function p_fields = tm_get_import_p()
%% tm_get_import_p
% Return the fields for the import p struct.
%
% WW 05-2022

%% Fields

p_fields = {'root_dir', 'str';...               % Root folder for dataset; stack directories will be generated here.
            'raw_stack_dir', 'str';...          % Folder containing raw stacks (It is recommended to use links)
            'raw_frame_dir', 'str';...          % Folder containing unsorted frames (It is recommended to use links)
            'tomolist_name', 'str';...          % Relative to root_dir
            'log_name', 'str';...               % Relative to root_dir
%             'prefix', 'str';...                 % Beginning of stack/mdoc names (e.g. stackname is [prefix][tomonum].[raw_stack_ext])
            'raw_stack_ext', 'str';...          % File extension of raw stacks
            'if_eer', 'boo';...                 % ! for EER, 0 for MRC
            'gainref','str';...                 % For no gainref, set to 'none, set to 'AUTO' if you are lazy!
            'defects_file','str';...            % For no defects_file, set to 'none'
            'rotate_gain','num';...             % Gain ref rotation
            'flip_gain','num';...               % Gain ref flip; 0 = none, 1 = up/down, 2 = left/right
            'os','str';...                      % Operating system for data collection. Options are 'windows' and 'linux'
            'mirror_stack','str';...            % Mirror images, MAKE SURE YOU KNOW YOUR STUFF!!;
            'voltage', 'num'};                  % Voltage in kV.
            
            
            
        
end
