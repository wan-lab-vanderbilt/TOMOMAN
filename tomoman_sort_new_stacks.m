function tomolist = tomoman_sort_new_stacks(p,ov,s,tomolist)
%% tomoman_sort_new_stacks
% A function to check the raw_stack_dir for new stacks and .mdoc files, and
% copy them, along with their frames, to new tilt-stack directories. A new
% tomolist will also be generated and filled.
%
% WW 04-2018

%% Initialize
disp('TOMOMAN: Sorting new stacks!!!');

% Get list of .mdoc files
mdoc_dir = dir([p.raw_stack_dir,p.prefix,'*.mdoc']);
n_stacks = size(mdoc_dir,1);
disp(['TOMOMAN: ',num2str(n_stacks),' new .mdoc files found!']);

% Get indices for stack number
sn_s = numel(p.prefix)+1;
sn_e = numel(p.raw_stack_ext)+5;


% Initilize mdoc parsing fields
mdoc_fields = {'TiltAxisAngle','TiltAngle','ExposureDose','ExposureTime','TargetDefocus','SubFramePath','NumSubFrames','PixelSpacing','DateTime'};
mdoc_field_types = {'num','num','num','num','num','str','num','num','str'};



%% Loop through and sort stack data

for i = 1:n_stacks
    
    % Initialize new tomolist row
    temp_tomolist = tomoman_generate_tomolist(1);
    
    % Write root_dir
    temp_tomolist.root_dir = p.root_dir;
        
    % Parse stack number
    stack_num = mdoc_dir(i).name(sn_s:(end-sn_e));
    temp_tomolist.tomo_num = str2double(stack_num);
    
    
    % Check check!!!
    disp(['TOMOMAN: parsing .mdoc for stack ',stack_num]);
    
    % Parse .mdoc
    mdoc_param = tomoman_parse_mdoc([p.raw_stack_dir,mdoc_dir(i).name],mdoc_fields,mdoc_field_types);
    n_tilts = numel(mdoc_param);
    
    % Check for raw stack
    raw_stack_name = [p.prefix,stack_num,p.raw_stack_ext]; 
    if ~exist([p.raw_stack_dir,raw_stack_name],'file')
        warning(['ACHTUNG!!! Raw stack for tomogram ',num2str(stack_num),' missing!!!']);
        if ~logical(s.ignore_raw_stacks)
            warning(['ACHTUNG!!! Skipping stack ',num2str(stack_num),'!!!']);
            continue
        end
    end
    
    % Check frames
    frame_names = cell(n_tilts,1);
    for j = 1:n_tilts
        % Continue i loop in case of missing frame
        continue_loop = false;
        
        % Parse framenames from .mdoc
        switch p.os
            case 'windows'
                [~,name,ext] = tomoman_fileparts_windows(mdoc_param(j).SubFramePath);
            case 'linux'
                [~,name,ext] = fileparts(mdoc_param(j).SubFramePath);
        end
        
        % Store frame name
        frame_names{j} = [name,ext];
        
        % Check for existence of frame
        if ~exist([p.raw_frame_dir,frame_names{j}],'file')
            warning(['ACHTUNG!!! Frame "',frame_names{j},'" missing from stack ',num2str(stack_num),'!!!']);
            if ~logical(s.ignore_missing_frames)
                continue_loop = true;
            end
        end
    end
    if continue_loop
        warning(['ACHTUNG!!! Skipping stack ',num2str(stack_num),'!!!']);
        continue
    end
    temp_tomolist.frame_names = frame_names;
    
    % Write tilt-axis angle
    if isempty(ov.tilt_axis_angle)
        temp_tomolist.tilt_axis_angle = mdoc_param(1).TiltAxisAngle;
    else
        temp_tomolist.tilt_axis_angle = ov.tilt_axis_angle;
    end
        
    % Write tilt angles (Order by collection time)
    dt = datetime({mdoc_param.DateTime},'InputFormat','dd-MMM-yyyy HH:mm:ss');  % Convert to MATLAB datetime
    [~,time_idx] = sort(dt);
    temp_tomolist.collected_tilts = [mdoc_param(time_idx).TiltAngle]'; 
    
    % Store camera files
    temp_tomolist.gainref = p.gainref;
    temp_tomolist.defects_file = p.defects_file;
    temp_tomolist.rotate_gain = p.rotate_gain;
    temp_tomolist.flip_gain = p.flip_gain;
    
    % Mirror stack
    temp_tomolist.mirror_stack = p.mirror_stack;
    
    % Pixelsize
    if isempty(ov.pixelsize)
        if all(mdoc_param(1).PixelSpacing == [mdoc_param.PixelSpacing])
            temp_tomolist.pixelsize = mdoc_param(1).PixelSpacing;
        else
            warning(['Achtung!!! ',raw_stack_name,' has varying pixelsizes!!!']);
            temp_tomolist.pixelsize = [mdoc_param.PixelSpacing];
        end
    else
       temp_tomolist.pixelsize = ov.pixelsize; 
    end
    
    % Get doses
    total_exposure = cumsum([mdoc_param.ExposureTime]');
    temp_tomolist.cumulative_exposure_time = total_exposure;
    if isempty(ov.dose_rate)        
        temp_tomolist.dose = cumsum([mdoc_param.ExposureDose]');
    else
        total_dose = (total_exposure.*ov.dose_rate)./([temp_tomolist.pixelsize].^2);
        temp_tomolist.dose = total_dose;

    end
    
    % Target defocus
    if all(mdoc_param(1).TargetDefocus == [mdoc_param.TargetDefocus])
        temp_tomolist.target_defocus = mdoc_param(1).TargetDefocus;
    else
        warning(['Achtung!!! ',raw_stack_name,' has varying target defocii!!!']);
        temp_tomolist.target_defocus = [mdoc_param.TargetDefocus];
    end
    
    % Number of frames
    if all(mdoc_param(1).NumSubFrames == [mdoc_param.NumSubFrames])
        temp_tomolist.n_frames = mdoc_param(1).NumSubFrames;
    else
        temp_tomolist.n_frames = [mdoc_param.NumSubFrames];
    end
        
    
    % Generate new folder
    disp(['Generating directories and moving files for stack ',num2str(stack_num),'!!!']);
    tomo_dir = [p.root_dir,p.prefix,stack_num,'/'];
    mkdir(tomo_dir);
    mkdir([tomo_dir,'frames/']);
    temp_tomolist.stack_dir = tomo_dir;
    temp_tomolist.frame_dir = [tomo_dir,'frames/'];
    
    % Move .mdoc file
    movefile([p.raw_stack_dir,mdoc_dir(i).name],[tomo_dir,mdoc_dir(i).name]);
    temp_tomolist.mdoc_name = mdoc_dir(i).name;
    
    % Move raw stack
    raw_stack_name = [p.prefix,stack_num,p.raw_stack_ext];    
    if exist([p.raw_stack_dir,raw_stack_name],'file')
        movefile([p.raw_stack_dir,raw_stack_name],[tomo_dir,raw_stack_name]);
        temp_tomolist.raw_stack_name = raw_stack_name;
    else
        warning(['ACHTUNG!!! ',raw_stack_name,' not copied as it does not exists...']);
    end      
    
    % Move frames
    for j = 1:n_tilts
        try
            movefile([p.raw_frame_dir,frame_names{j}],[tomo_dir,'frames/',frame_names{j}]);
        catch
            warning(['ACHTUNG!!! Error moving ',p.raw_frame_dir,frame_names{j}]);
        end
    end        

    
    % Append and save tomolist
    tomolist = cat(2,tomolist,temp_tomolist);
    save([p.root_dir,p.tomolist_name],'tomolist');
    disp(['Stack ',num2str(i),' of ',num2str(n_stacks),' sorted...']);
end    
    
disp('TOMOMAN: Stack sorting complete!!!');
    
    
    
    



