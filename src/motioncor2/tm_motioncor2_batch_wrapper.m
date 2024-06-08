function tm_motioncor2_batch_wrapper(p,input_names, output_names, tomolist, mc2, dep)
%% tm_motioncor2_batch_wrapper
% A wrapper function for batch stack processing of images using MotionCor2. 
%
% SK, WW 06-2022

%% Check check

% Check names
if iscell(input_names) && iscell(output_names)
    n_img = numel(input_names);
    if n_img ~= numel(output_names)
        error([p.name,'Achtung!!! Number of input names does not match output names!!!']);
    end    
end

% Check input format
switch mc2.input_format
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
    mc2.gain_corrected = true;
else
    mc2.gain_corrected = false;
end
if ~mc2.gain_corrected

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
if strcmp(mc2.input_format,'eer')
    if ~isempty(tomolist.defects_file)
        defect_str = [' -DefectMap ',tomolist.defects_file];
    else
        error([p.name,'You must provide defect map when motion correcting EER!!!']);
    end
end
    
% EER sampling
if strcmp(mc2.input_format,'eer')
    if ~isempty(mc2.EerSampling)
        eer_sampling_str = [' -EerSampling ', num2str(mc2.EerSampling)];
    else
        error([p.name,'You must provide EER sampling when motion correcting EER!!!']);
    end
end

% Pixel size string 
if strcmp(mc2.input_format,'eer')
    pixelsize_str = [' -PixSize ',num2str(tomolist.pixelsize.*(1./mc2.EerSampling),'%f')];
else
    pixelsize_str = [' -PixSize ',num2str(tomolist.pixelsize,'%f')];
end

% Odd/Even stack
if mc2.SplitSum == 1
    splitsum_str = ' -SplitSum 1 ';
else
    splitsum_str = '';
end
% Parse other parameters
other_param = tm_motioncor2_argument_parser(mc2);


%% Run motioncor2

% Open run script
mc2_script = [tomolist.stack_dir,'MotionCor2/run_motioncor2.sh'];
fid = fopen(mc2_script,'w');

% Parse MotionCor2 commands
for i = 1:n_img
    
    % Check for dose filtering
    if mc2.dose_filter
        
        
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
    if strcmp(mc2.input_format,'eer')
        if ~isempty(mc2.FmIntFile)
            fmintfile_str = [' -FmIntFile ',mc2.FmIntFile];
        	
        else
            if ~isempty(mc2.EerGrouping)
                [~,header] = system(['header -eer ', input_names{i},' | grep "Number of columns"']);
                headersplit = split(header);
                eer_frames = str2num(headersplit{end-1});
                dose_fractions = [eer_frames,mc2.EerGrouping,0];
                warning(['EER frames: ', num2str(eer_frames),', Dose fractions: ',num2str(floor(eer_frames./mc2.EerGrouping)), ', Exluded frames: ', num2str(mod(eer_frames,mc2.EerGrouping))]);
                fmintfile = [tomolist.stack_dir,'/MotionCor2/fmintfile.txt'];
                dlmwrite(fmintfile,dose_fractions,'delimiter','\t');
                fmintfile_str = [' -FmIntFile ',fmintfile];
            
            else
                error([p.name,'You must provide either EER grouping or FmIntFile when motion correcting EER!!!']);
            end
        end
    end   
    
    % combine EER string
    if strcmp(mc2.input_format,'eer')
        eer_str = [defect_str,eer_sampling_str,fmintfile_str,pixelsize_str];
    else
        eer_str = '';
    end
    
    mc2_cmd = [dep.motioncor2,' ',in_str,input_names{i},' -OutMrc ',output_names{i},' -LogFile ',output_names{i},'.log ',gain_str,dosefilter_str,eer_str,other_param,splitsum_str];
    fprintf(fid,'%s\n',mc2_cmd);
    
    
end
% Close script
fclose(fid);

% Run MotionCor2
system(['chmod +x ',mc2_script]);
system(mc2_script);



