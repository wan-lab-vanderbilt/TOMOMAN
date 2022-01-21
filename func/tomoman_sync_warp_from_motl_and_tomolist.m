function tomoman_sync_warp_from_motl_and_tomolist(motl,tomolist,warp_targetfolder)


rlist = unique([motl.tomo_num]);

% Get indices of tomograms to export to warp
[~,r_idx] = intersect([tomolist.tomo_num],rlist);

% Check for skips
skips = [tomolist(r_idx).skip];
if any(skips)
    skip_list = rlist(skips);
    for i = numel(skip_list)
        warning(['ACHTUNG!!! Tomogram ',num2str(skip_list(i)),' was set to skip!!!']);
    end
    
    % Update lists
    rlist = rlist(~skips);
    r_idx = r_idx(~skips);
       
end
n_tomos = numel(rlist);
for i  = 1:n_tomos
    
    % Parse tomolist
    t = tomolist(r_idx(i));



    tomo_num = sprintf('%03d',t.tomo_num);
    [~,stack_name,~] = fileparts(t.dose_filtered_stack_name);
    xf_sourcename = [t.stack_dir '/' stack_name, '.xf'];
    xf = dlmread(xf_sourcename);
    xf_targetname = [warp_targetfolder,'/tilts/imod/',tomo_num,'/',tomo_num, '.xf'];
    link_cmd = ['ln -sf ' xf_sourcename, ' ', xf_targetname];
    system(link_cmd);
    fid = fopen(xf_targetname,'w');
    for j = 1:size(xf,1)
        fprintf(fid,'%20.8f%20.8f%20.8f%20.8f%20.8f%20.8f\n',xf(j,1),xf(j,2),xf(j,3),xf(j,4),xf(j,5),xf(j,6));
    end
    fclose(fid);
    

end
clear