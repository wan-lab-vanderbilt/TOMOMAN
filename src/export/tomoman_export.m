function par = tomoman_export(root_dir,paramfilename,par)
%% tomoman_export
% A function to streamline export of TOMOMAN project to other subtomogram averaging packages. At the moment we support following oprions:
%
% 1. RELION4. 
%
% 2. Warp/Relion3/M. 
%
% 3. STOPGAP: in development. I think It would be a good idea to implement to reduce all manual steps in setting up STOPGAP tm/subtomo job. 
%
% WW 06-2023

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_export_relion4.param';

%% Check check

% Check for parallel processing
par_proc = false;
if nargin == 3
    if ~isempty(par)
        par_proc = true;        
    end
else
    par = [];
end

% Check root_dir
root_dir = sg_check_dir_slash(root_dir);

%% Read inputs

% Parse task from paramfile
task = tm_parse_tasks([root_dir,paramfilename]);

% Read param
param_cell = tm_read_paramfile([root_dir,paramfilename]);

% Parse p-struct
p_fields = tm_get_basic_p();
p = tm_parse_param(p_fields,param_cell);

% Overrides for parallel processing
if par_proc    
    p.root_dir = par.root_dir;              % Root directory
end



% Parse cryocare struct
export_fields = tm_get_export_fields(task);
export = tm_parse_param(export_fields,param_cell);



% Parse node name
if par_proc
    p.name = par.name;
else
    p.name = 'TOMOMAN: ';
end



%% Initalize

% Open log
if ~par_proc
    diary([p.root_dir,p.log_name]);
else
    diary([p.root_dir,p.log_name,'_',num2str(par.task_id)]);
end
disp([p.name,' Initializing!!!']);


% Read tomolist
tomolist = tm_read_tomolist(p.root_dir,p.tomolist_name);
global_tomolist = tomolist;

% Get dependencies
dep = tm_get_dependencies(p,'linux');               % Basic linux commands
tm_check_dependencies(dep,false);                   % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Split tomolist
    switch task
        case {'export_relion4','export_warp'}
            [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par);            
    end
    if isempty(tomolist)
        return
    end
    
    
end


%% Run pipeline!!!


    
switch task
    case 'export_relion4'                        
        % Check if this is a processing node
        if ~par_proc
            proc = true;
        else
            % proc = false;
            error([p.name,'parallel export is not yet supported!!!']);
        end

        % Run process or wait
        if proc
            % Export to Relion4 pipeline
            if ~sg_check_param(export,'no_tomo_export')
                tm_export2relion4_parallel(tomolist, export);
            end
        end

    case 'export_warp'
        % Check if this is a processing node
        if ~par_proc
            proc = true;
        else
            % proc = false;
            error([p.name,'parallel export is not yet supported!!!']);
        end

        % Run process or wait
        if proc
            % Export to Relion4 pipeline
            if sg_check_param(export,'no_tomo_export')
                tm_export2warp_parallel(tomolist,export);
            end


            % compile star files 
            if sg_check_param(export,'sg_motl')
                tm_export2warp_final(global_tomolist, export);
            end
        end



    case 'stopgap'
        error('In construction!!!')
  
end    
    
% Close log
diary off


