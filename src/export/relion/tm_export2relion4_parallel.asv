function tm_export2relion4_parallel(tomolist, export)
% % Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% % collected by SerialEM. 
% 
% % WW,SK


% Initialize rlnTomostar
% Check for export_list
if sg_check_param(export,'export_list')
    export_list = dlmread(export.export_list);
end

% read motl and wedgelist
if exist(export.sg_motl,'file')
    motl = sg_motl_read(export.sg_motl);
else
    error('Motl not found!!!');
end

% if exist(export.sg_wedgelist,'file')
%     wedgelist = sg_wedgelist_read(export.sg_wedgelist);
% else
%     error('Wedgelist not found!!!');
% end


rlnTomostar = struct();
rlncoords = struct();

%% Run pipeline!!!

% Number of stacks
n_stacks = numel(tomolist);

temptomostar = struct();
tempcoords = struct();

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
        % Parse subset motl
        motl_ndx = [motl.tomo_num] == tomolist(i).tomo_num;
        t_motl = motl(motl_ndx);
        
        if ~numel(t_motl) == 0
            % Export to Relion4
            % tm_export2warp_export_tomogram(tomolist(i),export.output_dir,export.process_stack);
            [temptomostar,tempcoords] = tm_export2relion4_export_tomogram(tomolist(i),t_motl,export);
        

            % concatanate tomostar and particlestar
            if i == 1
                rlnTomostar = temptomostar;
                rlncoords = tempcoords;
                
            else
                rlnTomostar = cat(1,rlnTomostar,temptomostar);
                rlncoords = cat(1,rlncoords,tempcoords);
            end
        end
        
    end

      
end

% Otput file names
tomostar_name = [export.output_dir,'/tomograms.star'];
particlestar_name = [export.output_dir,'/particles.star'];


tm_rlntomostar_write(tomostar_name,rlnTomostar);
tm_rlntomocoord2_1_write(particlestar_name,rlncoords);
    


