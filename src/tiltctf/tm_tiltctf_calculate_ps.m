function tm_tiltctf_calculate_ps(p,tiltctf_paramfilename)
%% tm_tiltctf_calculate_ps
% Calculate a stretched power spectrum using the tiltctf algorithm.
%
% SK, WW 06-2022

%%%% DEBUG
% tiltctf_paramfilename = '/hd1/wwan/mintu/VUKrios_Apr22/tomoman_test/Position_5/tiltctf/Position_5_tiltctf.param';


%% Initialize

% Read param
param_cell = tm_read_paramfile(tiltctf_paramfilename);

% Parse are-struct
tctf_fields = tm_get_tiltctf_ps_fields();
tctf = tm_parse_param(tctf_fields,param_cell);



%% Read input files

% Read numeric inputs
tilts = csvread(tctf.tlt_name);
xf = dlmread(tctf.xf_name);
lut = dlmread(tctf.lut_name);

% Parse stack name
[stack_dir,stack_name,~] = fileparts(tctf.stack_name);
stack_dir = [stack_dir,'/'];

disp([p.name,'Calculating tilt-adjusted power spectrum for ',stack_name]);

% Read stack
disp([p.name,'Reading stack...']);
stack = sg_mrcread(tctf.stack_name);
image_size = [size(stack,1);size(stack,2)];
n_img = size(stack,3);


%% Calculate grids for periodogram sampling

% Generate grid
disp([p.name,'Calculating grid...']);
[grid_points,d_offsets] = tm_tiltctf_calculate_sampling_grid(image_size, tctf.pixelsize, tctf.ps_size, tctf.def_tol, xf, tilts, tctf.xtilt);
total_ft = size(grid_points,1);

% Initialize volumes
p_ps_stack = zeros(tctf.ps_size,tctf.ps_size,n_img);
if sg_check_param(tctf,'write_unstretched')
    u_ps_stack = p_ps_stack;
end
if sg_check_param(tctf,'write_negative')
    n_ps_stack = p_ps_stack;
end


% Find defocus closes to target
[~,def_idx] = min(abs(lut(:,1)-abs(tctf.target_def)));
% Define scaling-factor function
scale_fun = @(d_off)(lut(def_idx,2).*(d_off.^2)) + (lut(def_idx,3).*d_off) +1;    % Giving defocus offset provides scaling factor


%% Calculate spectra

% Loop through each image
disp([p.name,'Begin calculating FTs']);

% Calculate masks
[tile_mask, m_idx, n_pix] = tm_tiltctf_calculate_tile_mask(tctf.ps_size,20,'circle');

% Counter stuff
c = 0;
tic;

%figure;
for i = 1:n_img
    
    % Parse grid positions
    pos_idx = grid_points(:,3) == i;
    temp_pos = grid_points(pos_idx,1:2);
    temp_def = d_offsets(pos_idx);
    n_pos = sum(pos_idx);
    
    % Loop through and calculate transforms
%     %diagnostic
%     ss=zeros(256,256);
    for j = 1:n_pos
        
        % Crop tile
        x1 = temp_pos(j,1) - floor(tctf.ps_size/2);
        x2 = x1 + tctf.ps_size - 1;
        y1 = temp_pos(j,2) - floor(tctf.ps_size/2);
        y2 = y1 + tctf.ps_size - 1;
        tile = double(stack(x1:x2,y1:y2,i));
        
        
        % Calculate amplitude
        %temp_amp = abs(fftshift(fft2(tile)));ORIG
        
        %edit SK FB
        %disp('Hack to be checked !!!!'); 
        %temp_amp=tom_ps(tom_norm(tom_smooth(tile,500),'mean0+1std'));
        %temp_amp=tom_ps(tom_norm(tile,'mean0+1std').*mask);
        
        % Preprocess tile and calculate amplitude
