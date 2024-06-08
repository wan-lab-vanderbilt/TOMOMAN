function tomolist = tm_archive_tomogram(p,tomolist,archive,par)
%% tm_archive_tomogram
% TOMOMAN module for generating an archival folder for a project to be
% uploaded to EMPIAR.
%
% SK WW 09-2023


%% Check check
% Check for parallel processing
par_proc = false;
if nargin == 4
    if ~isempty(par)
        par_proc = true;
    end
end

% Skip archiving
if tomolist.skip == 1
    warning(['Achtung!! The tilt series numbered ' num2str(tomolist.tomo_num) ' was skipped during preprocessing!!!!']);
    return
end


%% Perform archival
disp(['Archiving files for: ',tomolist.stack_name,'!!!']);


% List of archival tasks
task_list = {'import','stacks','ctf','ali'};
n_tasks = numel(task_list);

% Loop through tasks
for i = 1:n_tasks
    
    % Get filenames
    filenames = tm_get_archive_filenames(task_list{i},tomolist,archive);
    
    % Rsync files
    tm_archive_sync(filenames);

end



%% Update tomolist

disp('Updating tomolist....')
tomolist.root_dir = strrep(tomolist.root_dir,p.root_dir,archive.archive_dir);
tomolist.stack_dir = strrep(tomolist.stack_dir,p.root_dir,archive.archive_dir);
tomolist.frame_dir = strrep(tomolist.frame_dir,p.root_dir,archive.archive_dir);
if ~isempty(tomolist.gainref)
    tomolist.gainref = strrep(tomolist.gainref,p.root_dir,archive.archive_dir);
end
if ~isempty(tomolist.defects_file)
    tomolist.defects_file = strrep(tomolist.defects_file,p.root_dir,archive.archive_dir);
end

%% Create metadata folder (for future developments)

% Parse archival tomogram directory
[~,name,~] = fileparts(tomolist.stack_name);
archive_tomodir = [archive.archive_dir,'/',name,'/'];

% Make metadata folder
system(['mkdir -p ',archive_tomodir,'/metadata/archival/']);


% Write archival timepoint to metadata (to avoid empty folders)
time = datestr(clock,'YYYY/mm/dd HH:MM:SS:FFF');
fid = fopen([archive_tomodir,'/metadata/archival/timepoint.log'],'w');
fprintf(fid,'%23s\n',time);
fclose(fid);


disp(['Archiving ',tomolist.stack_name,' completed!!!']);


%% Write parallel completion file    
if par_proc
    system(['touch ',par.comm_dir,'tomoman_archive']);
end


end

