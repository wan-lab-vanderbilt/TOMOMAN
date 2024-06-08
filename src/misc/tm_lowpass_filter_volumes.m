function tm_lowpass_filter_volumes(input_dir,output_dir,suffix,lp_res,pixelsize)
%% tm_lowpass_filter_volumes
% A function to apply a low-pass filter to all .mrc files in a folder. This
% assumes all .mrc files in the folder are volumes. Filtered volumes are
% written into the output directory with an optional suffix.
%
% The lp_res is the low pass filter resolution cutoff in Angstroms.
%
% Pixelsize is automatically taken from the .mrc headers. If these are
% incorrect, the pixelsize can be given. Only square pixels are supported.
%
% WW 06-2022

%% Initialize

% Check output_dir
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

% Get all .mrc files in input_dir
mrc_names = dir([input_dir,'*.mrc']);
n_mrc = numel(mrc_names);


%% Filter volumes

for i = 1:n_mrc
    
    % Read volume
    [vol,header] = sg_mrcread(mrc_names(i).name);
    
    % Check pixelsize
    if nargin == 4
        
        % Parse pixelsize
        ps = [(header.xlen/double(header.mx)),(header.ylen/double(header.my)),(header.zlen/double(header.mz))];
        
        % Round to 4 decimal places
        ps = round(ps.*10000)./10000;       % In case of rounding errors
        
        % Check dimensions
        if ~all(ps==ps(1))
            error(['ACHTUNG!!!! Non-cubic voxel size in ',mrc_names(i).name,'!!!']);
        else
            pixelsize = ps(1);
        end
    end
    
    % Filter volume
    filt_vol = sg_bandpass_filter_tomogram(vol,'pixelsize',pixelsize,'lp_res',lp_res);
    
    
    % Parse output name
    [path,name,~] = fileparts(mrc_names(i).name);
    if ~isempty(path)
        path = [path,'/'];
    end
    output_name = [path,name,'_',suffix,'.mrc'];
    
    
    % Write output
    sg_mrcwrite([output_dir,output_name],filt_vol,header);
    disp([mrc_names(i).name,' filtered!!!']);
    
    clear vol filt_vol
    
    
end
    
    
    
    


