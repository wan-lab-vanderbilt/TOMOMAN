function tomolist = tm_import_new_stacks(p,ov,s,tomolist,par)
%% tm_import_new_stacks
% A function to check the raw_stack_dir for new stacks and .mdoc files, and
% copy them, along with their frames, to new tilt-stack directories. A new
% tomolist will also be generated and filled.
%
% WW 04-2018

%% Parallel processing

% Check for parallel processing
par_proc = false;
if nargin == 5
    if ~isempty(par)
        par_proc = true;
    end
end


%% Initialize
disp([p.name,'Importing new stacks!!!']);

% Get list of .mdoc files
mdoc_dir = dir([p.root_dir,p.raw_stack_dir,'*.mdoc']);
n_stacks = size(mdoc_dir,1);

% Return if no new stacks
if n_stacks == 0
    disp([p.name,'No new .mdoc files found!!!']);
    return
else
    disp([p.name,'',num2str(n_stacks),' .mdoc files found!']);
end

% % Get indices for stack number
% sn_s = numel(p.prefix)+1;
% sn_e = 5;
% sn_e = numel(p.raw_stack_ext)+5;

% Initilize mdoc parsing fields
if isempty(ov.target_defocus)
    mdoc_fields = {'TiltAxisAngle','TiltAngle','ExposureDose','ExposureTime','TargetDefocus','SubFramePath','NumSubFrames','PixelSpacing'};
    mdoc_field_types = {'num','num','num','num','num','str','num','num'};
else
    mdoc_fields = {'TiltAxisAngle','TiltAngle','ExposureDose','ExposureTime','SubFramePath','NumSubFrames','PixelSpacing'};
    mdoc_field_types = {'num','num','num','num','str','num','num'};
end    


%% Loop through and sort stack data

for i = 1:n_stacks
    
    % Initialize new tomolist row
    temp_tomolist = tm_generate_tomolist(1);
    
    % Store root_dir
    temp_tomolist.root_dir = p.root_dir;
        
%     % Parse stack number
%     [temp_tomolist.tomo_num, tomo_name, digits] = tm_parse_tomo_num(mdoc_dir(i).name,p.prefix);

%     % Tilt-series root name
%     tomo_name = mdoc_dir(i).name(1:end-sn_e);   
    
    % Parse .mdoc name
    [path,name,ext] = fileparts(mdoc_dir(i).name);
    if ~isempty(path)
        path = [path,'/'];
    end
    
    
    % Check check!!!
    disp([p.name,'parsing ',name]);
    
    
    % Check if the .mdoc is already in the tomolist
    if numel(tomolist) >= 1        
        idx = strcmp({tomolist.mdoc_name}, mdoc_dir(i).name);        
        if any(idx)            
            warning([p.name,'ACHTUNG!!! ',name,' is already in the tomolist!!! Skipping ...']);
            continue            
        end  
    end
    
    
    % Parse .mdoc
    mdoc_param = tm_parse_mdoc([p.root_dir,p.raw_stack_dir,mdoc_dir(i).name],mdoc_fields,mdoc_field_types);
    n_tilts = numel(mdoc_param);
    
    % Check for raw stack
   if exist([p.raw_stack_dir,name,p.raw_stack_ext],'file')
        % Same basename without ext
        raw_stack_name = [name,p.raw_stack_ext];         
   elseif exist([p.raw_stack_dir,name],'file')
        % Same basename with ext. Sometimes SerialEM does this...
        raw_stack_name = name;   
   else 
        raw_stack_name = name; 
        warning([p.name,'ACHTUNG!!! Raw stack for tomogram ',name,' missing!!!']);
        if ~s.ignore_raw_stacks
            warning([p.name,'ACHTUNG!!! Skipping stack ',name,'!!!']);
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
                [~,fname,ext] = tm_fileparts_windows(mdoc_param(j).SubFramePath);
            case 'linux'
                [~,fname,ext] = fileparts(mdoc_param(j).SubFramePath);
        end
        
        % Store frame name
        frame_names{j} = [fname,ext]; 
        
