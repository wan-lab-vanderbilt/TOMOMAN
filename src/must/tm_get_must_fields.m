function must_fields = tm_get_must_fields()
%% tm_get_membrain_fields
% Return parameter fields for a given tomoman_isonet task. 
%
% WW 06-2023

%% Get fields


must_fields = {'process_stack','str',[];...                 % Stack for processing. Either 'unfiltered' or 'dose-filtered' or 'odd' or 'even'
               'erase_radius','num',[];...                  % Set to 'none' to skip. Radius (in pixels) for gold fiducial erasing. Requires a *_erase.fid file from IMOD.
               'subset_list','str',[];...                   % Path to list of tomograms to be reconstructed; list is a plain-text file with a column of target tomo_num. Set to none to reconstruct all tomogmrams in
               'tomo_bin','num',[];...                      % Output binning parameters.
               'output_dir_prefix','str',[];...             % Prefix of output directory, relative to root_dir. For example, if prefix is "novactf_" and tomo_bin is "1,2", then output directories are novactf_bin1/ and novactf_bin2/.
               'n_cores','num',[];...                       % Number of cores for parallel processing. Parallel processing is only for building stacks; tomogram reconstruction and binning is not parallelized.
               'gpu_id','num',[];...                        % ID of GPU to use for processing
               'skip_ctfcorrection','num',[];...            % Skip CTF correction (0-Don't skip; 1-Skip)
               'ctf_deconvolve','num',[];...                % Correct CTF with deconvolution using a Wiener-like filter (0-Multiplication; 1-Deconvolution)
               'ctf_phaseflip','num',[];...                 % Correct CTF with phase flipping (0-Multiplication; 1-Phase flipping; Phase flippling is not available for 3D-CTF correction)
               'ctfcorrection_3d','num',[];...              % Apply 3D-CTF correction (0-Don't apply; 1-Apply) (If set to 1, the parameter "skip_ctfcorrection" will be ignored)
               'output_style','num',[];...                  % Output style (0 - Along the tilt axis in the 0-degree micrograph; 1 - Tilt axis = y-axis; 2 - Tilt axis = x-axis; 3 - Along the tilt axis of a specific micrograph; 4 - Along a specific tilt axis angle)
               'output_style_para','num',[];...             % The parameter for the output style 3 or 4 (For 3 - The number of the micrograph (started from 0); For 4 - The tilt axis angle)
               'it_sirt','num',[];...                       % Number of iterations for SIRT-like filter (Particularly, 0 stands for WBP (turn off SIRT-like filter), 1 stands for BP (no weighting))
               'padding','num',[];...                       % Padding factor of the micrographs before reconstruction (1 or 2 is recommended)
               'trimming','num',[];...                      % Trimming the micrograph to alleviate aliasing (0 - No trimming; 1 - Trimming)
               'bin','num',[];...                           % Binning factor
               'lp','num',[];...                            % Ratio of the cuf-off frequency with regard to the Nyquist frequency for lowpass filter (0~1, 1 means no filtering)
               'h_padding','num',[];...                     % Padding in height direction (in pixel) (1 or 2 times of the reconstructed height is recommended. Typically, the higher this value, the higher the contrast of the reconstructed tomogram)
               'N_block_fft','num',[];...                   % Number of blocks for dividing the tilt-series when doing FFT
               'N_block_rec','num',[];...                   % Number of blocks for dividing the reconstructed tomogram
               'N_block_linear_combination','num',[];...    % Number of blocks for dividing the micrographs in linear combination
               };





