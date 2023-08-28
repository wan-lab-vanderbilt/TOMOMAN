function res = find_first_ctf_node(image_size,pixelsize,defocus,pshift,evk,famp,cs)
%% find_first_ctf_node
% Calculate a CTF curve using given inputs and return the resolution before
% the first node.
%
% WW 07-2018

%% FIND THE NODE

% Calculate frequency array
f = sg_frequencyarray(zeros(image_size,1),pixelsize);
f = f(floor(image_size/2)+1:end);   % Take half of spectrum

% Calculate CTF
ctf = sg_ctf(defocus,pshift,famp,cs,evk,f);


% First pixel after phase inversion
inv_idx = find(ctf<0,1);

% Pixel before phase inversion
idx = inv_idx - 1;

% Return resolution
res = (image_size*pixelsize)/idx;
