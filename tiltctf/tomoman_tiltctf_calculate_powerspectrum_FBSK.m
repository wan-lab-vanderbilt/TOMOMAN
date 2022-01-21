function tomoman_tiltctf_calculate_powerspectrum(stack_dir,stack_name,output_name,target_def,pixelsize,xf_name,tlt_name,lut,ps_size,def_tol,fscaling,write_unstretched,write_negative)
%% tomoman_tiltctf_calculate_powerspectrum
% A function for calculating power spectra from tilt-stacks. 
%
% WW 07-2018


% % % % % DEBUG
% 
% stack_dir = '/fs/gpfs03/lv03/pool/pool-plitzko/will_wan/simulations/ctf_strectching/periodogram_test/';
% stack_name = '45.st';
% output_name = './deftol_050_fourier2/ps45';
% 
% target_def = 3;
% pixelsize = 1.35;
% 
% xf_name = '45-dose_filt.xf';
% tlt_name = '45-dose_filt.tlt';
% lut_name = 'tiltctf_lut_2.csv';
% 
% ps_size = 512;
% def_tol = 0.05;
% fscaling = 2;
% 
% write_unstretched = true;
% write_negative = true;


%% Initialize
disp(['Calculating tilt-adjusted power spectrum for ',stack_name]);

% Read stack
disp('Reading stack...');
stack = sg_mrcread([stack_dir,stack_name]);
image_size = [size(stack,1);size(stack,2)];
n_img = size(stack,3);

% Read numeric inputs
tilts = csvread([stack_dir,tlt_name]);
xf = dlmread([stack_dir,xf_name]);
% lut = dlmread([stack_dir,lut_name]);

% Generate grid
disp('Calculating grid...');
[grid_points,d_offsets] = tomoman_tiltctf_calculate_sampling_grid(image_size, pixelsize, ps_size, def_tol, xf, tilts);
total_ft = size(grid_points,1);

% Initialize volumes
p_ps_stack = zeros(ps_size,ps_size,n_img);
if write_unstretched
    u_ps_stack = zeros(ps_size,ps_size,n_img);
end
if write_negative
    n_ps_stack = zeros(ps_size,ps_size,n_img);
end


% Find defocus closes to target
[~,def_idx] = min(abs(lut(:,1)-target_def));
% Define scaling-factor function
scale_fun = @(d_off)(lut(def_idx,2).*(d_off.^2)) + (lut(def_idx,3).*d_off) +1;    % Giving defocus offset provides scaling factor


%% Calculate spectra

% Loop through each image
disp('Begin calculating FTs');

% Counter stuff
c = 0;
tic;

figure;
for i = 11:n_img
    
    % Parse positions
    pos_idx = grid_points(:,3) == i;
    temp_pos = grid_points(pos_idx,1:2);
    temp_def = d_offsets(pos_idx);
    n_pos = sum(pos_idx);
    
    % Loop through and calculate transforms
    mask=tom_spheremask(ones(256,256),90,20);
    ss=zeros(256,256);
    for j = 200:n_pos
        
        % Crop tile
        x1 = temp_pos(j,1) - floor(ps_size/2);
        x2 = x1 + ps_size - 1;
        y1 = temp_pos(j,2) - floor(ps_size/2);
        y2 = y1 + ps_size - 1;
        tile = double(stack(x1:x2,y1:y2,i));
        
        
        % Calculate amplitude
        %temp_amp = abs(fftshift(fft2(tile)));
        disp('Hack to be checked !!!!'); 
        %temp_amp=tom_ps(tom_norm(tom_smooth(tile,500),'mean0+1std'));
        temp_amp=tom_ps(tom_norm(tile,'mean0+1std').*mask);
        
        % Rescale positive
        p_scale_factor = scale_fun(temp_def(j));        % Scaling factor                
        %p_res_amp = sg_fourier_rescale_image(temp_amp,p_scale_factor*fscaling);
        p_res_amp = imresize(temp_amp,p_scale_factor*fscaling,'lanczos3');
        p_res_amp = tom_cut_out(p_res_amp,'center',[256 256]);
        
        p_ps_stack(:,:,i) = p_ps_stack(:,:,i) + p_res_amp; % Sum amplitude
            
        % Unstretched
        if write_unstretched
            u_res_amp = sg_fourier_rescale_image(temp_amp,fscaling);
            u_ps_stack(:,:,i) = u_ps_stack(:,:,i) + u_res_amp;
        end

        
        % Negative defocus scaling
        if write_negative
            n_scale_factor = scale_fun(-temp_def(j));        % Scaling factor                
            n_res_amp = sg_fourier_rescale_image(temp_amp,n_scale_factor*fscaling);
            n_ps_stack(:,:,i) = n_ps_stack(:,:,i) + n_res_amp; % Sum amplitude
        end
        
        subplot(2,3,1); tom_imagesc(p_ps_stack(:,:,i));title(['sum pos Nr ' num2str(j)]); drawnow;
        subplot(2,3,2); tom_imagesc(temp_amp);title(['unstr ind Nr ' num2str(j)]); drawnow;
        subplot(2,3,3); tom_imagesc(p_res_amp);title(['ind Nr ' num2str(j)]); drawnow;
        subplot(2,3,4); tom_imagesc(tile);title(['real Nr ' num2str(j)]); drawnow;
        ss=ss+temp_amp;
        subplot(2,3,5); tom_imagesc(temp_amp);title(['unstr ind Nr ' num2str(j)]); drawnow;
        
        % Increment FT counter
        c = c+1;
    end
    
    % Divide to calculate mean
    p_ps_stack(:,:,i) = p_ps_stack(:,:,i)./n_pos;
    if write_unstretched
        u_ps_stack(:,:,i) = u_ps_stack(:,:,i)./n_pos;
    end
    if write_negative
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
    
    
    disp(['Image ',num2str(i),' of ',num2str(n_img),' calculated... ',num2str(rt),' ',t_unit,' remaining...']);
end

        
%% Write outputs


sg_mrcwrite([stack_dir,output_name],p_ps_stack);

if write_unstretched || write_negative
    [dir,name,ext] = fileparts(output_name);
    if ~isempty(dir)
        dir = [dir,'/'];
    end
end
    
if write_unstretched
    uname = [dir,name,'_unstretched',ext];
    sg_mrcwrite([stack_dir,uname],u_ps_stack);
end
if write_negative
    nname = [dir,name,'_negative',ext];
    sg_mrcwrite([stack_dir,nname],n_ps_stack);
end




