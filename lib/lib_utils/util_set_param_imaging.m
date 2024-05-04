function param_imaging = util_set_param_imaging(param_general, param_algo, imDims)

% set subfolder name for saving results
switch param_general.algorithm
    case 'airi'
        subFolerName = [param_general.srcName, '-AIRI_heuScale_', ...
            num2str(param_algo.heuNoiseScale), ...
            '_maxItr_', num2str(param_algo.imMaxItr)];
    case 'cairi'
        subFolerName = [param_general.srcName, '-cAIRI_heuScale_', ...
            num2str(param_algo.heuNoiseScale), ...
            '_maxItr_', num2str(param_algo.imMaxItr)];
    case 'upnp-bm3d'
        subFolerName = [param_general.srcName, '-uPnP-BM3D_heuScale_', ...
            num2str(param_algo.heuNoiseScale), ...
            '_maxItr_', num2str(param_algo.imMaxItr)];
    case 'cpnp-bm3d'
        subFolerName = [param_general.srcName, '-cPnP-BM3D_heuScale_', ...
            num2str(param_algo.heuNoiseScale), ...
            '_maxItr_', num2str(param_algo.imMaxItr)];
end
% set full path
param_imaging.resultPath = fullfile(param_general.resultPath, subFolerName);
if ~exist(param_imaging.resultPath, 'dir')
    mkdir(param_imaging.resultPath)
end

fprintf('\nINFO: results will be saved in ''%s''', param_imaging.resultPath);

% interval for saveing intermediate results
if ~isfield(param_general, 'itrSave') || ~isscalar(param_general.itrSave)
    param_imaging.itrSave = 500;
elseif param_general.itrSave < 1
    param_imaging.itrSave = param_algo.imMaxItr + 1; % do not save intermediate results
else
    param_imaging.itrSave = floor(param_general.itrSave);
end

% set image dimension
param_imaging.imDims = imDims;

% imaging & verbose flag
param_imaging.flag_imaging = param_general.flag_imaging;
param_imaging.verbose = param_general.verbose;

% groundtruth image
param_imaging.groundtruth = param_general.groundtruth;

end