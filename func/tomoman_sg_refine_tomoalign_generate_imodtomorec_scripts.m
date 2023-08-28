function tomoman_sg_refine_tomoalign_generate_imodtomorec_scripts(t,p,tiltcom)
%% will_novactf_generate_parallel_scripts
% A function for generating a set of scripts for parallel processing of
% tilt-stacks for NovaCTF. 
%
% WW 01-2018

%% Initialize

% % Generate job array
% job_array = will_job_array(n_stacks,p.n_cores);
% n_jobs = size(job_array,1);
% if n_jobs < p.n_cores
%     disp(['ACHTUNG!!! For tomogram ',num2str(t.tomo_num),' there are fewer stacks than number of allotted cores!!!']);
% end

% Stackname
switch p.stack
    case 'r'
        stack_name = t.stack_name;
    case 'w'
        [~,name,~] = fileparts(t.stack_name);
        stack_name = [name,'-whitened.st'];
    case 'df'
        stack_name = t.dose_filtered_stack_name;
    case 'dfw'
        [~,name,~] = fileparts(t.dose_filtered_stack_name);
        stack_name = [name,'-whitened.st'];
end
        
%copy required files
[~,name,~] = fileparts(t.dose_filtered_stack_name);
% dir = t.stack_dir;
% basename = [dir '/' name];
iter_basename = [t.stack_dir,'sg_refine_tomoalign/iter',num2str(p.iteration-1),'_tomo_',num2str(t.tomo_num,['%0' num2str(p.digits) 'd'])];
new_iter_basename = [t.stack_dir,'sg_refine_tomoalign/iter',num2str(p.iteration),'_tomo_',num2str(t.tomo_num,['%0' num2str(p.digits) 'd'])];


% Parse tlt filename
tltname = [iter_basename,'.tlt'];
% Parse transform file anme
xform_file = [iter_basename,'.xf'];

tilts = dlmread(tltname);
[~,zerotlt_ndx] = min(abs(tilts+tiltcom.OFFSET));


% Check whether to use tomopitch xaxistilt
switch p.xtilt  
    case 'default'
        xaxistilt = tiltcom.XAXISTILT;

    case 'tomopitch'
        if exist([t.stack_dir,'tomopitch.log'],'file')
            tomopitch = tomoman_imod_parse_tomopitchlog([t.stack_dir,'tomopitch.log']);  
            xaxistilt = tomopitch.XAXISTILT;
        else
            xaxistilt = tiltcom.XAXISTILT;
        end
        
    case 'motl'
        disp('__UNDER_CONSTRUCTION__.... setting to default');
        xaxistilt = tiltcom.XAXISTILT;
        
    otherwise
        error('Achtung!! unsupported xtilt option!!!');
end

    

% Parse Rotation/ TiltAxisAngle from Xform file
xf = sg_read_IMOD_xf(xform_file);
tiltaxisangle = xf(zerotlt_ndx).rot; 

% Check if tiltaxisangle is too far from the initial
if abs(abs(t.tilt_axis_angle) - abs(real(tiltaxisangle))) > 5
    tiltaxisangle = t.tilt_axis_angle;
    warning('Setting tilt Axis angle to that in the Tomolist. Tilt Axis Angle was too faar from initial!!!');
end

% Generate string for newstack size
if ~isempty(p.ali_dim)
    ali_dim = ['-si ',num2str(p.ali_dim(1)),',',num2str(p.ali_dim(2)),' '];
else
    ali_dim = [];
end

%% Write parallel scripts

% Base name of parallel scripts
pscript_name = [t.stack_dir,'sg_refine_tomoalign/stack_process.sh'];

    
% Open script
pscript = fopen(pscript_name,'w');

% Write initial lines
fprintf(pscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);


% Write comment line
fprintf(pscript,['echo "##### Processing stack ',stack_name,' #####"','\n\n\n']);


            
% Perform CTF correction using IMOD
switch p.correction_type
    case '2dctf'
        fprintf(pscript,['# Perform CTF correction by CTFPHASEFLIP','\n']);
        fprintf(pscript,['ctfphaseflip ',...
                         '-InputStack ',t.stack_dir,stack_name,' ',...
                         '-OutputFileName ',t.stack_dir,'sg_refine_tomoalign/corrected_stack.st ',...
                         '-AngleFile ',iter_basename,'.tlt ',...
                         '-AxisAngle ',num2str(tiltaxisangle),' ',...
                         '-XAxisTilt ',num2str(xaxistilt),' ',...
                         '-DefocusFile ',t.stack_dir,'ctfphaseflip_',t.ctf_determination_algorithm,'.txt',' ',...
                         '-MaximumStripWidth ',num2str(tiltcom.FULLIMAGE(1)),' ',...
                         '-PixelSize ',num2str(t.pixelsize/10),' ',...
                         '-AmplitudeContrast ',num2str(p.famp),' ',...
                         '-SphericalAberration ',num2str(p.cs),' ',...
                         '-InterpolationWidth 1 ',...
                         '-DefocusTol 15 ',...
                         '-UseGPU ',p.gpustring,' ',...
                         '-ActionIfGPUFails 1,1 ',...
                         '-Voltage ',num2str(p.evk),' ',...
                         ' > ',t.stack_dir,'sg_refine_tomoalign/ctfphaseflip.log \n\n']);

        % Generate aligned stack
        fprintf(pscript,['# Generate aligned stack','\n']);
        fprintf(pscript,['newstack -in ',t.stack_dir,'sg_refine_tomoalign/corrected_stack.st ',...
                         '-ou ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                         '-xform ',iter_basename,'.xf ',...
                         ali_dim,' > ',t.stack_dir,'sg_refine_tomoalign/newst.log\n\n']);
    case 'uncorr'
        % Generate aligned stack
        fprintf(pscript,['# Generate aligned stack','\n']);
        fprintf(pscript,['newstack -in ',t.stack_dir,stack_name,' ',...
                         '-ou ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                         '-xform ',iter_basename,'.xf ',...
                         ali_dim,' > ',t.stack_dir,'sg_refine_tomoalign/newst.log\n\n']);
                     
    case '3dctf'
        % Generate aligned stack
        fprintf(pscript,['# Generate aligned stack','\n']);
        fprintf(pscript,['newstack -in ',t.stack_dir,stack_name,' ',...
                         '-ou ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                         '-xform ',iter_basename,'.xf ',...
                         ali_dim,' > ',t.stack_dir,'sg_refine_tomoalign/newst.log\n\n']);

                     
    otherwise
        error('Achtung!! unsupported ctf correction option!!!')
