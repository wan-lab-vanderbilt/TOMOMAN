function arctic_fields = tm_get_arctic_fields()
%% tm_get_arctic_fields
% Return the fields for the ARCTiC structs.
%
% WW 07-2025

%% Fields

arctic_fields = {'force_cleaning','boo';...       % Force cleaning for cleaned stacks. 1 = yes, 0 = no
                 'clean_append','str';...         % Append to name for cleaned stack. Setting to "none" overwrites old file.
                 'check_cleaning','boo';...       % Make sure stacks have been cleaned using stored bad tilts. 1 = yes, 0 = no.
                 'subset_list','str';...          % List containing tomo_num values for processing. Set to 'none' to skip.
                 'gpu_id','num';...               % The ID of GPUs to be used for processing. e.g 0,1,2,3.
                 'angle_step','num';...           % The increment (step size) for the tilt angles between consecutive tilts.
                 'model','str';...                % Path to the pre-trained model file
                };
              

        
end
