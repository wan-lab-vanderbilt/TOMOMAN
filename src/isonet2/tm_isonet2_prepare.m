function tm_isonet2_prepare(tomolist, p, isonet2, dep, par)
%% tm_isonet2_prepare
% A function for taking a tomolist and IsoNet2 parameters to prepare an 
% IsoNet2  star file and optionally run odd/even tomogram reconstruction.
%
% WW 02-2062


%% Initialize
disp([p.name,'Preparing star file and tomograms for IsoNet2 processing!!!1!']);


% Check for subset_list
if sg_check_param(isonet2,'subset_list')
    subset_list = dlmread([p.root_dir,isonet2.subset_list]);
else
    subset_list = [];
end

% Check directories
isonet2_dir = [p.root_dir,isonet2.isonet2_dir];
if ~exist(isonet2_dir,'dir')
    mkdir(isonet2_dir);
end
tomo_subdir = [isonet2_dir,isonet2.tomo_subdir];
if isonet2.reconstruct_tomos
    if ~exist(tomo_subdir,'dir')
        mkdir(tomo_subdir);
        mkdir([tomo_subdir,'ODD/']);
        mkdir([tomo_subdir,'EVN/']);
        mkdir([tomo_subdir,'AVG/']);
    end
end

% Parse tomogram numbers
tomo_num = [tomolist.tomo_num];

% Parse tomograms to process
proc_tomo_num = [tomolist(~[tomolist.skip] & tm_check_if_aligned(tomolist)).tomo_num];    % Parse tomo_num for non-skipped
if ~isempty(subset_list)
    proc_tomo_num = intersect(proc_tomo_num,subset_list);
end


% Split for parallel processing
if ~isempty(par)
    
    % Calculate job array
    job_array = tm_job_array(numel(proc_tomo_num),par.n_tasks);

    % Check number of jobs
    if par.task_id > size(job_array,1)         % Return empty arrays if too many tasks for jobs
        proc_tomo_num = [];
    end
    
    % Parse tomograms
    proc_tomo_num = proc_tomo_num(job_array(par.task_id,2):job_array(par.task_id,3));

end

% Parse indices
[~,proc_idx,~] = intersect([tomolist.tomo_num],proc_tomo_num);   % In case tomo_num doesn't match index in tomolist

% For boolean outputs
bool_string = {'false', 'true'};


%% Reconstruct tomograms

if isonet2.reconstruct_tomos
    
    % Parse output directory
    output_dir = cell(2,1);
    output_dir{1} = [tomo_subdir,'ODD/'];
    output_dir{2} = [tomo_subdir,'EVN/'];
    
    % Odd/even array
    odd_even = {'odd','even'};
    
    
    % Reconstruct assigned tomograms
    for i = 1:numel(proc_idx)

        % Parse index in tomolist
%         tomo_idx = tomo_num == i;
        % Parse stack basename
        switch isonet2.process_stack
            case 'dose-filtered'
                [~,name,~] = fileparts(tomolist(proc_idx(i)).dose_filtered_stack_name);
            otherwise
                [~,name,~] = fileparts(tomolist(proc_idx(i)).stack_name);
        end
        
        disp([p.name,'Preparing scripts for odd and even tomogram reconstruction of ',name]);        

        % Loop through stacks
        for j = 1:2
            
            % Check stack type
            switch isonet2.process_stack
                case 'unfiltered'
                    stack_type = odd_even{j};
                case 'dose-filtered'
                    stack_type = ['df_',odd_even{j}];
            end                        
            
            % Reconstruct tomogram in IMOD
            tm_imod_reconstruct_tomogram(tomolist(proc_idx(i)),isonet2,stack_type,'isonet2/',isonet2.binning,output_dir{j},isonet2.gpuID);
        end
        
        %%%%% Sum odd/even tomograms %%%%%        
        
        % Sum tomograms
        disp([p.name,'Summing odd/even tomograms for ',name]);
        sum_tomo = sg_mrcread([tomo_subdir,'ODD/',name,'_ODD.rec']);
        sum_tomo = sum_tomo + sg_mrcread([tomo_subdir,'EVN/',name,'_EVN.rec']);
        sg_mrcwrite([tomo_subdir,'AVG/',name,'_AVG.rec'],sum_tomo,[]);

                    
    end
end



%% Write inital star file
disp([p.name,'Preparing .star files for IsoNet2 processing...']);

% Parse star file name
if isempty(par)    
    star_name = [p.root_dir,isonet2.isonet2_dir,isonet2.star_filename];
else
    star_name = [p.root_dir,isonet2.isonet2_dir,isonet2.star_filename,'_',num2str(par.task_id)];
end

% Write starfile
tm_isonet2_initialize_star(p,tomolist(proc_idx),isonet2,star_name);


% Concatenate parallel star files
if ~isempty(par)
    
    % Write completed com
    system(['touch ',par.comm_dir,'tomoman_isonet2_prepare_',num2str(par.task_id)]);
    
    % Run process or wait
    if par.task_id == 1
        % Wait for parallel jobs
        disp([par.name,'Waiting for all tasks to finish...']);
        tm_wait_for_them(par.comm_dir,'tomoman_isonet2_prepare',par.n_tasks,5);
        
        % Assemble star files
        disp([par.name,'All parallel star files written!!! Assembling full star file...']);
        tm_isonet2_cat_star_files(p,isonet2,par); 
        
        % Write completion file
        system(['touch ',par.comm_dir,'tomoman_isonet2_prepare_star']);
        
        % Clear parallel star files
        system(['rm ',p.root_dir,isonet2.isonet2_dir,isonet2.star_filename,'_*']);
    else
        % Wait for sorting to finish
        disp([p.name,'Waiting for full star files...']);
        tm_wait_for_it(par.comm_dir,'tomoman_isonet2_prepare_star',5);  
    end
    
   
end                


end


