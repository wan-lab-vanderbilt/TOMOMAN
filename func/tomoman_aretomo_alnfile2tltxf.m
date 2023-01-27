function [xf,tlt] = tomoman_aretomo_alnfile2tltxf(alignfile_name,binning)
% Convert AreTomo Alnfile to imod xf and tlt
%this is the right convention

% %% Debug
% clear all;
% 
% alignfile_name = '/fs/pool/pool-plitzko/Sagar/Projects/insitu_rubisco/chlamy_t4_1.2A/tomo/20200626_ChR_Rubisco_tomo__Position_16/AreTomo/20200626_ChR_Rubisco_tomo__Position_16-dose_filt.st.aln';
% binning = 4;

%% Function
fid = fileread(alignfile_name);

data = strsplit(fid,'\n');

numel(data);
n_tilts = numel(data)-3;

c = 1;
for i = 4:numel(data)-1 %aretomo version 1.0.0 onwards
    tlt_data = strsplit(data{i},' ');

    rotation(c) = str2double(tlt_data{3});
    tltangle(c) = str2double(tlt_data{end});
    xshift(c) = -str2double(tlt_data{5});
    yshift(c) = -str2double(tlt_data{6});
    a11(c) = cosd(-rotation(c));
    a12(c) = -sind(-rotation(c));
    a21(c) = sind(-rotation(c));
    a22(c) = cosd(-rotation(c));
    xshift_p(c) = (a11(c).*xshift(c) + a12(c).*yshift(c)).*binning;
    yshift_p(c) = (a21(c).*xshift(c) + a22(c).*yshift(c)).*binning;
    c = c+1;
    
end

xf = [a11',a12',a21',a22',xshift_p',yshift_p'];
tlt = tltangle';


% %% Debug
% 

end
