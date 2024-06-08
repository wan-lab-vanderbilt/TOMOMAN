function tm_export2warp_parallel(tomolist, export)

% % Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% % collected by SerialEM. 
% 

%% DO NOT CHANGE BELOW THIS LINE!!!!

%% Initialize
% Check for export_list
if sg_check_param(export,'export_list')
    export_list = dlmread(export.export_list);
end


%% Run pipeline!!!

% Number of stacks
n_stacks = numel(tomolist);
for i = 1:n_stacks
        
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
    end
        
    
    % Check recons_list
    if exist('export_list','var')
        if ~any(export_list == tomolist(i).tomo_num)
            process = false;
        end
    end
    
    
    % Perform tomogram reconstruction with novaCTF
    if process   
        % Export to Relion4
        tm_export2warp_export_tomogram(tomolist(i),export.output_dir,export.process_stack);
    end  
end

end

