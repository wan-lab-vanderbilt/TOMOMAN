function tm_update_procesing_dir(tomolist_name,old_import_param_name,new_import_param_name,new_tomolist_name)
%% tm_update_procesing_dir
% A fucntion for updating the paths and links of a TOMOMAN processing
% directory. Required inputs are a tomolist_name, and two TOMOMAN import
% parameter file names. An optional new_tomolist_name can also be provided;
% otherwise the old tomolist is overwritten.
%
% The root_dir, raw_stack_dir, and raw_frame_dir parameters are parsed from
% both import parameter files and their paths are updated in the tomolist.
% The symlinks for frames and raw stack data are then updated.
%
% This function is useful when moving, sharing, or unarchiving processing
% directories.
%
% WW 10-2022

% %% DEBUG
tomolist_name = 'tomolist.mat';
old_import_param_name = 'tomoman_import.param';
new_import_param_name = 'tomoman_import_ssd.param';
new_tomolist_name = 'tomolist_ssd.mat';

%% Check check

if nargin == 3
    new_tomolist_name = tomolist_name;
elseif nargin ~= 4
    error('ACHTUNG!!! Incorrect number of inputs!!!');
end


%% Read inputs

% Read tomolist
tomolist = tm_read_tomolist('./',tomolist_name);
n_tomos = numel(tomolist);

% Read paramfiles
old_param_cell = tm_read_paramfile(old_import_param_name);
new_param_cell = tm_read_paramfile(new_import_param_name);

% Parse p-struct
p_fields = tm_get_import_p();
old_p = tm_parse_param(p_fields,old_param_cell);
new_p = tm_parse_param(p_fields,new_param_cell);


%% Update paths and links

for i = 1:n_tomos
    % Parse stack name
    [~,name,~] = fileparts(tomolist(i).mdoc_name);
    disp(['TOMOMAN: Updating paths and links for ',name,'...']);
    
    % Update root_dir
    tomolist(i).root_dir = new_p.root_dir;

    % Update stack_dir
    tomolist(i).stack_dir = strrep(tomolist(i).stack_dir,old_p.root_dir,new_p.root_dir);
    
    % Relink .mdoc
    system(['ln -sf ',new_p.root_dir,new_p.raw_stack_dir,tomolist(i).mdoc_name,' ',tomolist(i).stack_dir,tomolist(i).mdoc_name]);
    
    % Check and relink raw stack
    if sg_check_param(tomolist(i),'raw_stack_name')
        system(['ln -sf ',new_p.root_dir,new_p.raw_stack_dir,tomolist(i).raw_stack_name,' ',tomolist(i).stack_dir,tomolist(i).raw_stack_name]);
    end   
    
    % Update frame_dir
    tomolist(i).frame_dir = strrep(tomolist(i).frame_dir,old_p.root_dir,new_p.root_dir);
    
    % Relink frames
    for j = 1:numel(tomolist(i).collected_tilts)
        try
            system(['ln -sf ',new_p.root_dir,new_p.raw_frame_dir,tomolist(i).frame_names{j},' ',tomolist(i).frame_dir,tomolist(i).frame_names{j}]);
        catch
            warning([p.name,'ACHTUNG!!! Error moving ',new_p.raw_frame_dir,tomolist(i).frame_names{j}]);
        end
    end 

    disp(['TOMOMAN: Paths and links for ',name,' updated!!!']);
end


%% Write new tomolist

save(new_tomolist_name,'tomolist');





    



