function frame_name = tomoman_lookup_tomo5_frame(mdoc_name, mdoc_param,i)


[~,name,~] = fileparts(mdoc_name);

ta = mdoc_param.TiltAngle;
if round(ta) == -0
    ta = 0;
end
sufix =  sprintf('_%03d[%2.2f]_EER.eer',i,round(ta));
prefix = 'D:\\data\';
frame_name = [prefix,name,sufix];
end
