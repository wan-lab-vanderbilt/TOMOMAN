function tm_isonet_cat_star_files(p,isonet,par)
%% tm_isonet_cat_star_files
% A function to concatenate IsoNet star files when running isonet_prepare
% in parallel.
%
% WW 06-2025

%% Compile results

% Read star files
star_cell = cell(par.n_tasks,1);
for i = 1:par.n_tasks
    star_cell{i} = stopgap_star_read([p.root_dir,isonet.isonet_dir,isonet.output_star,'_',num2str(i)]);
end
cat_star = cat(1,star_cell{:});

% Write new star
stopgap_star_write(cat_star,[p.root_dir,isonet.isonet_dir,isonet.output_star]);

disp([par.name,'Full star file written!!!']);

    
    