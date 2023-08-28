orig_path = '/fs/gpfs06/lv03/fileset01/pool/pool-plitzko/Sagar/';
new_path = '/fs/pool/pool-plitzko/Sagar/';

tomolist_name = '/fs/pool/pool-plitzko/Sagar/Projects/riboprot/130k_multishot_2/tomo//tomolist.mat';

load(tomolist_name);

for i=1:numel(tomolist)
    tomolist(i).root_dir = strrep(tomolist(i).root_dir,orig_path,new_path);
    tomolist(i).stack_dir = strrep(tomolist(i).stack_dir,orig_path,new_path);
    tomolist(i).frame_dir = strrep(tomolist(i).frame_dir,orig_path,new_path);
    tomolist(i).gainref = strrep(tomolist(i).gainref,orig_path,new_path);
end

save(tomolist_name,'tomolist');