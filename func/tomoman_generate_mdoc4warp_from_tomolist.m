function tomoman_generate_mdoc4warp_from_tomolist(motl,tomolist,warp_targetfolder,motionmethod)


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

    dose = t.dose(1);
    tilt_axis_angle = t.tilt_axis_angle;


    tomo_num = sprintf('%03d',t.tomo_num);
    mdoc_name = [warp_targetfolder,'/mdocs/',tomo_num,'.mdoc'];
    
    tilts_folder = [warp_targetfolder,'/tilts/'];
    
    %%step 1: get rid of deleted images, 
    %%tilts: tilt angles from neg to pos; tilt_idx: collection order, start
    %%with 1 


    [tilts,tilt_idx] = setdiff(t.collected_tilts,t.removed_tilts); 

    %% sort tilts
    [tilts,t_idx] = sort(tilts,'descend');

    %% from positive to negative, tilt_id shows the order.
    tilt_idx = tilt_idx(t_idx);
    n_tilts = numel(tilts);


    dose_array = zeros(n_tilts,4);
    %% make a empty array, fulfill with the informations: #1 order of collection, #2 dose, #3 tilt angle, #4 tilt image name/image order in the stack
    dose_array(:,3) = tilts;
    dose_array(:,1) = tilt_idx;
    dose_array(:,4) = flip([1:n_tilts])';
    dose_array(:,2) = dose;

    %% sort with the collection order

    sort_dose_array = sortrows(dose_array,1);


    %prepare mdoc file

    mdoc_output = fopen(mdoc_name,'w');


    fprintf(mdoc_output,['PixelSpacing = ',num2str(t.pixelsize),'\n', 'Voltage = 300\n', 'ImageFile = ', t.stack_name, '\n','ImageSize = ',num2str(t.image_size(1)),' ',num2str(t.image_size(2)),'\n','DataMode = 1\n\n']);
    fprintf(mdoc_output,['[T = SerialEM: Fake mdoc for warp. Exported from TOMOMAN         07-Oct-19  18:30:21    ]\n\n']);
    fprintf(mdoc_output,['[T =     Tilt axis angle = %4.1f, binning = 1  spot = 8  camera = 0] \n\n'], tilt_axis_angle);

    for j = 1:n_tilts
        % Parse tomogram string
        tomo_str = strrep(t.mdoc_name, '.st.mdoc', '');
        % Generate temporary output names
        relionmc_dir = [t.stack_dir,motionmethod,'/'];

        % Read image
        frame_name = [tomo_str,'_',num2str(sort_dose_array(j,1)),'.mrc'];
        
        
        %frame_name = t.frame_names{sort_dose_array(j,1)};
        
        link_frame_cmd = ['ln -sf ',relionmc_dir ,frame_name,' ', tilts_folder];
        
        system(link_frame_cmd);
        fprintf(mdoc_output, '[ZValue = %d]\n', sort_dose_array(j,1)-1);

        fprintf(mdoc_output, 'TiltAngle = %4.2f\n', sort_dose_array(j,3));
        fprintf(mdoc_output, 'ExposureDose =  %4.2f\n', sort_dose_array(j,2));
        fprintf(mdoc_output, 'SubFramePath = %s\n', frame_name);
        %fake a date and time, so that everything/dose will be well ordered
        fprintf(mdoc_output, 'DateTime = 07-Oct-19  11:41:%02d\n\n',j);
    end


    fclose(mdoc_output);

end
clear
   