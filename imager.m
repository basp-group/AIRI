function imager(pathData, imPixelSize, imDimx, imDimy, param_general, runID)
    
    fprintf('\nINFO: measurement file %s', pathData);
    fprintf('\nINFO: Image size %d x %d', imDimx, imDimy)

    %% setting paths
    dirProject = param_general.dirProject;
    fprintf('\nINFO: Main project dir. is %s', dirProject);
    
    % src & lib codes
    addpath([dirProject, filesep, 'lib', filesep, 'lib_imaging', filesep]);
    addpath([dirProject, filesep, 'lib', filesep, 'lib_utils', filesep]);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'nufft']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'irt', filesep, 'utilities']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'lib', filesep, 'utils']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'lib', filesep, 'operators']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'lib', filesep, 'ddes_utils']);
    
    %% Measurements & operators
    % Measurements
    [DATA, param_general.flag_data_weighting] = util_read_data_file(pathData, param_general.flag_data_weighting);

    % Set pixel size
    if isempty(imPixelSize)
        maxProjBaseline = double( load(pathData, 'maxProjBaseline').maxProjBaseline );
        spatialBandwidth = 2 * maxProjBaseline;
        imPixelSize = (180 / pi) * 3600 / (param_general.superresolution * spatialBandwidth);
        fprintf('\nINFO: default pixelsize: %g arcsec, that is %f x nominal resolution at the highest freq.',...
            imPixelSize, param_general.superresolution);
    else
        fprintf('\nINFO: user specified pixelsize: %g arcsec,', imPixelSize)
    end
    
    % Set parameters releated to operators
    [param_nufft, param_precond, param_wproj] = util_set_param_operator(param_general, imDimx, imDimy, imPixelSize);

    % Generate operators
    [A, At, G, W, ~, nWimag] = util_gen_meas_op_comp_single(pathData, imDimx, imDimy, ...
        param_general.flag_data_weighting, param_nufft, param_wproj, param_precond);
    [FWOp, BWOp] = util_syn_meas_op_single(A, At, G, W, []);

    % compute operator norm
    fprintf('\nComputing spectral norm of the measurement operator..')
    param_general.measOpNorm = op_norm(FWOp, BWOp, [imDimy,imDimx], 1e-6, 500, 0);
    fprintf('\nINFO: measurement op norm %f', param_general.measOpNorm);
    % if use primal-dual
    if ismember(param_general.algorithm, {'cairi', 'cpnp-bm3d'})
        [~, BWOpCmp] = util_syn_meas_op_single(A, At, G, W, [], true);
        param_general.measOpNormCmp = op_norm(FWOp, BWOpCmp, [imDimy,imDimx], 1e-6, 500, 0);
        fprintf('\nINFO: measurement op norm with complex BWOp %f', param_general.measOpNormCmp);
        clear BWOpCmp
    end
    
    % Compute PSF & dirty image
    dirac = zeros(imDimy, imDimx);
    dirac(floor(imDimy./2) + 1, floor(imDimx./2) + 1) = 1;
    PSF = BWOp(FWOp(dirac));
    PSFPeak = max(PSF,[],'all');
    fprintf('\nINFO: PSF peak value: %g',PSFPeak);

    dirty = BWOp(DATA)./PSFPeak;
    peak_est = max(dirty,[],'all');
    fprintf('\nINFO: dirty image peak value: %g', peak_est);
    clear dirac;
    
    %% Heuristic noise level
    heuristic = 1 / sqrt(2 * param_general.measOpNorm);
    fprintf('\nINFO: heuristic noise level: %g', heuristic);

    if param_general.flag_data_weighting
        % Calculate the correction factor of the heuristic noise level when
        % data weighting vector is used
        [FWOp_prime, BWOp_prime] = util_syn_meas_op_single(A, At, G, W, nWimag.^2);
        measOpNorm_prime = op_norm(FWOp_prime,BWOp_prime,[imDimy,imDimx],1e-6,500,0);
        heuristic_correction = sqrt(measOpNorm_prime/param_general.measOpNorm);
        clear FWOp_prime BWOp_prime;
        heuristic = heuristic .* heuristic_correction;
        fprintf('\nINFO: heuristic noise level after correction: %g, corection factor %.16g', heuristic, heuristic_correction);
    end

    %% Set parameters for imaging and algorithms
    param_algo = util_set_param_algo(param_general, heuristic, peak_est, numel(DATA));
    param_imaging = util_set_param_imaging(param_general, param_algo, [imDimy,imDimx], pathData, runID);
    
    % save dirty image and PSF
    fitswrite(single(PSF), fullfile(param_imaging.resultPath, 'PSF.fits'));
    fitswrite(single(dirty), fullfile(param_imaging.resultPath, 'dirty.fits'));
    
    % clear unnecessary vars
    clear param_nufft param_precond param_wproj
    clear dirProject maxProjBaseline
    clear measOpNorm_prime nWimag
    clear peak_est spatialBandwidth PSF dirty heuristic
    
    %% INFO
    fprintf("\n________________________________________________________________\n")
    disp('param_algo')
    disp(param_algo)
    disp('param_imaging')
    disp(param_imaging)
    fprintf("________________________________________________________________\n")
    
    %% Imaging
    switch param_algo.algorithm
        case {'airi', 'upnp-bm3d'}
            RESULTS = solver_imaging_forward_backward(DATA, FWOp, BWOp, param_imaging, param_algo);
        case {'cairi', 'cpnp-bm3d'}
            RESULTS = solver_imaging_primal_dual(DATA, FWOp, BWOp, param_imaging, param_algo);
    end

    %% Save final results
    fitswrite(RESULTS.MODEL, fullfile(param_imaging.resultPath, [param_algo.algorithm, '_model_image.fits']))
    fitswrite(RESULTS.RESIDUAL, fullfile(param_imaging.resultPath, [param_algo.algorithm, '_residual_dirty_image.fits']))
    fitswrite(RESULTS.RESIDUAL ./ PSFPeak, fullfile(param_imaging.resultPath, [param_algo.algorithm, '_residual_dirty_image_normalised.fits']))

    %% Final metrics
    fprintf('\nINFO: The std of the residual dirty image %g', std(RESULTS.RESIDUAL, 0, 'all'))
    try
        gdth_img = fitsread(param_imaging.groundtruth);
        rsnr = 20*log10( norm(gdth_img(:)) / norm(RESULTS.MODEL(:) - gdth_img(:)) );
        fprintf('\nINFO: The signal-to-noise ratio of the reconstructed image %f dB', rsnr)
    end
    
    fprintf('\nTHE END\n')
    end
