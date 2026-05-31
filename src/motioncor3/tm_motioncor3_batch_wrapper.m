function tm_motioncor3_batch_wrapper(p,input_names, output_names, tomolist, mc3, dep)
%% tm_motioncor3_batch_wrapper
% A wrapper function for batch stack processing of images using MotionCor3. 
%
% SK, WW 08-2025

%% Check check

% Check names
if iscell(input_names) && iscell(output_names)
    n_img = numel(input_names);
    if n_img ~= numel(output_names)
        error([p.name,'Achtung!!! Number of input names does not match output names!!!']);
    end    
end

% Check input format
switch mc3.input_format
    case 'tiff'
        in_str = '-InTiff ';
    case 'mrc'
        in_str = '-InMrc ';
    case 'eer'
        in_str = '-InEer ';
    otherwise
        error([p.name,'Invalid input_format!!!']);
end


% Gainref
if isempty(tomolist.gainref) || strcmp(tomolist.gainref,'none')
    mc3.gain_corrected = true;
else
    mc3.gain_corrected = false;
end
if ~mc3.gain_corrected

    % Check if gainref exists
    if ~exist(tomolist.gainref,'file')
        error([p.name,'Gain reference file does not exist!!!'])
    else
        gain_str = [' -Gain ',tomolist.gainref];
    end   
    
    % Add gainref parameters to param_str
    if ~isempty(tomolist.rotate_gain)
        gain_str = [gain_str,' -RotGain ',num2str(tomolist.rotate_gain,'%i')];
    end
    if ~isempty(tomolist.flip_gain)
        gain_str = [gain_str,' -FlipGain ',num2str(tomolist.flip_gain,'%i')];
    end
    
else
    
    gain_str = '';

end

% Defect map
if strcmp(mc3.input_format,'eer')
    if ~isempty(tomolist.defects_file)
        defect_str = [' -DefectMap ',tomolist.defects_file];
    else
%         error([p.name,'You must provide defect map when motion correcting EER!!!']);
        defect_str = '';
    end
end
    
% EER sampling
if strcmp(mc3.input_format,'eer')
    if ~isempty(mc3.EerSampling)
        eer_sampling_str = [' -EerSampling ', num2str(mc3.EerSampling)];
    else
        error([p.name,'You must provide EER sampling when motion correcting EER!!!']);
    end
end

% Pixel size string 
if strcmp(mc3.input_format,'eer')
    pixelsize_str = [' -PixSize ',num2str(tomolist.pixelsize.*(1./mc3.EerSampling),'%f')];
else
    pixelsize_str = [' -PixSize ',num2str(tomolist.pixelsize,'%f')];
end

% Odd/Even stack
if mc3.SplitSum == 1
    splitsum_str = ' -SplitSum 1 ';
else
    splitsum_str = '';
end

% CTF estimatino
if sg_check_param(mc3,'CTF_est')
    ctf_str = [' -Cs ',num2str(mc3.Cs,'%f'),' -AmpCont ',num2str(mc3.AmpCont,'%f'),' -ExtPhase ',num2str(mc3.ExtPhase,'%f')];
else
    ctf_str = '';
end

% Parse other parameters
mc3.kV = tomolist.voltage;
other_param = tm_motioncor3_argument_parser(mc3);


%% Run motioncor3

% Open run script
mc3_script = [tomolist.stack_dir,'MotionCor3/run_motioncor3.sh'];
fid = fopen(mc3_script,'w');

% Parse MotionCor3 commands
for i = 1:n_img
    
    % Check for dose filtering
    if mc3.dose_filter
        
        
        % Initial dose
        if i == 1
            init_dose = 0;
        else
            init_dose = tomolist.dose(i-1);
        end
        init_dose_str = [' -InitDose ',num2str(init_dose,'%f')];
        
        % Dose per frame
        if i == 1
            img_dose = tomolist.dose(1);
        else
            img_dose = tomolist.dose(i)-tomolist.dose(i-1);
        end        
        dpf_str = [' -FmDose ',num2str(img_dose./tomolist.n_frames,'%f')];
        
        % Concatenate string
        dosefilter_str = [pixelsize_str,init_dose_str,dpf_str];
    else
        dosefilter_str = '';
    end
    
    % EER grouping
    if strcmp(mc3.input_format,'eer')
        if ~isempty(mc3.FmIntFile)
            fmintfile_str = [' -FmIntFile ',mc3.FmIntFile];
        	
        else
            if ~isempty(mc3.EerGrouping)
                [~,header] = system(['header -eer ', input_names{i},' | grep "Number of columns"']);
                headersplit = split(header);
                eer_frames = str2num(headersplit{end-1});
                dose_fractions = [eer_frames,mc3.EerGrouping,0];
                excluded_frames = mod(eer_frames,mc3.EerGrouping);
                if excluded_frames ~= 0
                    warning(['EER frames: ', num2str(eer_frames),', Dose fractions: ',num2str(floor(eer_frames./mc3.EerGrouping)), ', Exluded frames: ', num2str(excluded_frames)]);
                end
                fmintfile = [tomolist.stack_dir,'/MotionCor3/fmintfile.txt'];
                dlmwrite(fmintfile,dose_fractions,'delimiter','\t');
                fmintfile_str = [' -FmIntFile ',fmintfile];
            
            else
                error([p.name,'You must provide either EER grouping or FmIntFile when motion correcting EER!!!']);
            end
        end
    end   
    
    % combine EER string
    if strcmp(mc3.input_format,'eer')
        eer_str = [defect_str,eer_sampling_str,fmintfile_str];
    else
        eer_str = '';
    end
    
    mc3_cmd = [dep.motioncor3,' ',in_str,input_names{i},' -OutMrc ',output_names{i},' -LogDir ',tomolist.stack_dir,'MotionCor3/',gain_str,dosefilter_str,eer_str,pixelsize_str,other_param,splitsum_str,ctf_str];
    fprintf(fid,'%s\n',mc3_cmd);
    
    
end
% Close script
fclose(fid);

% Run MotionCor3
system(['chmod +x ',mc3_script]);
system(mc3_script);



