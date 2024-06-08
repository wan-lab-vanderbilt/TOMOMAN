function tm_fix_mdoc_brackets(input_name,output_name,backup_dir)
%% tm_fix_mdoc_brackets
% A function to remove square backets from the SubFramePath fields of .mdoc
% files. The left bracket is replaced with an underscore while the right
% bracket is removed. 
%
% WW 05-2022

%% Check inputs

% Look for backup directory
if nargin == 2
    backup_dir = '';
end

%% Backup mdoc

if ~isempty(backup_dir)
    
    % Parse mdoc name
    [path,name,ext] = fileparts(input_name);
    
    % Assemble backup name
    if ~isempty(path)
        path = [path,'/'];
    end
    backup_path = [path,backup_dir,'/'];
    backup_name = [backup_path,name,ext];
    
    % Check for directory
    if ~exist(backup_path,'dir')
        mkdir(backup_path);
    end
    
    % Copy file
    system(['cp ',input_name,' ',backup_name]);
end
    


%% Fix Brackets

% Read .mdoc file
fid = fopen(input_name,'r');
mdoc = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
mdoc = mdoc{1};

% Find SubFramePath lines
cell_idx = cellfun(@(x) contains(x,'SubFramePath'), mdoc, 'UniformOutput', false); 
idx = find([cell_idx{:}]);

% Replace brackets
for j = 1:numel(idx)
    mdoc{idx(j)} = strrep(mdoc{idx(j)},'[','_');
    mdoc{idx(j)} = strrep(mdoc{idx(j)},']','');
end

% Save new .mdoc
fopen(output_name,'w');
for j = 1:numel(mdoc)
    fprintf(fid,'%s\n',mdoc{j});
end
fclose(fid);



