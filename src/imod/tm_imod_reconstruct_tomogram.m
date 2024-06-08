function tm_imod_reconstruct_tomogram(t,p,stack_type,sub_dir,binning,output_dir,gpu_id)
%% tm_imod_reconstruct_tomogram
% A function to reconstruct a tomogram in IMOD.
%
% The 't' input is a single tomolist entry, 'p' contains the necessary IMOD
% parameters, 'stack_type' is the type of the image stack to be used for 
% reconstruction, 'sub_dir' is the subdirectory within the stack directory 
% to be used for temporary processing, and 'output_dir' is the directory
% for the final reconstructed tomogram.
%
% WW 06-2023

%% Initialize

%%%%% Parse stackname %%%%%

% Parse stack basename
switch stack_type(1:2)
    case 'df'
        [~,name,ext] = fileparts(t.dose_filtered_stack_name);
        df = true;
    otherwise
        [~,name,ext] = fileparts(t.stack_name);
        df = false;
end

% Parse suffix
if df
    subtype = stack_type(4:end);
else
    subtype = stack_type;
end
switch subtype
%     case 'w'
%         subtype = '_whitened';
    case ""
        subtype = [];
    case ''
        subtype = [];
    case 'odd'
        subtype = '_ODD';
    case 'even'
        subtype = '_EVN';
    otherwise
        warning(['TOMOMAN: Achtung!!! Unsupported type subtype: "',subtype,'"!!! Ignoring subtype!!!']);
        subtype = [];
end
        
% Assemble stack name
stack_name = [name,subtype,ext];

% switch stack_type
%     case 'r'
%         stack_name = t.stack_name;
%     case 'w'
%         [~,name,ext] = fileparts(t.stack_name);
%         stack_name = [name,'_whitened',ext];
%     case 'df'
%         stack_name = t.dose_filtered_stack_name;
%     case 'dfw'
%         [~,name,ext] = fileparts(t.dose_filtered_stack_name);
%         stack_name = [name,'_whitened',ext];
%     case 'odd'
%         [~,name,ext] = fileparts(t.stack_name);
%         stack_name = [name,'_ODD',ext];
%     case 'even'
%         [~,name,ext] = fileparts(t.stack_name);
%         stack_name = [name,'_EVN',ext];
%     case 'dfodd'
%         [~,name,ext] = fileparts(t.dose_filtered_stack_name);
%         stack_name = [name,'_ODD',ext];
%      case 'dfeven'
%         [~,name,ext] = fileparts(t.dose_filtered_stack_name);
%         stack_name = [name,'_EVN',ext];               
% end


% Initialize temporary directory
temp_dir = [t.stack_dir,sub_dir];
if ~exist(temp_dir,'dir')
    system(['mkdir -p ',temp_dir]);
end

        

%% Read input files

% Parse IMOD-formatted Alignment Filenames
switch t.alignment_software
    case 'AreTomo'
        subfolder = 'AreTomo/';
    case 'imod'
        subfolder = 'imod/';
    otherwise  % Assume IMOD
        subfolder = 'imod/';
end
[~,name,~] = fileparts(t.dose_filtered_stack_name);         % Assume alignment using dose filtered stack
tiltcom_name = [t.stack_dir,subfolder,'tilt.com'];
tlt_name = [t.stack_dir,subfolder,name,'.tlt'];
xf_name = [t.stack_dir,subfolder,name,'.xf'];


% Read tilt.com
tiltcom = sg_read_IMOD_tiltcom(tiltcom_name);

% Read .tlt
tilts = dlmread(tlt_name);

% Parse Rotation/ TiltAxisAngle from Xform file
xf = sg_read_IMOD_xf(xf_name);






%% Reconstruct Tomogram

% Open reconstruction script
script_name = [temp_dir,'/imod_recons.sh'];
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Processing stack ',stack_name,' #####"','\n\n\n']);


%%%%% Prepare aligned stack %%%%%

% Generate aligned stack
fprintf(script,['echo "TOMOMAN: Generating aligned stack for ',stack_name,'..."\n']);
fprintf(script,['newstack -in ',t.stack_dir,stack_name,' ',...
                '-ou ',temp_dir,name,'.ali ',...
                '-xform ',xf_name,' ',...
                '-si ',num2str(tiltcom.FULLIMAGE(1)),',',num2str(tiltcom.FULLIMAGE(2)),'\n\n']);
            
 
% Erase gold
if sg_check_param(p,'erase_radius')
    efid_name = [t.stack_dir,subfolder,name,'_erase.fid'];
    if exist(efid_name,'file')
        fprintf(script,['echo "TOMOMAN: Erasing gold beads in for',stack_name,'..."\n']);
        fprintf(script,['ccderaser -input ',temp_dir,name,'.ali ',...
                        '-output ',temp_dir,name,'.ali ',...
                        '-mo ',efid_name,' ',...
                        '-be ',num2str(p.erase_radius),' ',...
                        '-or 0 -me -exc -c / ','\n\n']);
    end
end


% Taper edges
if sg_check_param(p,'taper_pixels')
    fprintf(script,['echo "TOMOMAN: Tapering edges of ',stack_name,'..."\n']);
    fprintf(script,['mrctaper -t ',num2str(p.taper_pixels),' ',...
                    temp_dir,name,'.ali ','\n\n']);
