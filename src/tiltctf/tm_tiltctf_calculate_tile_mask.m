function [mask, m_idx, n_pix] = tm_tiltctf_calculate_tile_mask(tile_size,edge_smooth,smooth_type)
%% tm_tiltctf_calculate_tile_mask
% Calculate a mask for tiltctf tiles.
%
% SK, WW 06-2022

%% Calculate mask


switch smooth_type
    
    case 'circle'
        % Calculate smoothing circular mask
        radius = tile_size - (4*edge_smooth)+ 4;
        mask = sg_circle(tile_size,radius, edge_smooth);
        
    case 'square'
        
        % THIS NEEDS MORE WORK - SK
        % WW: BTW, there is an sg_cube_mask function.
        
        % Calculate smoothing square mask
        box_mask = zeros(tile_size,tile_size);
        b1 = (2*edge_smooth)+1;
        b2 = tile_size - (2*edge_smooth);
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


