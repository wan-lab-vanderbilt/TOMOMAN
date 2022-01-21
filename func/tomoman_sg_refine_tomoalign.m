function tomoman_sg_refine_tomoalign(t,p,stack)
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
dir = t.stack_dir;
basename = [dir '/' name];
iter_basename = [t.stack_dir,'sg_refine_tomoalign/iter',num2str(p.iteration-1),'_tomo_',num2str(t.tomo_num,['%0' num2str(p.digits) 'd'])];
new_iter_basename = [t.stack_dir,'sg_refine_tomoalign/iter',num2str(p.iteration),'_tomo_',num2str(t.tomo_num,['%0' num2str(p.digits) 'd'])];


%commands to creat symbolic links
ali_stackname = [stack.stack_path '/' stack.stack_name];
ali_file_cmd = ['ln -s ', ali_stackname,' ',iter_basename, '.ali'];
xf_file_cmd = ['ln -s ', basename, '.xf',' ',iter_basename, '.xf' ];
tlt_file_cmd = ['ln -s ', basename, '.tlt',' ',iter_basename, '.tlt' ];
fid_file_cmd = ['ln -s ', p.subtomo_dir,'fiducials/fiducials_',num2str(t.tomo_num,['%0' num2str(p.digits) 'd']),'.fid',' ',new_iter_basename, '.fid' ];
fidxyz_file_cmd = ['ln -s ', p.subtomo_dir,'/fiducials/orig_fiducials_',num2str(t.tomo_num,['%0' num2str(p.digits) 'd']),'.xyz',' ',new_iter_basename, '_xyz.txt' ];

system(ali_file_cmd);
system(xf_file_cmd);
system(tlt_file_cmd);
system(fid_file_cmd);
system(fidxyz_file_cmd);

% Convert the Fid file to txt

convert_cmd = ['model2point -object ' ,new_iter_basename, '.fid ' ,new_iter_basename, '_fid.txt'];
system(convert_cmd);

%% Write parallel scripts

% Base name of parallel scripts
pscript_name = [t.stack_dir,'sg_refine_tomoalign/stack_align.sh'];

    
% Open script
pscript = fopen(pscript_name,'w');

% Write initial lines
fprintf(pscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);


% Write comment line
fprintf(pscript,['echo "##### Aligning stack ',stack_name,' #####"','\n\n\n']);

% % local alignments
% if p.ta_LocalAlignments == 1
%     local_string =  ['-LocalAlignments ',num2str(p.ta_LocalAlignments),' ',...
%                     '-LocalRotOption ',num2str(p.ta_LocalRotOption),' ',...
%                     '-LocalRotDefaultGrouping ',num2str(p.ta_LocalRotDefaultGrouping),' ',...
%                     '-LocalTiltOption ',num2str(p.ta_LocalTiltOption),' ',...
%                     '-LocalTiltDefaultGrouping ',num2str(p.ta_LocalTiltDefaultGrouping),' ',...
%                     '-LocalMagOption ',num2str(p.ta_LocalMagOption),' ',...
%                     '-LocalMagDefaultGrouping 5 ',num2str(p.ta_LocalMagDefaultGrouping),' ',...
%                     '-OutputLocalFile ', new_iter_basename,'.local ',...
%                     '-NumberOfLocalPatchesXandY ',num2str(p.ta_NumberOfLocalPatchesXandY(1)), ',',num2str(p.ta_NumberOfLocalPatchesXandY(2)) ,' ',...
%                     '-MinFidsTotalAndEachSurface ',num2str(p.ta_MinFidsTotalAndEachSurface(1)), ',',num2str(p.ta_MinFidsTotalAndEachSurface(2)) ,' ',...
%                     '-MinSizeOrOverlapXandY ',num2str(p.ta_MinSizeOrOverlapXandY), ',',num2str(p.ta_MinSizeOrOverlapXandY) ,' ',...
%                     '-LocalOutputOptions ',p.ta_LocalOutputOptions];
% else
%     local_string =  '';
% end



% Perform tilt series alignment
fprintf(pscript,['# Perform tilt series alignment using Tomoalign','\n']);
fprintf(pscript, ['tomoalign ',...
                '-a ', iter_basename,'.tlt ',...
                '-i ', new_iter_basename,'_fid.txt ',...
                '-f ', new_iter_basename,'_xyz.txt ',...
                '-o ', new_iter_basename,'.par ',... %                 '-', p.tomoalign_motion,' ',...
                '-t ', p.tomoalign_t,' > ',t.stack_dir,'sg_refine_tomoalign/tomoalign.log\n\n']);
           

fclose(pscript);    % Close script
% Make executable
system(['chmod +x ',pscript_name]);
% system(pscript_name)

        


