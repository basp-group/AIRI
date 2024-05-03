function [FINAL_MODEL, FINAL_RESIDUAL] = cpnp_bm3d(DATA, measop, adjoint_measop, aW, param_imaging, param_algo)

%% ************************************************************************
% *************************************************************************
% Imaging: constrained plug-and-play algorithm based on primal-dual
% *************************************************************************

%% Initialization
% Ellipsoid projection parameters
param_proj.min_itr = 1;
param_proj.max_itr = 10;
param_proj.eps = 1e-6;

%% ALGORITHM
fprintf('\n*************************************************')
fprintf('\n********* STARTING ALGORITHM: cPNP-BM3D *********')
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
    % denoising step, apply BM3D denoiser
    MODEL(MODEL < 0) = 0;
    currPeak = max(MODEL, [], 'all');
    if currPeak <= 1.0
        currPeak = 1.0;
    end
    MODEL = BM3D(MODEL/currPeak, param_algo.heuristic) * currPeak;
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
