function tm_isonet2_cat_star_files(p,isonet2,par)
%% tm_isonet2_cat_star_files
% A function to concatenate IsoNet2 star files when running isonet_prepare
% in parallel.
%
% WW 02-2026

%% Compile results

% Read star files
star_cell = cell(par.n_tasks,1);
for i = 1:par.n_tasks
    star_cell{i} = stopgap_star_read([p.root_dir,isonet2.isonet2_dir,isonet2.star_filename,'_',num2str(i)]);
end
cat_star = cat(1,star_cell{:});

% Write new star
stopgap_star_write(cat_star,[p.root_dir,isonet2.isonet2_dir,isonet2.star_filename],'isonet2',[],4);

disp([par.name,'Full star file written!!!']);

    
    