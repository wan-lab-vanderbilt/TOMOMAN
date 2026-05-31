function output_stack = tm_function_dose_filter_stack(p,input_stack, pixelsize, dose_list, a, b, c)
%% tm_function_dose_filter_stack
% A function to exposure filter a tilt-stack using a modified version of 
% the Grant and Grigorieff approach implemented in Unblur. The modification
% is that applies the exposure filters as low-pass filters without
% frequency reweighting. Therefore, reweighting should be performed after
% subtomogram averaging.
%
% Required inputs are the input stack, name of the pixelsize in Angstroms,
% and a dose_list of e/A^2 that matches the input stack. 
%
% The resolution-dependent critical exposure constants can be provided as
% a,b,c; otherwise the defaults will be used.
%
% WW 04-2018

%% Check check

if nargin == 3
    % Hard-coded resolution-dependent critical exposures 
    a = 0.245;
    b = -1.665;
    c = 2.81;
elseif nargin ~= 7
    error('Achtung!!! Incorrect number of inputs!!!');
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

% Check stack size
if numel(dose_list) ~= z
    error('ACHTUNG!!! Stack size and dose-list do not match!!!');
end

% Initialize new stack
output_stack = zeros(x,y,z,'single');

% Intialize frequency array
freq_array = single(tm_frequencyarray(input_stack(:,:,1),pixelsize));


%% Filter stack
disp([p.name,'Begin dose filtering...']);
% Generate and apply filter for each tilt
for i = 1:z
    
    % Calculate FFT
%     fft_img = fft2(double(input_stack(:,:,i)));
    fft_img = fft2(single(input_stack(:,:,i)));

    
    % Calculate filter
    filter = ifftshift(exp((-dose_list(i))./(2.*((a.*(freq_array.^b))+c))));
    
    % Calculate new image
    output_stack(:,:,i) = real(ifft2(fft_img.*filter));
    
    disp([p.name,'Image ',num2str(i),' of ',num2str(z),' filtered...']);
end



