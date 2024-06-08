function tm_relion_motioncorr_batch_wrapper(p,input_names, ali_names, tomolist, relionmc,relionmc_dir,dep,par)
%% tm_relion_motioncorr_batch_wrapper
% A wrapper function for batch stack processing of images using MotionCor2. 
%
% SK
% WW 05-2022

%% Check check

% Check names
n_img = numel(input_names);
if iscell(input_names) && iscell(ali_names)    
    if n_img ~= numel(ali_names)
        error([p.name,'Achtung!!! Number of input names does not match output names!!!']);
    end    
end

% Check motioncorr directory
if ~exist(relionmc_dir,'dir')
        mkdir(relionmc_dir);
end

% Check par array
if isempty(par)
    par.cpus_per_task = relionmc.n_cores;
end

%% Assemble input strings

% Binning factor
binfactor_str = [' --bin_factor ',num2str(relionmc.bin_factor,'%i')];

% B-factor
bfactor_str = [' --bfactor ',num2str(relionmc.bfactor,'%i')];

% Motioncor patch 
patch_str = [' --patch_x ',num2str(relionmc.patch(1),'%i'),' --patch_y ',num2str(relionmc.patch(2),'%i') ];

% EER 
switch relionmc.input_format
    case 'eer'
        [~,header] = system(['header -eer ', input_names{1},' | grep "Number of columns"']);
        headersplit = split(header);
        eer_frames = str2double(headersplit{end-1});

        relionmc.eer_grouping = floor(eer_frames./relionmc.eer_dosefractions);

        disp([p.name,'Using ' num2str(relionmc.eer_dosefractions) ' dose fractions gives EER grouping of ' num2str(relionmc.eer_grouping) ])
        eer_str = [' --eer_grouping ', num2str(relionmc.eer_grouping,'%i'), ' --eer_upsampling ', num2str(relionmc.eer_upsampling,'%i') ];
    otherwise
        eer_str = [];
end


% Gainref
if isempty(tomolist.gainref) || strcmp(tomolist.gainref,'none')
    relionmc.gain_corrected = true;
else
    relionmc.gain_corrected = false;
end

if ~relionmc.gain_corrected

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
additional_str = [' --voltage ',num2str(tomolist.voltage),' --use_own --save_noDW'];

% Write Odd/Even sums string
if relionmc.save_OddEven
    oddeven_str = ' --save_OddEven';   
else
    oddeven_str = '';
end

% % Open file for writing commands
% rmc_script = [relionmc_dir,'run_relion_motioncorr.sh'];
% fid = fopen(rmc_script,'w');
% fprintf(fid,'%s\n',['cd ',relionmc_dir]);
% 
% % Make directory for temporary MotionCorr2 files
% fprintf(fid,'%s\n',['mkdir ',relionmc_dir,'MotionCorr/']);
% 
% % Loop through tilts
% for i = 1:n_img
%     
%     % Copy input stack soft links to relion motioncorr folder (this is because of relions implementation of job directory)
%     [~,name,ext] = fileparts(input_names{i});
%     stack_str = [name,ext];
%     symlink_cmd = ['ln -sf ' , input_names{i}, ' ', relionmc_dir,stack_str];
%     fprintf(fid,'%s\n',symlink_cmd);
%     
%     % Run Relion motioncorr
%     relion_run_motioncor_cmd = [dep.relionmc,' --i ',stack_str,binfactor_str,bfactor_str,patch_str,eer_patch,gain_str,pixelsize_str,additional_str];
%     fprintf(fid,'%s\n',relion_run_motioncor_cmd);
%     
%         
%     % Copy and rename motion corrected mrc, log, shifts, and star file
%     [~,output_name,~] = fileparts(ali_names{i});
%     outputstack_str = strrep(name,'.','_');     % Relion does this replacement...
%     mv_cmd = cell(4,1);
%     mv_cmd{1} = ['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'.mrc ', ali_names{i}];
%     mv_cmd{2} = ['mv ',relionmc_dir,'/MotionCorr/',outputstack_str,'.log ', output_name,'.log ' ];
%     mv_cmd{3} = ['mv ',relionmc_dir,'/MotionCorr/',outputstack_str,'.star ', output_name,'.star '];
%     mv_cmd{4} = ['mv ',relionmc_dir,'/MotionCorr/',name,'_shifts.eps ', output_name,'_shifts.eps '];
%     for j = 1:4
%         fprintf(fid,'%s\n',mv_cmd{j});        
%     end 
%     
% end
% % Remove MotionCor temporary dir
% fprintf(fid,'%s\n','rm -rf MotionCorr/');
% 
% % Close command file
% fclose(fid);
% 
% % Run Relion Motioncorr
% system(['chmod +x ',rmc_script]);
% system(rmc_script);
% 

% Run Relion motioncor
cd(relionmc_dir);
system(['ln -sf ../frames/*.',relionmc.input_format,' ', relionmc_dir]);

relion_import_cmd = [dep.relion_import,' --i "', '*.',relionmc.input_format,'" --ofile movies.star --angpix ' ,num2str(tomolist.pixelsize,'%f'), ' --odir ./ --do_movies'];
%disp(relion_import_cmd);
system(relion_import_cmd);

relion_run_motioncor_cmd = [dep.relionmc,' --i ','movies.star --j ',num2str(par.cpus_per_task),' --o ./MotionCorr', binfactor_str,bfactor_str,patch_str,eer_str,gain_str,pixelsize_str,additional_str,oddeven_str];
% disp(relion_run_motioncor_cmd);
system(relion_run_motioncor_cmd);


for i = 1:n_img
    % copy input stack soft links to relion motioncor folder (this is because of relions implementation of job directory)
    [~,name,~] = fileparts(input_names{i});
    stack_str = strrep(name, '.mrc', '');
    
    
    
    % Copy and rename motion corrected mrc, log, shifts, and star file
    [~,output_name,~] = fileparts(ali_names{i});
    outputstack_str = strrep(stack_str,'.','_');
    system(['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'.mrc ', ali_names{i}]);
    system(['mv ',relionmc_dir,'/MotionCorr/',outputstack_str,'.log ', output_name,'.log ' ]);
    system(['mv ',relionmc_dir,'/MotionCorr/',outputstack_str,'.star ', output_name,'.star ']);
    system(['mv ',relionmc_dir,'/MotionCorr/',stack_str,'_shifts.eps ', output_name,'_shifts.eps ']);
    
    if relionmc.save_OddEven
        system(['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'_ODD.mrc ', output_name, '_ODD.mrc']);
        system(['mv ',relionmc_dir, '/MotionCorr/',outputstack_str,'_EVEN.mrc ', output_name, '_EVN.mrc']);
    end
    
    
    
end


