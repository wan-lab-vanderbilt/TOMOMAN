function n_img = tomoman_mrc_split(mrc_name, varargin)
%% tomoman_mrc_split
% A function to take in an mrc stack and write out the individual images. 
% Optional inputs can be given as name argument pairs. Arguments are
% 'outname' for the root name of the output stack and 'suffix' for adding
% an additional suffix to the root name. An optional 'digits' input is also
% available to set leading zeros. By default, the 'outname' is the same as 
% the 'mrc_name', the 'suffix' is empty, and 'digits' is -1, which sets the
% leading zeros based on the number of tilts in the stack. 
%
% WW 10-2017

%% Check check
if (round((nargin-1)/2) ~= ((nargin-1)/2))
    error('Achtung!!! Incorrect number of inputs!!!');
end

% Parse filename
[path,name,ext] = fileparts(mrc_name);
if isempty(path)
    path = '.';
end

% Initialize options
options = struct('outname',[path,'/',name],'suffix',[],'digits',-1);
option_names = fieldnames(options);

% Check input
if nargin ~= 0    
    % Parse argument pairs
    for pair = reshape(varargin,2,[])    
        input_name = lower(pair{1});
        if any(strcmp(input_name,option_names))
            options.(input_name) = pair{2};
        else
            error('Achtung!!! Invalid parameter!!!');
        end        
    end
    
    % Check digits input
    if (ischar(options.digits)); options.digits=eval(options.digits); end
    if floor(options.digits) ~= options.digits
        error('Achtung!!! Digits argument must be an integer!!!')
    elseif options.digits < -1
        error('Achtung!!! Invalid digits argument. Number must be greater that -1!!!')
    end

end

%% Banana split!

% Read stack
[stack,header] = sg_mrcread(mrc_name);
n_img = size(stack,3);
% Autoset digits
if options.digits == -1
    options.digits = ceil(log10(n_img+1));  % Should always work for integer counts...
end


% Split
for i  = 1:n_img
    
    % String of image number
    num_str = sprintf(['%0',num2str(options.digits),'d'],i);
    % New filename
    new_name = [options.outname,options.suffix,'_',num_str,ext];
    
    % Write output
    sg_mrcwrite(new_name,stack(:,:,i),header);
end
disp([mrc_name,' split!']);




