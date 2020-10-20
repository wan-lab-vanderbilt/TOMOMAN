function tomoman_link_sorted_frames(mdoc_name,frame_dir,output_dir)
%% tomoman_link_sorted_frames
% Read in a SerialEM .mdoc file, get frame names and tilt angles, and
% create symlinks from frame_dir to output_dir with names in order of tilt
% angle. 

%% Parse data
disp('Parsing data from .mdoc file...');

% Parse data from .mdoc
mdoc_fields = {'TiltAngle','SubFramePath','DateTime'};
mdoc_field_types = {'num','str','str'};
mdoc_param = tomoman_parse_mdoc(mdoc_name,mdoc_fields,mdoc_field_types);
n_frames = numel(mdoc_param);

% Sort by tilt angle
[~,sort_idx] = sort([mdoc_param.TiltAngle]);

% Number of digits for outputs
fmt = ['%0',num2str(ceil(log10(n_frames))),'d'];



%% Generate symlinks
disp('Creating symlinks...');

% Check folder
if ~exist(output_dir,'dir')
    system(['mkdir -p ',output_dir]);
end

for i = 1:n_frames    
    
    % Parse filename
    [~,name,ext] = tomoman_fileparts_windows(mdoc_param(sort_idx(i)).SubFramePath);
    
    % Generate symlink
    system(['ln -s ',frame_dir,'/',name,ext,' ',output_dir,'/',num2str(i,fmt),ext]);
    
end

disp('All symlinks created!!!1!');

