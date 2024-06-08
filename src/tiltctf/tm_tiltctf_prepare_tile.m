function normtile = tm_tiltctf_prepare_tile(tile, mask, m_idx, n_pix)
%% tm_tiltctf_prepare_tile
% Function to apply a mask to the tile and normalize unmasked areas to
% mean=0 and stdev = 1.
%
% SK, WW 06-2022

%% Prepare tile


% Mask and set mean to zero
mref = tile.*mask;
mref(m_idx) = mref(m_idx)-(sum(mref(m_idx))./n_pix);

% Normalization factor of references
sigmaRef = sqrt(sum(mref(m_idx).^2)./n_pix); % StDev of area under mask
normtile = mref./sigmaRef;


end