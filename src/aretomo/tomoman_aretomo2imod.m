function tomoman_aretomo2imod(paramfilename)
%% tomoman_aretomo2imod
% A function to convert AreTomo outputs to IMOD format. Can be useful for
% downstream processing in either IMOD or NovaCTF. 
%
% Input comes from the tomoman_aretomo.param file.
%
% WW 06-2022

%%%% DEBUG
% paramfilename = 'tomoman_aretomo.param';



%% Read inputs

% Read param
param_cell = tm_read_paramfile(paramfilename);

% Parse p-struct
p_fields = tm_get_basic_p();
p = tm_parse_param(p_fields,param_cell);

% Parse are-struct
are_fields = tm_get_aretomo_fields();
are = tm_parse_param(are_fields,param_cell);



%% Initalize

diary([p.root_dir,p.log_name]);
disp('TOMOMAN Initializing!!!');


% Read tomolist
tomolist = tm_read_tomolist(p.root_dir,p.tomolist_name);


% Get dependencies
dep = tm_get_dependencies(p,'linux');                 % Basic linux commands
dep = tm_get_dependencies(p,'aretomo',dep);           % AreTomo
tm_check_dependencies(dep,false);                   % Check dependencies


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)
    
    % Convert AreTomo .aln to IMOD .xf and .tlt
    tm_aretomo2imod(tomolist(t),are);    
    
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
    
    t = t+b_size;
    
end

diary off

