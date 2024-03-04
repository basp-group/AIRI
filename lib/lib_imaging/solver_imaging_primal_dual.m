function RESULTS = solver_imaging_primal_dual(DATA, FWOp, BWOp, param_imaging, param_algo)
%% ************************************************************************
% *************************************************************************
% Imaging: primal-dual algorithm
% *************************************************************************
%% Initialization

% initial image model
MODEL = zeros(param_imaging.imDims);
DUAL = zeros(size(DATA));
% calculate dirty image
DirtyIm = BWOp(DATA);
% l2-ball projection
prox_l2ball = @(z,c,radius) (z - c) * min(radius / norm(z(:)-c(:)), 1) + c;
% AIRI specific
flag_airi = strcmp(param_algo.algorithm, 'cairi');
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

    algo_print_name = '  cAIRI  ';
else
    algo_print_name = 'cPNP-BM3D';
end

%% ALGORITHM
fprintf('\n*************************************************\n')
fprintf('********* STARTING ALGORITHM: %s *********', algo_print_name)
fprintf('\n*************************************************\n')

tStart_total = tic;
for iter = 1 : param_algo.imMaxItr
    tStart_iter =tic;
    MODEL_prev = MODEL;

    % primal update
    tStart_primal =tic;
    MODEL = MODEL - param_algo.sigma .* BWOp(DUAL);
    % denoising step
    if flag_airi
        % apply AIRI denoiser
        if param_algo.dnnApplyTransform
            rot_id  = randi([0 3]); % times of 90-degree rotation
            do_fliplr = randi([0 1]); % left-right flip
            do_flipud = randi([0 1]); % up-down flip

            if rot_id > 0, MODEL = rot90(MODEL,rot_id);
            end
            if do_fliplr,  MODEL = fliplr(MODEL);
            end
            if do_flipud , MODEL = flipud(MODEL);
            end
        end
        
        % apply denoiser
        MODEL = double(predict(denoiser, MODEL./scalingFactor)).*scalingFactor;

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
        MODEL(MODEL<0) = 0;
        currPeak = max(MODEL, [], 'all');
        if currPeak <= 1.0
            currPeak = 1.0;
        end
        MODEL = BM3D(MODEL/currPeak, param_algo.heuristic) * currPeak;
    end
    t_primal = toc(tStart_primal);

    % dual update
    tStart_dual = tic;
    DUAL = DUAL + FWOp(2*MODEL - MODEL_prev);
    % l2-ball projection
    DUAL_proj = prox_l2ball(DUAL, DATA, param_algo.epsilon);
    DUAL = DUAL - DUAL_proj; % Moreau proximal decomposition
    t_dual = toc(tStart_dual);
    t_iter = toc(tStart_iter);

    % stopping creteria
    im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
    
    if iter >= param_algo.imMinItr && ... % reach minimum number of iteration
        im_relval < param_algo.imVarTol % reach variation tolerane

        diff = DATA - FWOp(MODEL);
        data_fidelity = norm(diff(:));

        % print info
        fprintf("\n\nIter %d: relative variation %g, data fidelity %g, primal update %f sec, dual update %f sec, current iteration %f sec.", ...
            iter, im_relval, data_fidelity, t_primal, t_dual, t_iter);

        if data_fidelity < param_algo.epsilon
            break;
        end
    else
        % print info
        fprintf("\n\nIter %d: relative variation %g, primal update %f sec, dual update %f sec, current iteration %f sec.", ...
            iter, im_relval, t_primal, t_dual, t_iter);
    end

    % save intermediate results
    if mod(iter, param_imaging.itrSave) == 0
        fitswrite(MODEL, fullfile(param_imaging.resultPath, ...
            ['tempModel_iter_', num2str(iter), '.fits']))
        RESIDUAL = DirtyIm - BWOp(FWOp(MODEL));
        fitswrite(RESIDUAL, fullfile(param_imaging.resultPath, ...
            ['tempResidual_iter_', num2str(iter), '.fits']))
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
t_total = toc(tStart_total);

fprintf("\n\nImaging finished in %f sec, total number of iterations %d\n\n", t_total, iter);
fprintf('\n**************************************\n')
fprintf('********** END OF ALGORITHM **********')
fprintf('\n**************************************\n')

%% Final variables
RESULTS.MODEL = MODEL; %reconstructed image
RESULTS.RESIDUAL = DirtyIm - BWOp(FWOp(MODEL)); %reconstructed image

end
