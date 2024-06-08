function compile_tomoman(target_dir)
%% compile_tomoman
% Default parameters for compiling TOMOMAN_parallel. TOMOMAN is compiled
% into the target_dir.
% 
% WW 07-2022

% % % % DEBUG
% target_dir = '/dors/wan_lab/home/wanw/research/software/tomoman/TOMOMAN-vandy/exec/lib/';


%% Compile

% % Clear workspace
% clear all
% close all

% Compile with tiltctf lookup table
[self_path,~,~] = fileparts(which('tm_get_dependencies'));
dep_param = [self_path,'/tm_dependencies.param'];
% dep_param = [self_path,'/tm_dependencies_umich2024.param'];

% Compile with backup dependencies
[self_path,~,~] = fileparts(which('tm_tiltctf_ctffind4'));
lut_name = [self_path,'/tiltctf_lut.csv'];

% Compile
% mcc -mv -R nojvm -R -nodisplay -R -nosplash tomoman_parallel.m -d /dors/wan_lab/home/wanw/research/software/tomoman/TOMOMAN-vandy/exec/lib/ -a lut_name
mcc('-R', 'nojvm', '-R', 'nodisplay', '-R', 'nosplash', '-m', 'tomoman_parallel.m', '-d', target_dir, '-a', lut_name, '-a', dep_param)
system(['chmod +x ',target_dir,'tomoman_parallel']);

% Compile standalone
sg_toolbox_dir = '/dors/wan_lab/home/wanw/research/software/stopgap/0.7.4/sg_toolbox/';
tomoman_dir = '/home/wanw/research/software/tomoman/TOMOMAN_v0.9rel_20240516/';
mcc('-R', 'nosplash', '-m', 'tomoman_standalone.m', '-d', target_dir, '-a', lut_name, '-a', dep_param, '-a', sg_toolbox_dir, '-a', tomoman_dir)
system(['chmod +x ',target_dir,'tomoman_standalone']);


