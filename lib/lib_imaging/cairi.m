function [FINAL_MODEL, FINAL_RESIDUAL] = cairi(DATA, measop, adjoint_measop, aW, param_imaging, param_algo)

%% ************************************************************************
% *************************************************************************
% Imaging: cAIRI algorithm based on primal-dual
% *************************************************************************

%% Initialization
% Ellipsoid projection parameters
param_proj.min_itr = 1;
param_proj.max_itr = 10;
param_proj.eps = 1e-6;
% load denoiser
[netPath, scalingFactor, peakMin, peakMax] = ...
    get_net_detail(param_algo.dnnShelfPath, param_algo.heuristic, param_algo.imPeakEst);
if param_algo.dnnApplyTransform && param_imaging.imDims(1) ~= param_imaging.imDims(2)
    paddingFlag = true;
    netInSize = max(param_imaging.imDims);
    netInSize = [netInSize, netInSize];
    imgPadX = floor((netInSize(2) - param_imaging.imDims(2))/2) + 1;
    imgPadX = [imgPadX, imgPadX + param_imaging.imDims(2) - 1];
    imgPadY = floor((netInSize(1) - param_imaging.imDims(1))/2) + 1;
    imgPadY = [imgPadY, imgPadY + param_imaging.imDims(1) - 1];
else
    paddingFlag = false;
    netInSize = param_imaging.imDims;
end
denoiser = get_resized_dnn(netPath, netInSize);

% adaptive network selection
if param_algo.dnnAdaptivePeak
    dnnAdaptivePeakTol = param_algo.dnnAdaptivePeakTolMax;
    peak_curr = param_algo.imPeakEst;
end

%% ALGORITHM
fprintf('\n*************************************************')
fprintf('\n********* STARTING ALGORITHM:   cAIRI   *********')
fprintf('\n*************************************************\n')
% init
MODEL = zeros(param_imaging.imDims);
DUAL = zeros(size(DATA));
[DUAL_proj, ~] = solver_proj_elipse_fb(DUAL, 0, DATA, aW, param_algo.epsilon, zeros(size(DATA)), param_proj.max_itr, param_proj.min_itr, param_proj.eps);
t_total = tic;

for itr = 1:param_algo.imMaxItr
    t_itr = tic;
    MODEL_prev = MODEL;

    % primal update
    t_primal = tic;
    MODEL = MODEL - param_algo.sigma .* adjoint_measop(DUAL);
    % denoising step, apply AIRI denoiser
    if param_algo.dnnApplyTransform
        if paddingFlag
            % padding array if not squre
            MODEL_ = zeros(netInSize);
            MODEL_(imgPadY(1):imgPadY(2), imgPadX(1):imgPadX(2)) = MODEL;
            MODEL = MODEL_;
        end
        rot_id = randi([0, 3]); % times of 90-degree rotation
        do_fliplr = randi([0, 1]); % left-right flip
        do_flipud = randi([0, 1]); % up-down flip

        if rot_id > 0, MODEL = rot90(MODEL, rot_id);
        end
        if do_fliplr, MODEL = fliplr(MODEL);
        end
        if do_flipud, MODEL = flipud(MODEL);
        end
    end

    % apply denoiser
    MODEL = double(predict(denoiser, MODEL./scalingFactor)) .* scalingFactor;

    if param_algo.dnnApplyTransform
        % undo transform
        if do_flipud, MODEL = flipud(MODEL);
        end
        if do_fliplr, MODEL = fliplr(MODEL);
        end
        if rot_id > 0, MODEL = rot90(MODEL, -rot_id);
        end

        if paddingFlag
            MODEL = MODEL(imgPadY(1):imgPadY(2), imgPadX(1):imgPadX(2));
        end
    end

    t_primal = toc(t_primal);

    % dual update
    t_dual = tic;
    DUAL = DUAL ./ aW + measop(2*MODEL-MODEL_prev);
    % l2-ball projection
    [DUAL_proj, ~] = solver_proj_elipse_fb(DUAL, 0, DATA, aW, param_algo.epsilon, DUAL_proj, param_proj.max_itr, param_proj.min_itr, param_proj.eps);
    DUAL = (DUAL - DUAL_proj) .* aW; % Moreau proximal decomposition
    t_dual = toc(t_dual);
    t_itr = toc(t_itr);

    % stopping creteria
    im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all')./(sum(MODEL.^2, 'all') + 1e-10));

    if itr >= param_algo.imMinItr && ... % reach minimum number of iteration
            im_relval < param_algo.imVarTol % reach variation tolerane

        diff = DATA - measop(MODEL);
        data_fidelity = norm(diff(:));

        % print info
        fprintf("\n\nIter %d: relative variation %g, data fidelity %g\ntimings: primal update %f sec, dual update %f sec, iteration %f sec.", ...
            itr, im_relval, data_fidelity, t_primal, t_dual, t_itr);

        if data_fidelity < param_algo.epsilon
            break;
        end
    else
        % print info
        fprintf("\n\nIter %d: relative variation %g\ntimings: primal update %f sec, dual update %f sec, iteration %f sec.", ...
            itr, im_relval, t_primal, t_dual, t_itr);
    end

    % save intermediate results
    if mod(itr, param_imaging.itrSave) == 0
        fitswrite(MODEL, fullfile(param_imaging.resultPath, ...
            ['tmpModel_itr_', num2str(itr), '.fits']))
        RESIDUAL = adjoint_measop(DATA - measop(MODEL));
        fitswrite(RESIDUAL, fullfile(param_imaging.resultPath, ...
            ['tmpResidual_itr_', num2str(itr), '.fits']))
    end

    % adaptive network selection
    if param_algo.dnnAdaptivePeak
        peak_prev = peak_curr;
        peak_curr = max(MODEL, [], 'all');
        peak_var = abs(peak_curr-peak_prev) / abs(peak_prev);
        fprintf('\nModel image peak value %g, relative variation = %g', peak_curr, peak_var);
        % peak value is stable and out of desired range
        if peak_var < dnnAdaptivePeakTol && (peak_curr > peakMax || peak_curr < peakMin)
            [netPath, scalingFactor_new, peakMin, peakMax] = ...
                get_net_detail(param_algo.dnnShelfPath, param_algo.heuristic, peak_curr);
            if scalingFactor_new ~= scalingFactor
                denoiser = get_resized_dnn(netPath, netInSize);
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
FINAL_RESIDUAL = adjoint_measop(DATA - measop(MODEL));

end
