function tm_isonet2_make_particle_mask(tomolist, p, isonet2, dep, par)
%% tm_isonet2_make_particle_mask
% Run IsoNet2 to make particle masks before refine training. This takes in
% either a STOPGAP motivelist or generic particle list and places a cube at
% each particle position. For particle list, the format is a 4 column table
% with tomo_num, x, y, z. 
%
% WW 02-2026


%% Initialize
disp([p.name,'Generating particle masks for IsoNet2 training!!!1!']);


% Check directories
isonet2_dir = [p.root_dir,isonet2.isonet2_dir];
output_dir = [isonet2_dir,isonet2.mask_subdir];
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

% Parse star name
input_star_name = [isonet2_dir,isonet2.star_filename];

% Read input star
input_star = stopgap_star_read(input_star_name);
proc_tomo_num = [input_star.rlnIndex];      % Parse tomo_num
    
% Check for subset_list
if sg_check_param(isonet2,'subset_list')
    % Read subset list
    subset_list = dlmread([p.root_dir,isonet2.subset_list]);
    
    % Parse tomo_num to be processed
    proc_tomo_num = intersect(proc_tomo_num,subset_list);
    n_tomos = size(subset_list,1);
        
else
    n_tomos = numel(input_star);
end


% Split for parallel processing
if ~isempty(par)
    
    % Calculate job array
    job_array = tm_job_array(n_tomos,par.n_tasks);

    % Check number of jobs
    if par.task_id > size(job_array,1)         % Return empty arrays if too many tasks for jobs
        disp([p.name,'No tomograms assigned to this task...']);
        return        
    else
        % Parse tomograms
        proc_tomo_num = proc_tomo_num(job_array(par.task_id,2):job_array(par.task_id,3));
    end

end
    

%% Read motive/particle list

if sg_check_param(isonet2,'sg_motl_name')    
    
    % Read motivliest
    motl = sg_motl_read2(tm_check_absolute_path(p.root_dir,isonet2.sg_motl_name));
    list_type = 'motl';
    
elseif sg_check_param(isonet2,'point_list')
    
    % Read particle list
    full_part_list = dlmread(tm_check_absolute_path(p.root_dir,isonet2.point_list));
    list_type = 'plist';
    
else
    error([p.name,'ACHTUNG!!! Either "sg_motl_name" or "point_list" is required!!!']);
end
    
% Calcualte binning factor between list and mask
binning_factor = isonet2.list_binning/isonet2.mask_binning;


%% Generate masks

% Parse tomo_num
tomo_num = [tomolist.tomo_num];

% Generate mask for each tomo
for i = proc_tomo_num

    %%%%% Prepare Particle List %%%%%
    
    % Parse particle list
    switch list_type
        case 'motl'
            
            % Parse tomogram index
            tomo_idx = motl.tomo_num == i;
            
            % Make particle list
            part_list = cat(2,...
                            round(motl.orig_x(tomo_idx)+motl.x_shift(tomo_idx)),...
                            round(motl.orig_y(tomo_idx)+motl.y_shift(tomo_idx)),...
                            round(motl.orig_z(tomo_idx)+motl.z_shift(tomo_idx)));
        case 'plist'
            
            % Parse tomogram index
            tomo_idx = motl.tomo_num == i;
            
            % Parse particle list
            part_list = full_part_list(tomo_idx,2:4);
            
    end
    n_part = size(part_list,1);
    
    % Check binnings
    if binning_factor > 1
        part_list = (part_list.*binning_factor) - (binning_factor-1);
    elseif binning_factor < 1
        part_list = part_list.*binning_factor;
    end
    
    
    %%%%% Get Tomogram Info %%%%%
    
    % Get tomo index
    t = tomo_num == i;
    
    % Parse IMOD-formatted Alignment Filenames
    switch tomolist(t).alignment_software
        case 'AreTomo'
            subfolder = 'AreTomo/';
        case 'imod'
            subfolder = 'imod/';
        otherwise 
            if startsWith(tomolist(t).alignment_software,'sg_refine_')
                subfolder = [tomolist(t).alignment_software,'/'];
            else
                error([p.name,'ACHTUNG !!! ',tomolist(t).alignment_software,' is an unsupported alignment_software type!!!']);
            end
    end
    tiltcom_name = [tomolist(t).stack_dir,subfolder,'tilt.com'];
    
    % Read tilt.com
    tiltcom = sg_read_IMOD_tiltcom(tiltcom_name);
    
    % Parse tomogram size
    tomo_size = ceil(cat(2,tiltcom.FULLIMAGE,tiltcom.THICKNESS)./isonet2.mask_binning);
    boxsize = isonet2.boxsize.*ones(1,3);
    
    %%%%% Make Mask %%%%%
    mask = zeros(tomo_size,'int16');

    for j = 1:n_part

        % Calculate coordinates
        [~, paste] = sg_calculate_paste_coords(boxsize,tomo_size,part_list(j,1:3)); 

        % Paste in mask
        mask(paste(1,1):paste(1,2),paste(2,1):paste(2,2),paste(3,1):paste(3,2)) = 1;

    end
    
    % Save mask
    [~,st_name,~] = fileparts(tomolist(t).stack_name);
    mask_name  = [p.root_dir,isonet2.isonet2_dir,isonet2.mask_subdir,st_name,'_mask.mrc'];
    sg_mrcwrite(mask_name,mask);
    disp([p.name,'Mask for ',st_name,' generated...']);
    
end

%% Update star file

% Check task_id
if ~isempty(par)
    if par.task_id ~= 1
        return
    end
end
        
% Parse indices for full dataset
proc_tomo_num = [input_star.rlnIndex];      % Parse tomo_num
    
% Check for subset_list
if sg_check_param(isonet2,'subset_list')
    % Read subset list
    subset_list = dlmread([p.root_dir,isonet2.subset_list]);
    
    % Parse tomo_num to be processed
    proc_tomo_num = intersect(proc_tomo_num,subset_list);
end

% Update rlnMaskName fields
for i = proc_tomo_num
    
    % Parse mask name
    t = tomo_num == i;
    [~,st_name,~] = fileparts(tomolist(t).stack_name);
    mask_name  = [p.root_dir,isonet2.isonet2_dir,isonet2.mask_subdir,st_name,'_mask.mrc'];
    
    % Update mask
    star_idx = [input_star.rlnIndex] == i;
    input_star(star_idx).rlnMaskName = mask_name;
end

% Write star file
stopgap_star_write(input_star,input_star_name,'isonet2',[],4);









