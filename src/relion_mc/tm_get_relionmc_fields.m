function [rmc_fields,a_fields] = tm_get_relionmc_fields()
%% tm_get_relionmc_fields
% Return the fields for the relion motioncor structs.
%
% WW 05-2022

%% Fields

rmc_fields = {'n_cores','num';...             % Number of parallel processing cores
              'input_format','str';...        % 'tiff' or 'mrc' or 'eer'
              'patch','num';...               % Number of patches to be used for patch based alignment, default 0 0 corresponding full frame alignment.
              'bin_factor','num';...          % Maximum iterations for iterative alignment, default 5 iterations.
              'bfactor','num';...             % B-Factor for alignment, default 150.
              'eer_dosefractions','num';...   % EER grouping, default 40 
              'eer_upsampling','num';...      % EER upsampling (1 = 4K or 2 = 8K
              'save_OddEven','boo'};          % save Odd/Even sums


a_fields = {'force_realign','boo';...         % Force realignment of stack
            'image_size','num'};            % Output stack prefix
            
        
end
