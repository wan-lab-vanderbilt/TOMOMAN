function tm_isonet2_update_star(init_star,proc_star_name,output_star_name,parallel,n_cores)
%% tm_isonet2_update_star
% Compile an updated star file after running a an isonet2 process. If
% procesing was done in tomoman_parallel, this also recompiles the parallel
% results. 
%
% If parallel processing is performed, proc_star_name should be the base
% name.
%
% WW 2-2026

%% Check check

% Read init_star
if ischar(init_star)
    output_star = stopgap_star_read(init_star);
else
    output_star = init_star;
end


%% Initialize

% Initialize star cell to hold proc_star files
star_cell = cell(n_cores,1);

% Read star files
if parallel
    for i = 1:n_cores
        % Parse parallel name
        temp_name = [proc_star_name,'_',num2str(i),'.star'];
        
        % Read star file
        star_cell{i} = stopgap_star_read(temp_name);
    end
else
   star_cell{1} = stopgap_star_read(proc_star_name); 
end


%% Compile results

% Parse tomo_num
tomo_num = [output_star.rlnIndex];

% Compile new results
for i = 1:n_cores
    
    % Parse number of entries in star
    n_idx = numel(star_cell{i});
    
    % Loop over entries in star
    for j = 1:n_idx
        % Parse index
        star_idx = tomo_num == star_cell{i}(j).rlnIndex;
        
        % Update entry
        output_star(star_idx) = star_cell{i}(j);
        
    end
end

% Write output
stopgap_star_write(output_star,output_star_name,'isonet2',[],4);



