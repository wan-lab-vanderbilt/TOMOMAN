function s_ctf = tomoman_scale_ctf(ctf,scaling,ps_limit)

% Input X-array
x = 1:numel(ctf);
% Resampled X-array
xq = x.*scaling;
if xq(1)<1
    xq(1) = 1;
end

% Interpolate!
s_ctf = interp1(x,ctf,xq);
s_ctf = s_ctf(1:round(ps_limit))';

