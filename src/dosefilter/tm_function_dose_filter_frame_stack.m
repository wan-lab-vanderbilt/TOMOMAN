function filt_img = tm_function_dose_filter_frame_stack(p,input_stack, pixelsize, initial_dose, dose_per_frame, a, b, c)
%% tm_function_dose_filter_frame_stack
% A function to exposure filter a tilt-stack using a modified version of 
% the Grant and Grigorieff approach implemented in Unblur. The modification
% is that applies the exposure filters are reweighted by the inverse of the
% sum of the squares, multiplied by the first filter. This is because the
% high-resolution information content of the summed image should not be
% higher than the exposure filter, otherwise noise is amplified. 
%
% Required inputs are the input stack, name of the pixelsize in Angstroms,
% the initial dose prior to imaging, and the dose per frame in e/A^2. 
%
% The resolution-dependent critical exposure constants can be provided as
% a,b,c; otherwise the defaults will be used.
%
% WW 04-2018

%% Check check

if nargin == 5
    % Hard-coded resolution-dependent critical exposures 
    a = 0.245;
    b = -1.665;
    c = 2.81;
elseif nargin ~= 8
    error([p.name,'Achtung!!! Incorrect number of inputs!!!']);
end

if isempty(a) || isempty(b) || isempty(c)
    % Hard-coded resolution-dependent critical exposures 
    a = 0.245;
    b = -1.665;
    c = 2.81;
end


%% Initialize

% Get stack dimensions
[x,y,z] = size(input_stack);

% Initialize filter stack
filter_stack = zeros(x,y,z);

% Filtered image
fft_sum = zeros(x,y,1);

% Intialize frequency array
freq_array = tm_frequencyarray(input_stack(:,:,1),pixelsize);


%% Filter stack

% Generate and apply filter for each tilt
for i = 1:z
    
    % Calculate FFT
    fft_img = fft2(double(input_stack(:,:,i)));
    
    % Calculate dose
    dose = initial_dose + (dose_per_frame*i);
    
    % Calculate filter
    filter_stack(:,:,i) = ifftshift(exp(-dose./(2.*((a.*(freq_array.^b))+c))));
    
    % Calculate new image
    fft_sum = fft_sum + (fft_img.*filter_stack(:,:,i));
    
    disp([p.name,'Frame ',num2str(i),' of ',num2str(z),' filtered...']);
end


%% Reweight image

% Reweighting filter
reweight_filter = filter_stack(:,:,1)./sqrt(sum(filter_stack.^2,3)./z);

% Filtered image
filt_img = real(ifft2(fft_sum.*reweight_filter));



