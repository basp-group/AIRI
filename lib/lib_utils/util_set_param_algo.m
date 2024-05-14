function param_algo = util_set_param_algo(param_general, heuristic_noise, peak_est, numMeas)

% algorithm type
param_algo.algorithm = param_general.algorithm;
flag_airi = ismember(param_general.algorithm, {'airi', 'cairi'});
flag_constrained = ismember(param_general.algorithm, {'cairi', 'cpnp-bm3d'});

% parameters shared by all algorithms
% max number of iterations
if ~isfield(param_general, 'imMaxItr') || ~isscalar(param_general.imMaxItr)
    param_algo.imMaxItr = 2000;
else
    param_algo.imMaxItr = param_general.imMaxItr;
end
% min number of iterations
if ~isfield(param_general, 'imMinItr') || ~isscalar(param_general.imMaxItr)
    param_algo.imMinItr = 200;
else
    param_algo.imMinItr = param_general.imMinItr;
end
% image variation tolerance
if ~isfield(param_general, 'imVarTol') || ~isscalar(param_general.imVarTol) || param_general.imVarTol <= 0
    param_algo.imVarTol = 1e-5;
else
    param_algo.imVarTol = param_general.imVarTol;
end
% heuristic noise scale
if ~isfield(param_general, 'heuNoiseScale') || ~isscalar(param_general.heuNoiseScale) || param_general.heuNoiseScale <= 0
    param_algo.heuNoiseScale = 1.0;
else
    param_algo.heuNoiseScale = param_general.heuNoiseScale;
end
% heuristic noise level
if param_algo.heuNoiseScale ~= 1.0
    heuristic_noise = heuristic_noise * param_algo.heuNoiseScale;
    fprintf('\nINFO: heuristic noise level after scaling: %g', heuristic_noise);
end
param_algo.heuristic = heuristic_noise;
% estimated image peak value
if ~isfield(param_general, 'imPeakEst') || ~isscalar(param_general.imPeakEst) || param_general.imPeakEst <= 0
    param_algo.imPeakEst = peak_est;
    fprintf("\nINFO: use normalised dirty peak as estimated image peak value: %g", param_algo.imPeakEst)
else
    param_algo.imPeakEst = param_general.imPeakEst;
    fprintf("\nINFO: user specified the estimated image peak value: %g", param_algo.imPeakEst)
end

% parameters shared by AIRI algorithms
if flag_airi
    % activate adaptive network selecting scheme
    if ~isfield(param_general, 'dnnAdaptivePeak')
        param_algo.dnnAdaptivePeak = true;
    else
        param_algo.dnnAdaptivePeak = param_general.dnnAdaptivePeak;
    end
    % activate random transform before applying denoisers to images
    if ~isfield(param_general, 'dnnApplyTransform')
        param_algo.dnnApplyTransform = true;
    else
        param_algo.dnnApplyTransform = param_general.dnnApplyTransform;
    end
    % max tolerance for relative image peak value variation
    if ~isfield(param_general, 'dnnAdaptivePeakTolMax') || ~isscalar(param_general.dnnAdaptivePeakTolMax) || param_general.dnnAdaptivePeakTolMax <= 0
        param_algo.dnnAdaptivePeakTolMax = 1e-1;
    else
        param_algo.dnnAdaptivePeakTolMax = param_general.dnnAdaptivePeakTolMax;
    end
    % min tolerance for relative image peak value variation
    if ~isfield(param_general, 'dnnAdaptivePeakTolMin') || ~isscalar(param_general.dnnAdaptivePeakTolMin) || param_general.dnnAdaptivePeakTolMin <= 0
        param_algo.dnnAdaptivePeakTolMin = 1e-3;
    else
        param_algo.dnnAdaptivePeakTolMin = param_general.dnnAdaptivePeakTolMin;
    end
    % decaying factor for the tolerance of relative image peak value variation
    if ~isfield(param_general, 'dnnAdaptivePeakTolStep') || ~isscalar(param_general.dnnAdaptivePeakTolStep) || param_general.dnnAdaptivePeakTolStep <= 0
        param_algo.dnnAdaptivePeakTolStep = 0.1;
    else
        param_algo.dnnAdaptivePeakTolStep = param_general.dnnAdaptivePeakTolStep;
    end
    % path to the denoiser shelf
    if ~isfield(param_general, 'dnnShelfPath')
        param_algo.dnnShelfPath = fullfile(param_general.dirProject, 'airi_denoisers', 'shelf_oaid.csv');
    else
        param_algo.dnnShelfPath = param_general.dnnShelfPath;
    end
else
    % pnp with BM3D denoiser
    if ~isfield(param_general, 'dirBM3DLib') || isempty(param_general.dirBM3DLib)
        addpath(fullfile(param_general.dirProject, 'lib', 'bm3d'))
    else
        addpath(param_general.dirBM3DLib)
    end
end

% parameters shared by constrained algorithms
if flag_constrained
    % TODO: user specifiy l2 error bound
    % Theoretical l2 error bound, assume chi-square distribution, tau=1
    param_algo.epsilon = sqrt(numMeas+2*sqrt(numMeas));
    param_algo.sigma = 0.5 / param_general.measOpNormCmp;

else
    % step size
    param_algo.gamma = 1.98 / param_general.measOpNorm;
end

end