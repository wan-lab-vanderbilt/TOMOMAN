function tm_novactf_run_parallel_scripts(p,tomolist,n_stacks)
%% tm_novactf_run_parallel_scripts
% Run novactf parallel scripts and wait for output.
%
% WW 07-2022


%% Run scripts
disp([p.name,'Preparing stacks for novaCTF in parallel...']);


% Script name
parscript_name = [tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process.sh'];

% Run script
system(parscript_name);

% % Run parallel scripts
% for i = 1:n_cores
%     
%     % File names
%     parscript_name = [tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process_',num2str(i-1),'.sh'];
%     parlog_name = [tomolist.stack_dir,'novaCTF/logs/parallel_log_',num2str(i-1),'.txt'];
%     
%     % Run script
%     unix([parscript_name,' > ',parlog_name,' 2>&1 &']);
%     
% end

% Wait for outputs
tm_wait_for_them([tomolist.stack_dir,'novaCTF/comm/'],'parallel_stack_process',n_stacks,10);

disp([p.name,'Preparation of novaCTF complete!!!']);

