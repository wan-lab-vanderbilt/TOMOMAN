%% run_ctffind
% Wrapper to run CTFFIND4
%
% WW 07-2018

function tomoman_run_ctffind_single(tomolist,input_name,ctffind,diag_name)

% Input name
%input_name = [tomolist.stack_dir,'/',ps_name];


% Parse fields from ctffind parameters
fields = fieldnames(ctffind);

% Write run file
ctffind_filename = [tomolist.stack_dir,'/ctffind4/run_ctffind.sh'];
fid = fopen(ctffind_filename,'w');
fprintf(fid,'%s\n','ctffind << fin');
fprintf(fid,'%s\n',input_name);
fprintf(fid,'%s\n',diag_name);
for i = 2:numel(fields)
    if isnumeric(ctffind.(fields{i}))
        fprintf(fid,'%s\n',num2str(ctffind.(fields{i})));
    else
        fprintf(fid,'%s\n',ctffind.(fields{i}));
    end
end
fprintf(fid,'%s\n','fin');
fclose(fid);

% Run CTFFIND
system(['chmod +x ',ctffind_filename]);
system(ctffind_filename);

end


        


