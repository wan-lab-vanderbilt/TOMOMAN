function ctffind4_fields = tm_get_ctffind4_fields()
%% tm_get_ctffind4_fields
% Return the fields for the CTFFIND4 structs.
%
% WW 05-2022

%% Fields

ctffind4_fields = {'force_ctffind', 'boo', false;...            % 1 = yes, 0 = no
                   'def_range', 'num', 0.6;...                  % Range of defocus to search in microns. TOMOMAN will use this and the "target_defocus" values in the tomolist to calculate the CTFFIND4 min_res and max_res parameters.
                   'ps_size', 'num', 512;...                    % Size of power-spectrum in pixels
                   'cs', 'num', 2.7;...                         % Spherical aberration
                   'famp', 'num', 0.07;...                      % Ampltidue contrast
                   'min_res', 'num', 30;...                     % Minimum resolution to fit
                   'max_res', 'num', 5;...                      % Maximum resolution to fit
                   'def_step', 'num', 0.01;...                  % Defocus search step in microns. Default is 0.01.
                   'known_astig', 'boo', false;...              % Do you know what astigmatism is present? (0 = no, 1 = yes). Default is 0
                   'slower', 'boo', true;...                    % Slower, more exhaustive search (0 = no, 1 = yes). Default is 0
                   'astig', 'boo', 0;...                        % Known astigmatism.
                   'astig_angle', 'num', 0;...                  % Known astigmatism angle.
                   'rest_astig', 'boo', true;...                % Restrict astigmatism (0 = no, 1 = yes). Default = 1
                   'exp_astig', 'num', 200;...                  % Expected (tolerated) astigmatism. Default is 200.
                   'det_pshift', 'boo', false;...               % Determine phase shift (0 = no, 1 = yes).
                   'pshift_min', 'num', 0;...                   % Minimum phase shift (rad). Default = 0.0.
                   'pshift_max', 'num', 3.15;...                % Maximum phase shift (rad). Default = 3.15.
                   'pshift_step', 'num', 0.1;...                % Phase shift search step. Default = 0.1.
                   'det_tilt','boo', false;...                  % Determine sample tilt? Default is 0
                   'expert', 'boo', true;...                    % Do you want to set expert options? (0 = no, 1 = yes) Default is 0
                   'resample', 'boo', true;...                  % Resample micrograph if pixel size too small? (0 = no, 1 = yes)
                   'known_defocus', 'boo', false;...            % Do you already know the defocus?  (0 = no, 1 = yes) Default is 0 
                   'known_defocus_1', 'num', 0;...              % Known defocus 1 .   Default is 0
                   'known_defocus_2', 'num', 0;...              % Known defocus 2 .   Default is 0
                   'known_defocus_astig', 'num', 0;...          % Known defocus astigmatism.   Default is 0
                   'known_defocus_pshift', 'num', 0;...         % Known defocus phase shift in radians.   Default is 0
                   'nthreads', 'num', 5;...                     % Desired number of parallel threads. 
                   };
              


        
end
