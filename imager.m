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
        fprintf('\nINFO: default pixelsize: %g arcsec, that is %d x nominal resolution at the highest freq.',...
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
    if isfield(param_general, 'measOpNorm') && ~isempty(param_general.measOpNorm)
        fprintf('\nINFO: user provides measurement op norm %f', param_general.measOpNorm);
    else
        fprintf('\nComputing spectral norm of the measurement operator..')
        rng(1,'Threefry');
        [param_general.measOpNorm,~,iter] = op_norm(FWOp, BWOp, [imDimy,imDimx], 1e-8, 1000, 0);
        fprintf('\nINFO: measurement op norm %f, computed in %d iter', param_general.measOpNorm, iter);
    end
    % if use primal-dual
    if ismember(param_general.algorithm, {'cairi', 'cpnp-bm3d'})
        if isfield(param_general, 'measOpNormCmp') && ~isempty(param_general.measOpNormCmp)
            fprintf('\nINFO: user provides measurement op norm with complex BWOp %f', param_general.measOpNormCmp);
        else
            [~, BWOpCmp] = util_syn_meas_op_single(A, At, G, W, [], true);
            param_general.measOpNormCmp = op_norm(FWOp, BWOpCmp, [imDimy,imDimx], 1e-8, 1000, 0);
            fprintf('\nINFO: measurement op norm with complex BWOp %f', param_general.measOpNormCmp);
            clear BWOpCmp
        end
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
        if isfield(param_general, 'heuCorrFactor') && ~isempty(param_general.heuCorrFactor)
            fprintf('\nINFO: user provides heuristic correction factor: %f', param_general.heuCorrFactor);
            heuristic_correction = param_general.heuCorrFactor;
        else
            [FWOp_prime, BWOp_prime] = util_syn_meas_op_single(A, At, G, W, nWimag.^2);
            rng(1,'Threefry');
            measOpNorm_prime = op_norm(FWOp_prime,BWOp_prime,[imDimy,imDimx],1e-8,1000,0);
            heuristic_correction = sqrt(measOpNorm_prime/param_general.measOpNorm);
            clear FWOp_prime BWOp_prime;
        end
        heuristic = heuristic .* heuristic_correction;
        fprintf('\nINFO: heuristic noise level after correction: %g', heuristic);
    end

    %% Set parameters for imaging and algorithms
    param_algo = util_set_param_algo(param_general, heuristic, peak_est, numel(DATA));
    param_imaging = util_set_param_imaging(param_general, param_algo, [imDimy,imDimx], pathData, runID);
    
    % save dirty image and PSF
    fitswrite(single(PSF), fullfile(param_imaging.resultPath, 'PSF.fits'));
    fitswrite(single(dirty), fullfile(param_imaging.resultPath, 'dirty.fits'));
    
    % clear unnecessary vars
    clear param_nufft param_precond param_wproj param_general 
    clear dirProject imDimx imDimy imPixelSize maxProjBaseline 
    clear measOpNorm_prime nWimag pathData runID
    clear peak_est spatialBandwidth PSF dirty heuristic
    % clear A At G W
    
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
    fitswrite(single(RESULTS.MODEL), fullfile(param_imaging.resultPath, [param_algo.algorithm, '_model_image.fits']))
    fitswrite(single(RESULTS.RESIDUAL), fullfile(param_imaging.resultPath, [param_algo.algorithm, '_residual_dirty_image.fits']))
    fitswrite(single(RESULTS.RESIDUAL ./ PSFPeak), fullfile(param_imaging.resultPath, [param_algo.algorithm, '_residual_dirty_image.fits']))
    
    fprintf('\nTHE END\n')
    end
