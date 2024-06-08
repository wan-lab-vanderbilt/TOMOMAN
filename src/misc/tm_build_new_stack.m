function new_stack = tm_build_new_stack(p,tomolist,stack_name,n_tilts,suffix,image_size)
%% tm_build_new_stack
% Function to build a new stack after frame alignment.
%
% WW 06-2022

% Debug
% stack_name = [relionmc_dir,tomo_str];

%% Build stack

% Build stack
for i = 1:n_tilts

    % Read image
    img = sg_mrcread([stack_name,'_',num2str(i),suffix,'.mrc']);

    % Initialize stacks
    if i == 1

        % Check image size
        if isempty(image_size)
            img_size = size(img);
        else
            img_size = image_size;
        end
        new_stack = zeros(img_size(1),img_size(2),n_tilts,'like',img); % In the loop so that it picks up the datatype
    end
    
    

    % Resize and mirror image
    img = tm_resize_stack(img,img_size(1),img_size(2),true);
    if sg_check_param(tomolist,'mirror_stack')
        img = tom_mirror(img,tomolist.mirror_stack);
    end

    % Store image
    new_stack(:,:,i) = img;

    disp([p.name,'image ',num2str(i),' of ',num2str(n_tilts),' added...']);
end
    
    