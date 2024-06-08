function par = tomoman_pipeline(root_dir,paramfilename,par)
%% tomoman_pipeline
% Run a pipeline of tomoman tasks as directed by an input 'pipeline' file
% that defines the order of tasks to perform. 
%
% Pipeline files are plain-text lists of paramfilenames.
%
% WW 06-2022


% %%%%% DEBUG
% root_dir = [pwd,'/'];
% paramfilename = 'pipeline.param';



%% Check check

if nargin == 2
    par = [];
end


% Check root_dir
root_dir = sg_check_dir_slash(root_dir);


%% Read inputs

% Read param
fid = fopen([root_dir,paramfilename],'r');
pipeline = textscan(fid, '%s','CommentStyle','#');
fclose(fid);
pipeline = pipeline{1};

% Number of tasks
n_tasks = numel(pipeline);


%% Run tasks

for i = 1:n_tasks
    
    par = tomoman(root_dir,pipeline{i},[],par);
    
     % Recompile results
    tm_par_finish_run(par);

end