end
 
 
% CTF correction
if sg_check_param(p,'ctfphaseflip')
    
    % Parse defocus file name
    switch t.ctf_determination_algorithm
        case 'ctffind4'
            ctfphaseflipname = [t.stack_dir,'ctffind4/ctfphaseflip_ctffind4.txt'];
        case 'tiltctf'
            ctfphaseflipname = [t.stack_dir,'tiltctf/ctfphaseflip_tiltctf.txt'];
        otherwise
            disp([p.name,'ACHTUNG!!! Unsupported ctf_determination_algorithm']);
    end
    
    % Check default parameters
    if ~sg_check_param(p,'deftolerance')
        p.deftolerance = 25;
    end
    if ~sg_check_param(p,'interwidth')
        p.interwidth = 4;
    end
    if ~sg_check_param(p,'maxwidth')
        p.maxwidth = 1024;
    end
    if ~sg_check_param(p,'cs')
        p.cs = 2.7;                 % Krios default
    end
    if ~sg_check_param(p,'famp')
        p.famp = 0.07;              % CTFFIND4 default
    end
    
    
    % Write ctfphaseflip command
    fprintf(script,['echo "TOMOMAN: Running CTFphaseflip on ',stack_name,'..."\n']);
    fprintf(script,['ctfphaseflip -input ',temp_dir,name,'.ali ',...
                    '-output ',temp_dir,name,'_ctfcorr.ali ',...
                    '-angleFn ',tlt_name,' ',...
                    '-defFn ',ctfphaseflipname,' ',...
                    '-defTol ',num2str(p.deftolerance),' ',...
                    '-iWidth ',num2str(p.interwidth),' ',...
                    '-maxWidth ',num2str(p.maxwidth),' ',...
                    '-pixelSize ',num2str(t.pixelsize),' ',...
                    '-volt ',num2str(t.voltage),' ',...
                    '-cs ',num2str(p.cs),' ',...
                    '-ampContrast ',num2str(p.famp),'\n']);
%     if copy_headers == 1
%         fprintf(script_output,['copyheader ',st_dir,'/',st_name,'_ctfcorr.ali ',st_dir,'/headers/',st_name,'_ctfcorr.ali.header','\n']);
%     end
end

% Parse reconstruction stack
if sg_check_param(p,'ctfphaseflip')
    recons_st = [temp_dir,name,'_ctfcorr.ali'];
else
    recons_st = [temp_dir,name,'.ali'];
end

% Bin stack
if binning > 1
    
    fprintf(script,['echo "TOMOMAN: Fourier cropping ',stack_name,' at binning factor ',num2str(binning),'..."\n']);
    fprintf(script,['newstack -InputFile ',recons_st,' ',...
                            ' -OutputFile ',recons_st,' ',...
                            ' -FourierReduceByFactor ', num2str(binning),'\n\n']);
end

%%%%% Reconstruct Tomogram %%%%%

% Check radial
if sg_check_param(p,'radial')
    % Parse from input
    radial_string = ['-RADIAL ',num2str(p.radial(1)),',', num2str(p.radial(2)),' '];
else
    % Check existing tilt.com
    if sg_check_param(tiltcom,'RADIAL')
        % Parse from tilt.com
        radial_string = ['-RADIAL ',num2str(tiltcom.RADIAL(1)),',', num2str(tiltcom.RADIAL(2)),' '];
    else
        % Empty
        radial_string = '';
    end
end

% Check GPU
if isempty(gpu_id)
    gpu_str = [];
else
    gpu_str = ['-UseGPU ',num2str(gpu_id),' '];
end

% Check FakeSIRTIteration
if sg_check_param(p,'fakesirtiter')
    fakesirt_string=['-FakeSIRTiterations ',num2str(p.fakesirtiter), ' '];
else
    fakesirt_string=[];
end



% Write tilt command
fprintf(script,['echo "Reconstruct tomogram with tilt','..."\n']);
fprintf(script,['tilt ',...
               '-InputProjections ',recons_st,' ',...
               '-OutputFile ',temp_dir,num2str(t.tomo_num),subtype,'.rec ',...
               '-IMAGEBINNED ',num2str(binning),' ',...
               '-TILTFILE ',tlt_name,' ',...
               '-THICKNESS ',num2str(tiltcom.THICKNESS),' ',...
               '-FalloffIsTrueSigma 1 ',...
               '-XAXISTILT ',num2str(tiltcom.XAXISTILT),' ',...
               '-PERPENDICULAR  ',...
               radial_string,...,...
               '-MODE 2 ',...
               '-FULLIMAGE ',num2str(tiltcom.FULLIMAGE(1)),',', num2str(tiltcom.FULLIMAGE(2)),' ',...
               '-SUBSETSTART ',num2str(tiltcom.SUBSETSTART(1)),',', num2str(tiltcom.SUBSETSTART(2)),' ',...
               '-AdjustOrigin  ',...
               '-OFFSET ',num2str(tiltcom.OFFSET),' ',...
               gpu_str,...
               '-ActionIfGPUFails 1,1 ',...
               fakesirt_string,...
               '-SHIFT ',num2str(tiltcom.SHIFT(1)),',', num2str(tiltcom.SHIFT(2)),' \n\n\n']);
            
            

% Rotate Tomogram
fprintf(script,'echo "Rotating tomogram about X..."\n');
fprintf(script,['clip rotx ',temp_dir,num2str(t.tomo_num),subtype,'.rec ',...
                output_dir,num2str(t.tomo_num),subtype,'.rec ','\n\n']);


% Cleanup temporary files
fprintf(script,['echo "Tomogram reconstruction complete!!! Cleaning up temporary files...','"\n']);
fprintf(script,['rm -f ',temp_dir,'*.ali\n']);         % Cleanup aligned stacks
fprintf(script,['rm -f ',temp_dir,'*.rec\n']);         % Cleanup reconstructions
fprintf(script,['rm -f ',temp_dir,'*~\n\n\n\n\n']);    % Cleanup temporary files

% Close script
fclose(script);    

% Make executable
system(['chmod +x ',script_name]);


%% Run Script

system(script_name);


        
