orig_path = '/fs/pool/pool-chlamy/users/sagar/tomo/good';
new_path = '/raven/ptmp/skhavnek/pool-chlamy/users/sagar/tomo/good/';

tomolist_name = '/raven/ptmp/skhavnek/pool-chlamy/users/sagar/tomo/good/tomolist_tiltctf.mat';

load(tomolist_name);

for i=1:numel(tomolist)
    tomolist(i).root_dir = strrep(tomolist(i).root_dir,orig_path,new_path);
    tomolist(i).stack_dir = strrep(tomolist(i).stack_dir,orig_path,new_path);
    tomolist(i).frame_dir = strrep(tomolist(i).frame_dir,orig_path,new_path);
    tomolist(i).gainref = strrep(tomolist(i).gainref,orig_path,new_path);
end

for i=1:numel(tomolist)
    if ~tomolist(i).skip
        ctf = tomolist(i).determined_defocii;
        tomolist(i).target_defocus = -median(median(ctf(:,1:2)));
    end
end
%%
for i=1:numel(tomolist)
    if ~tomolist(i).skip
        stack_dir = tomolist(i).stack_dir ;
        cd(stack_dir);
        mkdir('AreTomo')
        movefile *.xf AreTomo/
        movefile *.tlt AreTomo/
        movefile newst.com AreTomo/
        movefile tilt.com AreTomo/
    
        tomolist(i).alignment_software = 'AreTomo';
    end
end

save(tomolist_name,'tomolist');

%%

for i=1:numel(tomolist)
    if ~tomolist(i).skip
        stack_dir = tomolist(i).stack_dir ;
        cd(stack_dir);
        mkdir('ctffind4')
        movefile ctfphaseflip_CTFFIND4-unfiltered.txt ctffind4/ctfphaseflip_ctffind4.txt
        tomolist(i).ctf_determination_algorithm = 'ctffind4';
        tomolist(i).ctf_parameters.cs = 2.700;
        tomolist(i).ctf_parameters.famp = 0.0700;

    end
end
save(tomolist_name,'tomolist');

%%

for i=1:numel(tomolist)
    if ~tomolist(i).skip
        stack_dir = tomolist(i).stack_dir;
        [~,stack_name,~] = fileparts(tomolist(i).stack_name);
        [~,dfstack_name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
        cd([stack_dir,'AreTomo/']);
        xfname_old = [stack_name '-dose_filt.xf'];
        xfname_new = [dfstack_name '.xf'];
        tltname_old = [stack_name '-dose_filt.tlt'];
        tltname_new = [dfstack_name '.tlt'];
        copyfile(xfname_old,xfname_new)
        copyfile(tltname_old,tltname_new)
    end
end


%%

tomolist_name = '/fs/pool/pool-briggs-scratch/sagar/yeast_arctis/temp_tomo/tomolist.mat';

load(tomolist_name);

for i=1:numel(tomolist)
    tomolist(i).alignment_stack = 'dose-filtered';
end

save(tomolist_name,'tomolist');
