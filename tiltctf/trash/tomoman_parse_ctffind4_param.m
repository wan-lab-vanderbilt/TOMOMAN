function ctffind = tomoman_parse_ctffind4_param(ctffind)
%% tomoman_parse_ctffind4_param
% Parse and check the input parameters for CTFFIND4.
%
% Last updated for: CTFFIND 4.1.5
%
% WW 07-2018

%% Parse!!!1!

% Parameter array
param = {'def_range', 'num', 0.6;...
         'pixelsize','num',1;...
         'evk', 'num', 300;...
         'cs', 'num', 2.7;...
         'famp', 'num', 0.07;...
         'ps_size', 'num', 512;...
         'min_res', 'num', 30;...
         'max_res', 'num', 5;...
         'min_def', 'num', 5000;...
         'max_def', 'num', 50000;...
         'def_step', 'num', 500;...
         'known_astig', 'boo', false;...
         'astig', 'num', 0;...
         'astig_angle', 'num', 0;...
         'slower', 'boo', false;...
         'rest_astig', 'boo', true;...
         'exp_astig', 'num', 200;...
         'det_pshift', 'boo', false;...
         'pshift_min', 'num', 0;...
         'pshift_max', 'num', 3.15;...
         'pshift_step', 'num', 0.1;...
         'expert', 'boo', false;...
         'resample', 'boo', false;...
         };
n_param = size(param,1);


% Check types default arguments
for i = 1:n_param
    
    if ~isfield(ctffind,param{i,1})
        ctffind.(param{i,1}) = param{i,3};
    elseif isempty(ctffind.(param{i,1}))
        ctffind.(param{i,1}) = param{i,3};
    else
        ctffind.(param{i,1}) = tomoman_check_param_type(ctffind.(param{i,1}),param{i,1},param{i,2});
    end
end
   
% Reorder fields
ctffind = orderfields(ctffind,param(:,1));

% Check for known astigmatism
if ctffind.known_astig
    ctffind = rmfield(ctffind,{'slower','rest_astig','exp_astig'});
else
    ctffind = rmfield(ctffind,{'astig','astig_angle'});
end

% Check for restrait on astigmatism
if ~ctffind.rest_astig
    ctffind = rmfield(ctffind,'exp_astig');
end
    

% Check for phase shift
if ~ctffind.det_pshift
    ctffind = rmfield(ctffind,{'pshift_min','pshift_max','pshift_step'});
end

% Check resample
if ctffind.resample
    ctffind.expert = true;
else
    ctffind.expert = false;
    ctffind = rmfield(ctffind,'resample');
end


% Convert logicals
fields = fieldnames(ctffind);
for i = 1:numel(fields)
    if islogical(ctffind.(fields{i}))
        if ctffind.(fields{i})
            ctffind.(fields{i}) = 'yes';
        else
            ctffind.(fields{i}) = 'no';
        end
    end
end


% Check defocus step
if ctffind.def_step < 1
    ctffind.def_step = ctffind.def_step * 10000;
end



    