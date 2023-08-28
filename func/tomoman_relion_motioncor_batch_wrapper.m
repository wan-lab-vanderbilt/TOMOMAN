function tomoman_relion_motioncor_batch_wrapper(input_names, output_names, tomolist, relionmc,relionmc_dir)
%% tomoman_motioncor2_batch_wrapper
% A wrapper function for batch stack processing of images using MotionCor2. 
%
% WW 05-2018

%% Check check

% Check names
if iscell(input_names) && iscell(output_names)
    n_img = numel(input_names);
    if n_img ~= numel(output_names)
        error('Achtung!!! Number of input names does not match output names!!!');
    end    
end

% Binning factor
binfactor_str = [' --bin_factor ',num2str(relionmc.bin_factor,'%i')];

% B-factor
bfactor_str = [' --bfactor ',num2str(relionmc.bfactor,'%i')];

% Motioncor patch 
if  ~isempty(relionmc.patch)
    patch_str = [' --patch_x ',num2str(relionmc.patch(1),'%i'),' --patch_y ',num2str(relionmc.patch(2),'%i') ];
else
    patch_str = '';
end


% EER 
[~,header] = system(['header -eer ', input_names{1},' | grep "Number of columns"']);
headersplit = split(header);
eer_frames = str2num(headersplit{end-1});

relionmc.eer_grouping = floor(eer_frames./relionmc.dosefractions);

disp(['Using ' num2str(relionmc.dosefractions) ' dose fractions gives EER grouping of ' num2str(relionmc.eer_grouping) ])
eer_patch = [' --eer_grouping ', num2str(relionmc.eer_grouping,'%i'), ' --eer_upsampling ', num2str(relionmc.eer_upsampling,'%i') ];


% Gainref
if isempty(tomolist.gainref) || strcmp(tomolist.gainref,'none')
    mc2.gain_corrected = true;
else
    mc2.gain_corrected = false;
end

if ~mc2.gain_corrected

    % Check if gainref exists
    if ~exist(tomolist.gainref,'file')
        error('Gain reference file does not exist!!!')
    else
        gain_str = [' --gainref ',tomolist.gainref];
    end   
    
    % Add gainref parameters to param_str
    if ~isempty(tomolist.rotate_gain)
        gain_str = [gain_str,' --gain_rot ',num2str(tomolist.rotate_gain,'%i')];
    end
    if ~isempty(tomolist.flip_gain)
        gain_str = [gain_str,' --gain_flip ',num2str(tomolist.flip_gain,'%i')];
    end
    
else
    
    gain_str = '';

end

% Pixel size string
pixelsize_str = [' --angpix ',num2str(tomolist.pixelsize,'%f')];

% Additional  string
additional_str = [' --voltage 300 --use_own --save_noDW'];

% Write aliugned frame stack string
if relionmc.save_aligned_frames
    aliframe_str = ' --save_aligned_frames';    
else
    aliframe_str = '';
end



% Write Odd/Even sums string
if relionmc.save_OddEven
    oddeven_str = ' --save_OddEven';   
else
    oddeven_str = '';
end


% Run Relion motioncor
cd(relionmc_dir);
system(['ln -sf ../frames/*.eer ', relionmc_dir]);

relion_import_cmd = ['relion_import --i "', '*.eer" --ofile movies.star --angpix ' ,num2str(tomolist.pixelsize,'%f'), ' --odir ./ --do_movies'];
%disp(relion_import_cmd);
system(relion_import_cmd);

relion_run_motioncor_cmd = ['relion_run_motioncorr_mpi ',' --i ','movies.star --j 20 --o ./MotionCorr', binfactor_str,bfactor_str,patch_str,eer_patch,gain_str,pixelsize_str,additional_str,aliframe_str,oddeven_str];
% disp(relion_run_motioncor_cmd);
system(relion_run_motioncor_cmd);


for i = 1:n_img
    % copy input stack soft links to relion motioncor folder (this is because of relions implementation of job directory)
    [~,name,~] = fileparts(input_names{i});
    stack_str = strrep(name, '.mrc', '');
    
    
    
    % Copy and rename motion corrected mrc, log, shifts, and star file
    [~,output_name,~] = fileparts(output_names{i});
    outputstack_str = strrep(stack_str,'.','_');
    system(['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'.mrc ', output_names{i}]);
    system(['mv ',relionmc_dir,'/MotionCorr/',outputstack_str,'.log ', output_name,'.log ' ]);
    system(['mv ',relionmc_dir,'/MotionCorr/',outputstack_str,'.star ', output_name,'.star ']);
    system(['mv ',relionmc_dir,'/MotionCorr/',stack_str,'_shifts.eps ', output_name,'_shifts.eps ']);
    
    if relionmc.save_OddEven
        system(['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'_ODD.mrc ', output_name, '_ODD.mrc']);
        system(['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'_EVEN.mrc ', output_name, '_EVN.mrc']);
    end
    
    
    
end

% Remove MotionCor dir
system(['rm -r ',relionmc_dir,'MotionCorr']);





