function tomoman_export2warp_import_tomogram(t,warpdir,imod_stack,motioncor_alg)

% Parse stack name (always non dose weighted!!!)
[~,TomoName,~] = fileparts(t.stack_name);
TomoName = strrep(TomoName, '.mdoc', '');


% Parse Imo/AreTomo alignment names
switch imod_stack
    case 'unfiltered'
        [~,imod_name,~] = fileparts(t.stack_name);
    case 'dose_filt'
        [~,imod_name,~] = fileparts(t.dose_filtered_stack_name);
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
end


%% Check if the import tomo directory exists. Create new if necessary.
if ~exist(warpdir,'dir')
    error('Warp project directory not found!!!');
end

WarpImodDir = [warpdir,'/imod/',TomoName];

WarpMdocDir = [warpdir,'/mdocs/'];

WarpTiltDir = [warpdir,'/tilts/'];

if ~exist(WarpImodDir,'dir')
    mkdir(WarpImodDir);
else
    system(['rm -r ',WarpImodDir]);
    mkdir(WarpImodDir);
end

if ~exist(WarpMdocDir,'dir')
    mkdir(WarpMdocDir);
end

if ~exist(WarpTiltDir,'dir')
    mkdir(WarpTiltDir);
end


%% Check if tilt stack file exists, export tilts, and generate a fake mdoc file
stack_sourcefile = [t.stack_dir,t.stack_name];
if ~exist(stack_sourcefile,'file')
    error('Tilt stack not found. Something went seriously wrong!!!');
end
    
% Check for removed tilts
[tilts,tilt_idx] = setdiff(t.collected_tilts,t.removed_tilts); 
dose = num2cell(t.dose(tilt_idx));
n_tilts = numel(tilts);

% unsorted index (important for getting right file index for motion corrected mrc)
[sorted_tilts, ~] = sortrows(t.collected_tilts);
[~,sort_tilt_idx] = setdiff(sorted_tilts,t.removed_tilts); 

% Check if the tilts are same as aligned tilts from tlt file.
tlt_sourcefile = [t.stack_dir,'/',imod_name,'.tlt'];
aligned_tilts = dlmread(tlt_sourcefile);
n_alitilts = numel(aligned_tilts);

if n_alitilts == n_tilts
    order_dosearray = zeros(n_tilts,6);
    order_dosearray(:,1) = tilt_idx;
    order_dosearray(:,2) = aligned_tilts; % aligned tilt angles
    order_dosearray(:,3) = tilts; % tilt angles
    order_dosearray(:,4) = [dose{:}]'; % dose
    order_dosearray(:,5) = sort_tilt_idx; % index of motioncor files
    order_dosearray(:,6) = 1:n_tilts';
    sort_dose_array = sortrows(order_dosearray,1);
    %dlmwrite(OrderList_name,sort_order_array(:,1:2));
else
    error('Something is seriously wrong with tilt angles!! Check whether number of tilts match between cleaned and aligned stack!!')
end

%% Make a fake mdoc file
mdoc_name = [WarpMdocDir , '/', TomoName,'.mdoc'];

mdoc_output = fopen(mdoc_name,'w');

% header of the mdoc
fprintf(mdoc_output,['PixelSpacing = ' num2str(t.pixelsize) '\n', 'Voltage = 300\n', 'ImageFile = ', TomoName, '.mrc\n','ImageSize = ' num2str(t.image_size(1)) ' ' num2str(t.image_size(2)) '\n','DataMode = 1\n\n']);
fprintf(mdoc_output,['[T = SerialEM: Made for Warp by TOMOMAN ]\n\n']);
fprintf(mdoc_output,['[T =     Tilt axis angle = %4.1f, binning = 1  spot = 1  camera = 1] \n\n'], t.tilt_axis_angle);

% read the stack file
%[~,warp_imod_name,~] = fileparts(t.stack_name);
stack_path = [t.stack_dir t.stack_name];
stack = sg_mrcread(stack_path);


for j = 1:n_tilts
    
    % Link the correct motion corrected frame
    
    tomo_str = strrep(t.mdoc_name, '.st.mdoc', ''); % this is real bad for Tomo5!!! (FIXIT Later)
    
%     switch motioncor_alg
%         case 'relion'
%             mc_dir = [t.stack_dir,'RelionMotioncor/'];
%         case 'motioncor2'
%             mc_dir = [t.stack_dir,'Motioncor/'];
%         otherwise
%             error('only motioncor2 and relion are supported algorithms!')
%     end
%     
%     motioncor_framename = [mc_dir,tomo_str,'_',num2str(sort_dose_array(j,5)),'.mrc'];
%     
%     if ~exist(motioncor_framename,'file')
%         error('Frame not found!!')
%     end

    % link frame to tilts folder

    frame_name_target = [WarpTiltDir TomoName '_' num2str(sort_dose_array(j,5)) '.mrc'];
    
    sg_mrcwrite(frame_name_target,stack(:,:,(sort_dose_array(j,6))));
%     system(['ln -sf ' motioncor_framename ' ' frame_name_target]);

    
    % write metadata to mdoc
    
    fprintf(mdoc_output, '[ZValue = %d]\n', sort_dose_array(j,1)-1);

    fprintf(mdoc_output, 'TiltAngle = %4.2f\n', sort_dose_array(j,2));

    fprintf(mdoc_output, 'ExposureDose =  %4.2f\n', sort_dose_array(1,4));
    

    fprintf(mdoc_output, ['SubFramePath = C:\\frames\\' TomoName '_' num2str(sort_dose_array(j,5)) '.mrc\n']);

    fprintf(mdoc_output, 'DateTime = 10-JAN-92  11:%02d:%02d\n\n',(j-mod(j,60))/60,mod(j,60));

    
end

fclose(mdoc_output);

% end of loop to write star files




%% Link necessary files for IMOD

% Xf file
xf_sourcefile = [t.stack_dir,'/',imod_name,'.xf'];
xf_targetfile = [WarpImodDir,'/',TomoName,'.xf'];
if exist(xf_sourcefile,'file')
    ln_cmd = ['ln -sf ',xf_sourcefile,' ',xf_targetfile];
    system(ln_cmd);
else
    error('.xf file not found!!!');
end




end

