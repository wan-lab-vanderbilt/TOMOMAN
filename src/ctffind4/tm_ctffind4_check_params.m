function ctffind4 = tm_ctffind4_check_params(ctffind4,t)
%% tm_ctffind4_check_params
% A function to check the ctffind4 parameter struct and modify as
% necessary.
%
% 'ctffind4' is the parameter struct while 't' is the input tomolist line.
%
% WW 06-2022

%% Check defaults

% Get fields
ctffind4_fields = tm_get_ctffind4_fields();
n_fields = size(ctffind4_fields,1);

% Check default arguments
for i = 1:n_fields
    
    
    if ~isfield(ctffind4,ctffind4_fields{i,1})
        % Fill field if missing
        ctffind4.(ctffind4_fields{i,1}) = ctffind4_fields{i,3};
        
    elseif isempty(ctffind4.(ctffind4_fields{i,1}))
        
        % Fill field if empty
        ctffind4.(ctffind4_fields{i,1}) = ctffind4_fields{i,3};
        
    end
end


% Reorder fields
ctffind4 = orderfields(ctffind4,ctffind4_fields(:,1));

% Check for known astigmatism
if ctffind4.known_astig
     ctffind4 = rmfield(ctffind4,{'rest_astig','exp_astig'});
else
    ctffind4 = rmfield(ctffind4,{'astig','astig_angle'});
end

% Check for restraint on astigmatism
if ~ctffind4.rest_astig
    ctffind4 = rmfield(ctffind4,'exp_astig');
end
    
% Check for phase shift
if ~ctffind4.det_pshift
    ctffind4 = rmfield(ctffind4,{'pshift_min','pshift_max','pshift_step'});
end

% Check resample
if ~ctffind4.expert
    ctffind4 = rmfield(ctffind4,{'resample','known_defocus','known_defocus_1','known_defocus_2','known_defocus_astig','known_defocus_pshift','nthreads'});
end

if ctffind4.expert && ~ctffind4.known_defocus
    ctffind4 = rmfield(ctffind4,{'known_defocus_1','known_defocus_2','known_defocus_astig','known_defocus_pshift'});
    
end

% Convert logicals
fields = fieldnames(ctffind4);
for i = 1:numel(fields)
    if islogical(ctffind4.(fields{i}))
        if ctffind4.(fields{i})
            ctffind4.(fields{i}) = 'yes';
        else
            ctffind4.(fields{i}) = 'no';
        end
    end
end

% Update pixelsize
ctffind4.pixelsize = t.pixelsize;

% Update voltage
ctffind4.voltage = t.voltage;

% Check defocus step (changed to 10 from 1.. you would be kidding if you wanted to use 10A step size!!)
if ctffind4.def_step < 10
    ctffind4.def_step = ctffind4.def_step * 10000;
end

% Prase defocus range from tomolist
ctffind4.min_def = (abs(t.target_defocus)-ctffind4.def_range)*10000;
ctffind4.max_def = (abs(t.target_defocus)+ctffind4.def_range)*10000;


    