%         temp_amp = abs(fftshift(fft2(tomoman_tiltctf_prepare_tile(tile,20,'circle'))));
        temp_amp = abs(fftshift(fft2(tm_tiltctf_prepare_tile(tile, tile_mask, m_idx, n_pix))));
 
        
        
        % Rescale positive
        p_scale_factor = scale_fun((tctf.handedness).*temp_def(j));        % Scaling factor  
        
        
        p_res_amp = sg_fourier_rescale_image(temp_amp,p_scale_factor*tctf.fscaling); %ORIG
        %p_res_amp = imresize(temp_amp,p_scale_factor*fscaling,'lanczos3');
        %p_res_amp = tom_cut_out(p_res_amp,'center',[256 256]);
        %p_res_amp = tomoman_tiltctf_realspace_rescale_ps(temp_amp,p_scale_factor*fscaling);
        
        p_ps_stack(:,:,i) = p_ps_stack(:,:,i) + p_res_amp; % Sum amplitude
            
        % Unstretched
        if sg_check_param(tctf,'write_unstretched')
            u_res_amp = sg_fourier_rescale_image(temp_amp,tctf.fscaling);
            %u_res_amp = tomoman_tiltctf_realspace_rescale_ps(temp_amp,fscaling);
            u_ps_stack(:,:,i) = u_ps_stack(:,:,i) + u_res_amp;
        end

        
        % Negative defocus scaling
        if sg_check_param(tctf,'write_negative')
            n_scale_factor = scale_fun(-(tctf.handedness).*temp_def(j));        % Scaling factor                
            n_res_amp = sg_fourier_rescale_image(temp_amp,n_scale_factor*tctf.fscaling);
            %n_res_amp = tomoman_tiltctf_realspace_rescale_ps(temp_amp,n_scale_factor*fscaling);
            n_ps_stack(:,:,i) = n_ps_stack(:,:,i) + n_res_amp; % Sum amplitude
        end
        
        % Diagnostic plots        
        if sg_check_param(tctf,'visualdebug')
            subplot(2,3,2); tom_imagesc(n_ps_stack(:,:,i));title(['sum neg PS Nr ' num2str(j)]); drawnow;
            subplot(2,3,5); tom_imagesc(p_ps_stack(:,:,i));title(['sum pos PS Nr ' num2str(j)]); drawnow;
            subplot(2,3,6); tom_imagesc(p_res_amp);title(['pos PS Nr ' num2str(j)]); drawnow;
            subplot(2,3,1); tom_imagesc(tile);title(['real Nr ' num2str(j)]); drawnow;
            %ss=ss+temp_amp;
            %subplot(2,3,4); tom_imagesc(tomoman_tiltctf_prepare_tile(tile,10));title(['real masked Nr ' num2str(j)]); drawnow;
            subplot(2,3,4); tom_imagesc(u_res_amp);title(['PS Nr ' num2str(j)]); drawnow;
            subplot(2,3,3); tom_imagesc(u_ps_stack(:,:,i));title(['sum unstr PS Nr ' num2str(j)]); drawnow;       
        end
        % Increment FT counter
        c = c+1;
    end
    
    % Divide to calculate mean
    p_ps_stack(:,:,i) = p_ps_stack(:,:,i)./n_pos;
    if sg_check_param(tctf,'write_unstretched')
        u_ps_stack(:,:,i) = u_ps_stack(:,:,i)./n_pos;
    end
    if sg_check_param(tctf,'write_negative')
        n_ps_stack(:,:,i) = n_ps_stack(:,:,i)./n_pos;
    end
    
    % Counter and estimated time
    tpft = toc/c;
    rft = total_ft - c;
    rt = rft * tpft;
    if rt > 60
        rt = rt/60;
        t_unit = 'minutes';
    else
        t_unit = 'seconds';
    end
    
    
    disp([p.name,'Image ',num2str(i),' of ',num2str(n_img),' calculated... ',num2str(rt,'%-4.2f'),' ',t_unit,' remaining...']);
end

        
%% Write outputs

% Write output PS stack
sg_mrcwrite(tctf.output_name,p_ps_stack);

% Parse filename
if sg_check_param(tctf,'write_unstretched') || sg_check_param(tctf,'write_negative')
    [dir,name,ext] = fileparts(tctf.output_name);
    if ~isempty(dir)
        dir = [dir,'/'];
    end
end
 
% Write remaining stacks
if sg_check_param(tctf,'write_unstretched')
    uname = [dir,name,'_unstretched',ext];
    sg_mrcwrite(uname,u_ps_stack);
end
if sg_check_param(tctf,'write_negative')
    nname = [dir,name,'_negative',ext];
    sg_mrcwrite(nname,n_ps_stack);
end

disp([p.name,'PS calculation for stack ',stack_name,' complete!!!']);


