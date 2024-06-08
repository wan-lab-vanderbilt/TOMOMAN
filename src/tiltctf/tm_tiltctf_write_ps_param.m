function [paramfilename, output_name] = tm_tiltctf_write_ps_param(tomolist,tctf,xtilt)
%% 
% Write parameter file for running tiltctf power spectrum calculatio. 
%
% WW 06-2022



%% Parse names

% Parse name of stack used for alignment
switch tomolist.alignment_stack
    case 'unfiltered'
        process_stack = tomolist.stack_name;
    case 'dose-filtered'
        process_stack = tomolist.dose_filtered_stack_name;
    otherwise
        error('TOMOMAN: ACTHUNG!!! Unsuppored stack!!! Only "unfiltered" and "dose-filtered" supported!!!');
end        
[~,name,~] = fileparts(process_stack);


% Parse alignment file names
switch tomolist.alignment_software
    case 'AreTomo'
        xf_name = [tomolist.stack_dir,'AreTomo/',name,'.xf'];
        tlt_name = [tomolist.stack_dir,'AreTomo/',name,'.tlt'];
    case 'imod'
        % IMOD files
        xf_name = [tomolist.stack_dir,'imod/',name,'.xf'];
        tlt_name = [tomolist.stack_dir,'imod/',name,'.tlt'];
end

% Output name        
output_name = [tomolist.stack_dir,'tiltctf/',name,'_tiltctf_ps.mrc'];

% Read lookup table
[self_path,~,~] = fileparts(which('tm_tiltctf_ctffind4'));
lut_name = [self_path,'/tiltctf_lut.csv'];
        
% Parse target defocus string
target_def = sprintf('%05.4f,',tomolist.target_defocus);            % In case you collect with a defocus range
target_def = target_def(1:end-1);


%% Write parameter file

% Open file
paramfilename = [tomolist.stack_dir,'tiltctf/',name,'_tiltctf_ps.param'];
fid = fopen(paramfilename,'w');

% Print parameters
fprintf(fid,'%s\n',['stack_name = ',tomolist.stack_dir,tomolist.stack_name]);   % Always use unfiltered stack for defocus determination 
fprintf(fid,'%s\n',['output_name = ',output_name]);
fprintf(fid,'%s\n',['target_def = ',target_def]);
fprintf(fid,'%s\n',['pixelsize = ',num2str(tomolist.pixelsize)]);
fprintf(fid,'%s\n',['xf_name = ',xf_name]);
fprintf(fid,'%s\n',['tlt_name = ',tlt_name]);
fprintf(fid,'%s\n',['lut_name = ',lut_name]);
fprintf(fid,'%s\n',['ps_size = ',num2str(tctf.ps_size)]);
fprintf(fid,'%s\n',['def_tol = ',num2str(tctf.def_tol)]);
fprintf(fid,'%s\n',['fscaling = ',num2str(tctf.fscaling)]);
fprintf(fid,'%s\n',['xtilt = ',num2str(xtilt)]);
fprintf(fid,'%s\n',['handedness = ',num2str(tctf.handedness)]);

% Optional fields
if isfield(tctf,'write_unstretched')
    fprintf(fid,'%s\n',['write_unstretched = ',num2str(tctf.write_unstretched)]);
end
if isfield(tctf,'write_negative')
    fprintf(fid,'%s\n',['write_negative = ',num2str(tctf.write_unstretched)]);
end
if isfield(tctf,'visualdebug')
    fprintf(fid,'%s\n',['visualdebug = ',num2str(tctf.visualdebug)]);
end

% Close file
fclose(fid);





