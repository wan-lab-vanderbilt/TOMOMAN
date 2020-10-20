function tomoman_motioncor2_batch_wrapper(input_names, output_names, tomolist, mc2)
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

% Check input format
switch mc2.input_format
    case 'tiff'
        in_str = '-InTiff ';
    case 'mrc'
        in_str = '-InMrc ';
    otherwise
        error('Invalid input_format!!!');
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
        error('Gain reference file does not exist!!!')
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

% Parse other parameters
other_param = tomoman_motioncor2_argument_parser(mc2);


%% Run motioncor2

for i = 1:n_img
    
    % Check for dose filtering
    if mc2.dose_filter
        
        % Pixel size string
        pixelsize_str = [' -PixSize ',num2str(tomolist.pixelsize,'%f')];
        
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
    
    system(['motioncor2 ',in_str,input_names{i},' -OutMrc ',output_names{i},' -LogFile ',output_names{i},'.log ',gain_str,dosefilter_str,other_param]);
end






