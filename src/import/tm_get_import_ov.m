function ov_fields = tm_get_import_ov()
%% tm_get_sortnew_ov
% Return the fields for the sortnew override struct.
%
% WW 05-2022

%% Fields 

ov_fields = {'tilt_axis_angle', 'num';...       % Tilt axis angle in degrees
             'dose_rate', 'num';...             % e/pixel/s
             'pixelsize', 'num';...             % Pixel size in Angstroms
             'target_defocus', 'num'};          % Target defocus in Microns
        
end
