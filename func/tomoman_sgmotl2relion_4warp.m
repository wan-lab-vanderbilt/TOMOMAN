function tomoman_sgmotl2relion_4warp(sg_motl, tomolist, star_file_out, apix)
    % Make CLEAN

    tomo_nums = unique([sg_motl.tomo_num])';

    %
    % write star file with angles from Align struct

    header_out = []; % let's have a clean start!

    % set up header 
    header_out.isLoop=1;
    header_out.title='data_';
    header_out.fieldNames={'_rlnMicrographName #1';
        '_rlnCoordinateX #2';'_rlnCoordinateY #3';'_rlnCoordinateZ #4';
        '_rlnImageName #5';'_rlnCtfImage #6'; '_rlnAngleRot #7 ';'_rlnAngleTilt #8';'_rlnAnglePsi #9';
        '_rlnOriginX #10';'_rlnOriginY #11';'_rlnOriginZ #12'; '_rlnMagnification #13'; '_rlnDetectorPixelSize #14'};
    header_out.fieldNamesNoCommet={'_rlnMicrographName';
        '_rlnCoordinateX';'_rlnCoordinateY';'_rlnCoordinateZ';
        '_rlnImageName';'_rlnCtfImage'; '_rlnAngleRot';'_rlnAngleTilt';'_rlnAnglePsi';
        '_rlnOriginX';'_rlnOriginY';'_rlnOriginZ'; '_rlnMagnification'; '_rlnDetectorPixelSize'};
    header_out.fieldNamesCommet={'#1'  '#2'  '#3'  '#4'  '#5'  '#6' '#7' '#8' '#9' '#10' '#11' '#12' '#12' '#13' '#14'};
    header_out.NumOfColumns=size(header_out.fieldNames,1);
    header_out.NumOfTotalLines=header_out.NumOfColumns+2;


    % the star data

    star_out = {};


    % indexes

    idx_mic_name = 1;

    idx_X = 2;
    idx_Y = 3;
    idx_Z = 4;

    idx_img_name = 5;

    idx_ctf_img = 6;

    idx_Rot = 7;
    idx_Tilt = 8;
    idx_Psi = 9;

    idx_ori_X = 10;
    idx_ori_Y = 11;
    idx_ori_Z = 12;

    idx_mag = 13;

    idx_apix = 14;


    % all fixed values go here

    rlnCtfImage = ['CTFmodel/CTFmodel.mrc']; % ctf image is fixed (fine at bin 4 ...)

    counter = 0;

    % process particles from same tomogram

    for i = 1:numel(tomo_nums)

        current_tomo_num = tomo_nums(i);

        [~, current_tomo, ~] = fileparts(tomolist(current_tomo_num).stack_name);

        subset_idx = [sg_motl.tomo_num] == current_tomo_num;

        subset = sg_motl(subset_idx);


        star_out_subset = {};


        for k = 1:numel(subset)

            % mic name

            rlnMicrographName = ['Tomograms/' current_tomo '/' current_tomo '.mrc'];

            % position

            rlnCoordinateX = subset(k).orig_x;
            rlnCoordinateY = subset(k).orig_y;
            rlnCoordinateZ = subset(k).orig_z;

            %  shifts

            rlnOriX = subset(k).x_shift;
            rlnOriY = subset(k).y_shift;
            rlnOriZ = subset(k).z_shift;


            % particle name

            rlnImageName = ['Particles/Tomograms/' current_tomo '/' current_tomo sprintf('%06d',k) '.mrc'];

            % convert angles ( ZXZ -> ZYZ )

            Phi = subset(k).phi;
            Psi = subset(k).psi;
            The = subset(k).the;

            [rot_m,euler_angles] = tom_eulerconvert_xmipp(Phi,Psi,The,'tom2xmipp');

            rlnAngleRot = euler_angles(1);
            rlnAngleTilt = euler_angles(2);
            rlnAnglePsi = euler_angles(3);


            star_out_subset{k, idx_mic_name} = rlnMicrographName;

            star_out_subset{k, idx_img_name} = rlnImageName;

            star_out_subset{k, idx_ctf_img} = rlnCtfImage;

            star_out_subset{k, idx_X} = rlnCoordinateX;
            star_out_subset{k, idx_Y} = rlnCoordinateY;
            star_out_subset{k, idx_Z} = rlnCoordinateZ;

            star_out_subset{k, idx_Rot} = rlnAngleRot;
            star_out_subset{k, idx_Tilt} = rlnAngleTilt;
            star_out_subset{k, idx_Psi} = rlnAnglePsi;

            star_out_subset{k, idx_ori_X} = rlnOriX;
            star_out_subset{k, idx_ori_Y} = rlnOriY;
            star_out_subset{k, idx_ori_Z} = rlnOriZ;

            star_out_subset{k, idx_mag} = 10000;

            star_out_subset{k, idx_apix} = apix;


        end

        star_out = [star_out; star_out_subset];


    end

    %%

    if ~isempty(star_file_out)

        tom_starwrite(star_file_out, star_out, header_out);

    end


end