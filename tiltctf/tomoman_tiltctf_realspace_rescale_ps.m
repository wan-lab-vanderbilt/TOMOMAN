function scale_ps = tomoman_tiltctf_realspace_rescale_ps(ps,scale_factor)
% Function to scale input power spectra in real space.
% substitutes sg_fourier rescale
% Sagar 01-2020


% Stretch the powerspectra with given scaling factor 
stretch_ps = imresize(ps,scale_factor,'lanczos3');


% Crop stretched ps to input size
ps_size = size(ps,1);
scale_ps = sg_crop_image(stretch_ps, ps_size);


end