function tm_export2warptools_final(tomolist, export)


%% create a particle list

% read motl and wedgelist
if exist(export.sg_motl,'file')
    motl = sg_motl_read(export.sg_motl);
else
    error('Motl not found!!!');
end

particlestar_name = [export.output_dir,'/particles.star'];
apix = tomolist(1).pixelsize;

tm_sgmotl2warptools(motl, tomolist, particlestar_name, apix)
disp('Export finished!!!')

%% Initialize Warptools project
script_name = [export.output_dir,'/initialize_warptools.sh'];
fid = fopen(script_name,'w');

% Create bash file

fprintf(fid, ['#!/usr/bin/env bash\n\n', ...
              'set -e\n', ...
              'set -o nounset\n\n']);

fprintf(fid, '# Initializing WarpTools project\n\n');

fprintf(fid, '# Create frameseries settings\n\n');
fprintf(fid, ['WarpTools create_settings --folder_data tilts --folder_processing warp_frameseries ' ...
              '--output warp_frameseries.settings --extension "*.mrc" --angpix ' num2str(apix) ...
              ' --exposure ' num2str(export.pertilt_exposure) '\n\n']);

fprintf(fid, '# Run per tilt CTF estimation\n\n');
fprintf(fid, ['WarpTools fs_ctf --settings warp_frameseries.settings --grid 2x2x1 ' ...
              '--range_max 5 --range_min 40 --use_sum\n\n']);

fprintf(fid, '# Link tilt images\n\n');
fprintf(fid, ['ln -sf ' export.output_dir '/tilts/*.mrc warp_frameseries/\n\n']);

fprintf(fid, ['mkdir -p ' export.output_dir '/warp_frameseries/average\n\n']);
fprintf(fid, ['ln -sf ' export.output_dir '/tilts/*.mrc ' ...
              export.output_dir '/warp_frameseries/average/\n\n']);

fprintf(fid, '# Make sure everything is selected\n\n');
fprintf(fid, 'WarpTools change_selection --settings warp_frameseries.settings --select\n\n');

fprintf(fid, '# Import tilt series metadata from pseudo mdoc files\n\n');
fprintf(fid, ['WarpTools ts_import --mdocs mdocs --frameseries warp_frameseries ' ...
              '--tilt_exposure ' num2str(export.pertilt_exposure) ' --output tomostar\n\n']);

fprintf(fid, '# Create tiltseries settings\n\n');
fprintf(fid, ['WarpTools create_settings --output warp_tiltseries.settings ' ...
              '--folder_processing warp_tiltseries --folder_data tomostar ' ...
              '--extension "*.tomostar" --angpix ' num2str(apix) ...
              ' --exposure ' num2str(export.pertilt_exposure) ...
              ' --tomo_dimensions ' num2str(export.tomodim(1)) 'x' ...
              num2str(export.tomodim(2)) 'x' num2str(export.tomodim(3)) '\n\n']);

fprintf(fid, '# Import tilt series alignments\n\n');
fprintf(fid, ['WarpTools ts_import_alignments --settings warp_tiltseries.settings ' ...
              '--alignments imod --alignment_angpix ' num2str(apix) '\n\n']);

fprintf(fid, '# Check defocus handedness\n\n');
fprintf(fid, 'WarpTools ts_defocus_hand --settings warp_tiltseries.settings --check\n\n');

fprintf(fid, '# Perform CTF estimation for tilt series\n\n');
fprintf(fid, 'WarpTools ts_ctf --settings warp_tiltseries.settings --range_high 5 --defocus_max 5\n\n');

fprintf(fid, '## NOT REALLY NEEDED, EXCEPT DEBUGGING\n');
fprintf(fid, '# Reconstruct Tomograms for visualisation OR debugging\n\n');
fprintf(fid, ['# WarpTools ts_reconstruct --settings warp_tiltseries.settings --angpix ' ...
              num2str(apix * 8) '\n\n']);

fprintf(fid, '# Export Particles\n\n');
fprintf(fid, ['# mkdir -p ' export.output_dir '/relion\n\n']);
fprintf(fid, ['# WarpTools ts_export_particles --settings warp_tiltseries.settings ' ...
              '--input_star particles.star --output_star relion/warptools4t.star ' ...
              '--output_angpix ' num2str(apix * export.particle_bin) ...
              ' --coords_angpix ' num2str(apix) ...
              ' --box ' num2str(export.particle_box) ...
              ' --diameter ' num2str(export.particle_radii) ...
              ' --relative_output_paths --3d --dont_normalize_3d --dont_normalize_input\n\n']);

fprintf(fid, '## Template for per-particle refinement\n');
fprintf(fid, '# MTools create_population --directory m --name 80S\n\n');

fprintf(fid, '# MTools create_source --name 80S --population m/80S.population --processing_settings warp_tiltseries.settings\n\n');

fprintf(fid, ['# MTools create_species --population m/80S.population --name ribosome ' ...
              '--diameter ' num2str(export.particle_radii) ...
              ' --sym C1 --temporal_samples 1 ' ...
              '--half1 m/fromsg/inv_subset_ref2_A_1.mrc ' ...
              '--half2 m/fromsg/inv_subset_ref2_B_1.mrc ' ...
              '--mask m/fromsg/bodymask.mrc ' ...
              '--angpix ' num2str(apix * export.particle_bin) ...
              ' --angpix_resample ' num2str(apix * export.particle_bin) ...
              ' --particles_relion particles.star --lowpass 15 ' ...
              '--angpix_coords ' num2str(apix) ...
              ' --angpix_shifts ' num2str(apix) '\n\n']);

fprintf(fid, '# MCore --population m/80S.population --iter 0\n\n');

fprintf(fid, '# MCore --population m/80S.population --refine_imagewarp 1x1 --refine_particles --ctf_defocus --ctf_defocusexhaustive --min_particles 8\n');
fprintf(fid, '# MCore --population m/80S.population --refine_imagewarp 1x1 --refine_particles --ctf_defocus --min_particles 8\n\n');

fprintf(fid, '# MCore --population m/80S.population --refine_imagewarp 4x4 --refine_particles --ctf_defocus --min_particles 8\n\n');

fclose(fid);

% Run script
system(['chmod +x ',script_name]);
%system(script_name);


end