end

% Erase gold
if ~isempty(p.goldradius)
    if exist([t.stack_dir,name,'_erase.fid'],'file' )
        fprintf(pscript,['# Erase gold beads','\n']);
        fprintf(pscript,['ccderaser -input ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                         '-output ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                         '-mo ',t.stack_dir,name,'_erase.fid ',...
                         '-be ',num2str(p.goldradius),' ',...
                         '-or 0 -me -exc -c / ','\n\n']);
    end
end

% Taper edges
if ~isempty(p.taper_pixels)
    fprintf(pscript,['# Taper edges of aligned stack','\n']);
    fprintf(pscript,['mrctaper -t ',num2str(p.taper_pixels),' ',...
                     t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali\n\n']);
end

% Fourier crop stacks
if p.ali_stack_bin > 1
%             
%             % Calculate new dimensions
%             if ~isempty(p.ali_dim)
%                 bin_x = ceil(p.ali_dim(1)/(p.ali_stack_bin*2))*2;
%                 bin_y = ceil(p.ali_dim(2)/(p.ali_stack_bin*2))*2;                
%             else
%                 bin_x = ceil(tiltcom.FULLIMAGE(1)/(p.ali_stack_bin*2))*2;
%                 bin_y = ceil(tiltcom.FULLIMAGE(2)/(p.ali_stack_bin*2))*2;
%             end
%             newdim = [num2str(bin_x),',',num2str(bin_y),',',num2str(numel(t.rawtlt))];
%             
%             
    fprintf(pscript,['# Fourier crop aligned stack','\n']);
%             fprintf(pscript,[p.fcrop_vol,' ',...
%                              '-InputFile ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali',...
%                              '-OutputFile ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali',...
%                              '-NewDimensions ',newdim,' ',...
%                              '-MemoryLimit 2000 \n\n']);
    fprintf(pscript,[p.fcrop_stack,' ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                     t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                     num2str(p.ali_stack_bin),' > ',t.stack_dir,'sg_refine_tomoalign/fcrop.log \n\n']);
end

% % Flip stack
% fprintf(pscript,['# Flip aligned stack','\n']);
% fprintf(pscript,['clip flipyz ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali_',num2str(j),' ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali_',num2str(j),'\n\n']);
% 
% % R-filter stack
% if ~isempty(p.radial)
%     radial_str = ['-RADIAL ',num2str(p.radial(1)),' ',num2str(p.radial(2))];
% else
%     radial_str = [];
% end
% fprintf(pscript,['# R-filter flipped stack with novaCTF','\n']);
% fprintf(pscript,[p.novactf,' -Algorithm filterProjections ',...
%                  '-InputProjections ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali',...
%                  '-OutputFile ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali',...
%                  '-TILTFILE ',t.stack_dir,tltname,' ',...
%                  '-StackOrientation xz ',...
%                  radial_str,'\n\n']);

% % Local file
% if p.ta_LocalAlignments == 1
%     local_string =  ['-LOCALFILE ', new_iter_basename,'.local '];
% else
%     local_string =  '';
% end
% 
% % FakeSIRTIteration
% if ~isempty(p.fakesirtiter)
%     fakesirt_string=['-FakeSIRTiterations ',num2str(p.fakesirtiter), ' '];
% else
%     fakesirt_string='';
% end

tomorec_z = tiltcom.THICKNESS./p.ali_stack_bin;

% Reconstruct with Tomorec (Please refer to the Tomoalign Manual when editing the code. tomorec is part of the tomoalign package.)

switch p.correction_type
    case {'2dctf','uncorr'}

        fprintf(pscript,['# Reconstruct tomogram with Tomorec','\n']);
        fprintf(pscript,['tomorec ',...
                        '-i ', t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali ',...
                        '-a ', new_iter_basename,'.par ',...
                        '-o ', p.main_dir,'/',num2str(t.tomo_num),'.rec ',...
                        '-z ', num2str(tomorec_z),' > ',t.stack_dir,'sg_refine_tomoalign/tomorec.log \n\n\n']);

        % Cleanup temporary files
        fprintf(pscript,['# Cleanup temporary files','\n']);
        fprintf(pscript,['rm -f ',t.stack_dir,'sg_refine_tomoalign/corrected_stack.st\n']);    % Cleanup CTF-correction stack
        fprintf(pscript,['rm -f ',t.stack_dir,'sg_refine_tomoalign/aligned_stack.ali~\n\n\n\n\n']);    % Cleanup CTF-correction stack
        
    case '3dctf'
        
        error('Under Construction!!!');
        
end


fclose(pscript);    % Close script
% Make executable
system(['chmod +x ',pscript_name]);

        