%         Not sure why this is needed... .eer is in the .mdoc
%         if p.if_eer            
%             % Store frame name
%             frame_names{j} = [name,'.eer'];        
%         else
%             % Store frame name
%             frame_names{j} = [name,ext];            
%             
%         end
        
        % Check for existence of frame
        if ~exist([p.root_dir,p.raw_frame_dir,frame_names{j}],'file')
            warning(['ACHTUNG!!! Frame "',frame_names{j},'" missing from stack ',name,'!!!']);
            if ~s.ignore_missing_frames
                continue_loop = true;
            end
        end                
    end
    
    % Skip stack if frame is missing
    if continue_loop
        warning(['ACHTUNG!!! Skipping stack ',num2str(name),'!!!']);
        continue
    end
    
    
    % Store frame names
    temp_tomolist.frame_names = frame_names;
    
    % Write tilt-axis angle
    if isempty(ov.tilt_axis_angle)
        temp_tomolist.tilt_axis_angle = mdoc_param(1).TiltAxisAngle;
    else
        temp_tomolist.tilt_axis_angle = ov.tilt_axis_angle;
    end
        
    % Write tilt angles
    temp_tomolist.collected_tilts = [mdoc_param.TiltAngle]'; 
    temp_tomolist.rawtlt = temp_tomolist.collected_tilts;
    
    % Store camera files
    temp_tomolist.gainref = p.gainref;
    temp_tomolist.defects_file = p.defects_file;
    temp_tomolist.rotate_gain = p.rotate_gain;
    temp_tomolist.flip_gain = p.flip_gain;
    
    % Store mirror stack parameter
    temp_tomolist.mirror_stack = p.mirror_stack;
    
    % Store voltage
    temp_tomolist.voltage = p.voltage;
    
    % Store pixelsize
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
    if isempty(ov.target_defocus)

        if all(mdoc_param(1).TargetDefocus == [mdoc_param.TargetDefocus])
            temp_tomolist.target_defocus = mdoc_param(1).TargetDefocus;
        else
            warning([p.name,'ACHTUNG!!! ',raw_stack_name,' has varying target defocii!!!']);
            temp_tomolist.target_defocus = [mdoc_param.TargetDefocus];
        end
        
    else
        temp_tomolist.target_defocus = ov.target_defocus; 
    end
    
    % Number of frames
    if all(mdoc_param(1).NumSubFrames == [mdoc_param.NumSubFrames])
        temp_tomolist.n_frames = mdoc_param(1).NumSubFrames;
    else
        temp_tomolist.n_frames = [mdoc_param.NumSubFrames];
    end
        
    
    % Generate new folder
    disp([p.name,'Generating directories and moving files for stack ', name ,'!!!']);
    [~,tomo_dir_root,~] = fileparts(name);    % In cause the .mdoc also has the stack extension
    tomo_dir = [p.root_dir,tomo_dir_root,'/'];
    mkdir(tomo_dir);
    mkdir([tomo_dir,'frames/']);
    temp_tomolist.stack_dir = tomo_dir;
    temp_tomolist.frame_dir = [tomo_dir,'frames/'];
    
    % Link .mdoc file
    system(['ln -sf ',p.root_dir,p.raw_stack_dir,mdoc_dir(i).name,' ',tomo_dir,mdoc_dir(i).name]);
    temp_tomolist.mdoc_name = mdoc_dir(i).name;
    
    % Link raw stack
    if exist([p.raw_stack_dir,raw_stack_name],'file')
        system(['ln -sf ',p.root_dir,p.raw_stack_dir,raw_stack_name,' ',tomo_dir,raw_stack_name]);
        temp_tomolist.raw_stack_name = raw_stack_name;
    else
        warning([p.name,'ACHTUNG!!! ',raw_stack_name,' not copied as it does not exists...']);
    end      
    
    % Link frames
    for j = 1:n_tilts
        try
            system(['ln -sf ',p.root_dir,p.raw_frame_dir,frame_names{j},' ',tomo_dir,'frames/',frame_names{j}]);
        catch
            warning([p.name,'ACHTUNG!!! Error moving ',p.raw_frame_dir,frame_names{j}]);
        end
    end        

    
    % Append and save tomolist    
    if sum(numel(tomolist)) >= 1        
        temp_tomolist.tomo_num = max([tomolist.tomo_num]) + 1;
    else
        temp_tomolist.tomo_num = 1;
    end
    
    tomolist = cat(2,tomolist,temp_tomolist);
    save([p.root_dir,p.tomolist_name],'tomolist');
    disp([p.name,'Stack ',num2str(i),' of ',num2str(n_stacks),' imported...']);
end    
    
disp([p.name,'Stack Importing complete!!!']);
    

% Write parallel completion file    
if par_proc
    system(['touch ',par.comm_dir,'tomoman_import']);
end
    



