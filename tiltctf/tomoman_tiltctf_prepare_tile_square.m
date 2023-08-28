function normtile = tomoman_tiltctf_prepare_tile(tile,edge_smooth)
% Function to smooth the  tile as edges and normalize to mean0+1sigma
% Sagar 01-2020


% Calculate smoothing mask
boxsize = size(tile,1);
box_mask = zeros(boxsize,boxsize);
b1 = (2*edge_smooth)+1;
b2 = boxsize - (2*edge_smooth);
box_mask(b1:b2,b1:b2) = 1;
mask = sg_smooth_mask(box_mask,edge_smooth, edge_smooth);

% Calculate mask parameteres
m_idx = mask > 0;
n_pix = sum(mask(:));   % Pixels under mask

% Mask and set mea to zero
mref = tile.*mask;
mref(m_idx) = mref(m_idx)-(sum(mref(m_idx))./n_pix);

% Normalization factor of references
sigmaRef = sqrt(sum(mref(m_idx).^2)./n_pix); % StDev of area under mask
normtile = mref./sigmaRef;



end

function smooth_mask = sg_smooth_mask(mask, radius,sigma)
% Function to smooth a 2D mask 
% Calculates a kernel and Smooths input mask by fourier multiplication (conv). 

% Calculate smoothing kernel
dims = size(mask);
kernel = sg_circle(dims(1,2),radius,sigma);
ft_kernel = fft2(kernel);
n_pix = sum(kernel(:));

% conv 
smooth_mask = fftshift(real(ifft2(fft2(mask).*ft_kernel)./n_pix));


end