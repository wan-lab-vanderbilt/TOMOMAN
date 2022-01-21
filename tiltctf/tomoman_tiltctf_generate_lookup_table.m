function tomoman_tiltctf_generate_lookup_table()
%% tomoman_tiltctf_generate_lookup_table
% A function to generate a lookup table containing 2nd order polynomial
% coefficients for defocus-dependent scaling factors.
%
% WW 05-2018

%% Inputs

% Defocus options (microns)
min_def = 1;
max_def = 5;
def_step = 0.05;

% Phase shift
pshift = 0; % degrees

% Microscope options
img_size = 3712;
pixelsize = 2;
evk = 300;
famp = 0.1;
cs = 2.7;

% Fitting options
fit_range = 0.7;      % +/- defocus range around each defocus value (microns)
fit_step = 0.01;    % fitting step size (microns)
ps_frac = [0.1,0.2,0.3,0.5];      % Proportion of spectrum for fitting (multiple values allows for refinement)

% Diagnostic plots
diag_plot = true;

% Output name
output_name = 'tiltctf_lut_test.csv';

%% Initialize
opts = optimset('Display','off');

% Number of refinement factors
n_refine = numel(ps_frac);

% Center of image
cen = floor(img_size/2)+1;

% Fourier pixel limit
ps_limit = round((img_size/2)*ps_frac);

% Frequency array
freq = sg_frequencyarray(zeros(img_size,1),pixelsize);
freq = freq(cen:end);

% Calculate defocii
defocii = min_def:def_step:max_def;
n_def = numel(defocii);

% Calculate delta-defocii
d_def = -fit_range:fit_step:fit_range;
n_d_def = numel(d_def);

% Intialize lookup
lookup = zeros(n_def,4); % Columns: defocus, 2nd order, 1st order, mean ctf residual, scaling residual, fitting range, pixel size

%% Fit CTFs
tic
for i = 1:n_def
    disp(['Calculating defocus: ',num2str(defocii(i)),', ',num2str(i),' of ',num2str(n_def),'!!!']);
    
    % Calculate local defocus array
    temp_def = d_def + defocii(i);
    
    % Scaling array
    scaling_array = ones(n_d_def,1);
    res = zeros(n_d_def,1);
    rmsd = zeros(n_d_def,1);
    
    % Calculate unshifted CTF
    target_ctf = will_ctfamp(defocii(i),pshift,famp,cs,evk,freq);
    
    
    % Fit scaling factor
    for j = 1:n_refine
        
        if diag_plot
            figure; hold on;
            plot(target_ctf(1:ps_limit(j)));
        end
    
        for k = 1:n_d_def

            % Defocus shifted ctf
            shift_ctf = will_ctfamp(temp_def(k),pshift,famp,cs,evk,freq);

            % Fitting function
            fun = @(x,x_data)tomoman_scale_ctf(x_data,x,ps_limit(j));

            % Least-squares fitting
            [scaling_array(k),res(k)] = lsqcurvefit(fun,scaling_array(k),shift_ctf,target_ctf(1:ps_limit(j)),[],[],opts);            
            
            % Calculate RMSD
            fitted_ctf = tomoman_scale_ctf(shift_ctf,scaling_array(k),ps_limit(j));
            rmsd(k) = will_rmsd(target_ctf(1:ps_limit(j)),fitted_ctf);
            
            if diag_plot
                plot(tomoman_scale_ctf(shift_ctf,scaling_array(k),ps_limit(j)))
            end

        end
    end        
    
    disp('Defocus fitting complete!!! Fitting polynomial factors!!!');
    
    % Fit polynomial to scaling factors    
    poly = @(x,x_data)(x(1).*(x_data.^2)) + (x(2).*x_data) +1; % Intercept of scaling factor is 1    
    [p,p_res] = lsqcurvefit(poly,[0,1],d_def',1./scaling_array,[],[],opts);
    
    
    fitted_poly = poly(p,d_def');    
    p_rmsd = will_rmsd(1./scaling_array,fitted_poly);
    
    if diag_plot
        figure; hold on;
        scatter(d_def,1./scaling_array);
        plot(d_def,poly(p,d_def'));
    end
    
    % Store parameters
    lookup(i,1) = defocii(i);
    lookup(i,2) = p(1);
    lookup(i,3) = p(2);
    lookup(i,4) = mean(res);
    lookup(i,5) = p_res;
    lookup(i,6) = fit_range;
    lookup(i,7) = pixelsize;
    
    disp(['Fitting complete!!! CTF-RMSD: ',num2str(mean(rmsd)),' Polynomial RMSD: ',num2str(p_rmsd)]);  
    t = toc;
    if diag_plot
        input('Press the any key to continue...');
        close all
    end
    
    tpf = t/i;
    rt = tpf*(n_def-i);
    if rt > 60
        rt = rt/60;
        tu = 'minutes';
    else
        tu = 'seconds';
    end
    disp(['Remaining time: ',num2str(rt,'%.2f'),' ',tu,'...']);
    
end

if ~isempty(output_name)
    csvwrite(output_name,lookup);
end




