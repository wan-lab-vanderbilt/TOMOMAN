function tm_export2warp_final(tomolist, export)


%% Initialize

% read motl and wedgelist
if exist(export.sg_motl,'file')
    motl = sg_motl_read(export.sg_motl);
else
    error('Motl not found!!!');
end

particlestar_name = [export.output_dir,'/particles.star'];
apix = tomolist(1).pixelsize;

tm_sgmotl2relion3(motl, tomolist, particlestar_name, apix)
disp('Export finished!!!');
end

