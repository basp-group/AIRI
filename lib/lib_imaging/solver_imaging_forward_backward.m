function [FINAL_MODEL, FINAL_RESIDUAL] = solver_imaging_forward_backward(measop, adjoint_measop, dirtyIm, param_imaging, param_algo)
%% ************************************************************************
% *************************************************************************
% Imaging: forward-backward algorithm
% *************************************************************************
%% Initialization
% AIRI specific
flag_airi = strcmp(param_algo.algorithm, 'airi');
if flag_airi
    % load denoiser
    [netPath, scalingFactor, peakMin, peakMax] = ...
        get_net_detail(param_algo.dnnShelfPath, param_algo.heuristic, param_algo.imPeakEst);
    denoiser = get_resized_dnn(netPath, param_imaging.imDims);

    % adaptive network selection
    if param_algo.dnnAdaptivePeak
        dnnAdaptivePeakTol = param_algo.dnnAdaptivePeakTolMax;
        peak_curr = param_algo.imPeakEst;
    end

    algo_print_name = '   AIRI  ';
else
    algo_print_name = 'uPNP-BM3D';
end

%% ALGORITHM
fprintf('\n*************************************************\n')
fprintf('********* STARTING ALGORITHM: %s *********', algo_print_name)
fprintf('\n*************************************************\n')
% init
MODEL = zeros(param_imaging.imDims);
t_total = tic;

for itr = 1 : param_algo.imMaxItr
    t_itr =tic;
    MODEL_prev = MODEL;

    % (forward) gradient step
    t_grad =tic;
    Xhat = MODEL - param_algo.gamma * (adjoint_measop(measop(MODEL)) - dirtyIm);
    t_grad = toc(t_grad);

    % (backward) denoising step
    t_den =tic;
    if flag_airi
        % apply AIRI denoiser
        if param_algo.dnnApplyTransform
            rot_id  = randi([0 3]); % times of 90-degree rotation
            do_fliplr = randi([0 1]); % left-right flip
            do_flipud = randi([0 1]); % up-down flip

            if rot_id > 0, Xhat = rot90(Xhat,rot_id);
            end
            if do_fliplr,  Xhat = fliplr(Xhat);
            end
            if do_flipud , Xhat = flipud(Xhat);
            end
        end
        
        % apply denoiser
        MODEL = double(predict(denoiser, Xhat./scalingFactor)).*scalingFactor;

        if param_algo.dnnApplyTransform
            % undo transform
            if do_flipud, MODEL = flipud(MODEL);
            end
            if do_fliplr, MODEL = fliplr(MODEL);
            end
            if rot_id > 0, MODEL = rot90(MODEL,-rot_id);
            end
        end

    else
        % BM3D
        Xhat(Xhat<0) = 0;
        currPeak = max(Xhat, [], 'all');
        if currPeak < 1.0
            currPeak = 1.0;
        end
        MODEL = BM3D(Xhat/currPeak, param_algo.heuristic) * currPeak;
    end
    t_den = toc(t_den);
    t_itr = toc(t_itr);

    % print info
    im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
    % print info
    fprintf("\n\nIter %d: relative variation %g\ntimings: gradient step %f sec, denoising step %f sec, iteration %f sec.", ...
        itr, im_relval, t_grad, t_den, t_itr);

    % stopping creteria
    if im_relval < param_algo.imVarTol && itr >= param_algo.imMinItr
        break;
    end

    % save intermediate results
    if mod(itr, param_imaging.itrSave) == 0
        fitswrite(MODEL, fullfile(param_imaging.resultPath, ...
            ['tmpModel_itr_', num2str(itr), '.fits']))
        RESIDUAL = dirtyIm - adjoint_measop(measop(MODEL));
        fitswrite(RESIDUAL, fullfile(param_imaging.resultPath, ...
            ['tmpResidual_itr_', num2str(itr), '.fits']))
    end

    % AIRI specific: adaptive network selection
    if flag_airi && param_algo.dnnAdaptivePeak
        peak_prev = peak_curr;
        peak_curr = max(MODEL, [], 'all');
        peak_var = abs(peak_curr - peak_prev) / abs(peak_prev);
        fprintf('\nModel image peak value %g, relative variation = %g', peak_curr, peak_var);
        % peak value is stable and out of desired range
        if peak_var < dnnAdaptivePeakTol && (peak_curr > peakMax || peak_curr < peakMin)
            [netPath, scalingFactor_new, peakMin, peakMax] = ...
                get_net_detail(param_algo.dnnShelfPath, param_algo.heuristic, peak_curr);
            if scalingFactor_new ~= scalingFactor
                denoiser = get_resized_dnn(netPath, param_imaging.imDims);
                scalingFactor = scalingFactor_new;
                dnnAdaptivePeakTol = max(dnnAdaptivePeakTol/param_algo.dnnAdaptivePeakTolStep, ...
                    param_algo.dnnAdaptivePeakTolMin);
            end
        end
    end
    
end
t_total = toc(t_total);

fprintf("\n\nImaging finished in %f sec, total number of iterations %d\n\n", t_total, itr);
fprintf('\n**************************************\n')
fprintf('********** END OF ALGORITHM **********')
fprintf('\n**************************************\n')

%% Final variables
FINAL_MODEL = MODEL;
FINAL_RESIDUAL = dirtyIm - adjoint_measop(measop(MODEL));

end
