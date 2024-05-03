function [FINAL_MODEL, FINAL_RESIDUAL] = upnp_bm3d(dirtyIm, measop, adjoint_measop, param_imaging, param_algo)

%% ************************************************************************
% *************************************************************************
% Imaging: unconstrained plug-and-play algorithm base on forward-backward
% *************************************************************************

%% ALGORITHM
fprintf('\n*************************************************')
fprintf('\n********* STARTING ALGORITHM: uPNP-BM3D *********')
fprintf('\n*************************************************\n')
% init
MODEL = zeros(param_imaging.imDims);
t_total = tic;

for itr = 1:param_algo.imMaxItr
    t_itr = tic;
    MODEL_prev = MODEL;

    % (forward) gradient step
    t_grad = tic;
    Xhat = MODEL - param_algo.gamma * (adjoint_measop(measop(MODEL)) - dirtyIm);
    t_grad = toc(t_grad);

    % (backward) denoising step
    t_den = tic;

    % BM3D
    Xhat(Xhat < 0) = 0;
    currPeak = max(Xhat, [], 'all');
    if currPeak < 1.0
        currPeak = 1.0;
    end
    MODEL = BM3D(Xhat/currPeak, param_algo.heuristic) * currPeak;

    t_den = toc(t_den);
    t_itr = toc(t_itr);

    % print info
    im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all')./(sum(MODEL.^2, 'all') + 1e-10));
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
