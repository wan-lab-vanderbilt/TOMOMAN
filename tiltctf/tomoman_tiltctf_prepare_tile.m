function normtile = tomoman_tiltctf_prepare_tile(tile,edge_smooth,smooth_type)
% Function to smooth the  tile as edges and normalize to mean0+1sigma
% Sagar 01-2020

switch smooth_type
    case 'circle'
        % Calculate smoothing circular mask
        boxsize = size(tile,1);
        radius = boxsize - (4*edge_smooth)+ 4;
        mask = sg_circle(boxsize,radius, edge_smooth);
        
    case 'square'
        
        % THIS NEEDS MORE WORK
        
        % Calculate smoothing square mask
        boxsize = size(tile,1);
        box_mask = zeros(boxsize,boxsize);
        b1 = (2*edge_smooth)+1;
        b2 = boxsize - (2*edge_smooth);
        box_mask(b1:b2,b1:b2) = 1;
        % smooth_mask = single(box_mask > 0);
        % mask(idx) = 1;

        dims = size(box_mask);
        kernel = sg_circle(dims(1,2),edge_smooth,edge_smooth);
        ft_kernel = fft2(kernel);
        n_pix = sum(kernel(:));
        mask = fftshift(real(ifft2(fft2(box_mask).*ft_kernel)./n_pix));
        mask = mask.*single(mask>0);
end

% Calculate mask parameteres
m_idx = mask > 0;
n_pix = sum(mask(:));   % Pixels under mask

% Mask and set mean to zero
mref = tile.*mask;
mref(m_idx) = mref(m_idx)-(sum(mref(m_idx))./n_pix);

% Normalization factor of references
sigmaRef = sqrt(sum(mref(m_idx).^2)./n_pix); % StDev of area under mask
normtile = mref./sigmaRef;


end