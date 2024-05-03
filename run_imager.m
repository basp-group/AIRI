function run_imager(json_filename, NameValueArgs)
% Read configuration parameters defined in an input ``.json`` file & Run imager
% Parameters
% ----------
% json_filename : string
%     Name of the .json configuration file.
% NameValueArgs :
% Returns
% -------
% None
%

arguments
    json_filename(1, :) {mustBeFile}
    NameValueArgs.srcName(1, :) {mustBeText}
    NameValueArgs.dataFile(1, :) {mustBeFile}
    NameValueArgs.resultPath(1, :) {mustBeText}
    NameValueArgs.algorithm(1, :) {mustBeMember(NameValueArgs.algorithm, {'airi', 'cairi', 'upnp-bm3d', 'cpnp-bm3d'})}
    NameValueArgs.imDimx(1, 1) {mustBePositive, mustBeInteger}
    NameValueArgs.imDimy(1, 1) {mustBePositive, mustBeInteger}
    NameValueArgs.dnnShelfPath(1, :) {mustBeFile}
    NameValueArgs.imPixelSize(1, 1) {mustBePositive}
    NameValueArgs.superresolution(1, 1) {mustBePositive}
    NameValueArgs.groundtruth(1, :) {mustBeFile}
    NameValueArgs.runID(1, 1) {mustBeNonnegative, mustBeInteger}
end

%% Parsing json file
clc
fid = fopen(json_filename);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);
config = jsondecode(str);

% main input
main = cell2struct(struct2cell(config{1, 1}.main), fieldnames(config{1, 1}.main));
% overwrite fields in main if available
if isfield(NameValueArgs, 'srcName')
    main.srcName = NameValueArgs.srcName;
end
if isfield(NameValueArgs, 'dataFile')
    main.dataFile = NameValueArgs.dataFile;
end
if isfield(NameValueArgs, 'resultPath')
    main.resultPath = NameValueArgs.resultPath;
end
if isfield(NameValueArgs, 'imDimx')
    main.imDimx = NameValueArgs.imDimx;
end
if isfield(NameValueArgs, 'imDimy')
    main.imDimy = NameValueArgs.imDimy;
end
if isfield(NameValueArgs, "algorithm")
    main.algorithm = NameValueArgs.algorithm;
end
if isfield(NameValueArgs, 'imPixelSize')
    main.imPixelSize = NameValueArgs.imPixelSize;
end
if isfield(NameValueArgs, 'superresolution')
    main.superresolution = NameValueArgs.superresolution;
end
if isfield(NameValueArgs, 'groundtruth')
    main.groundtruth = NameValueArgs.groundtruth;
end
if isfield(NameValueArgs, 'runID')
    main.runID = NameValueArgs.runID;
end
disp(main)

% flag
param_flag = cell2struct(struct2cell(config{2, 1}.flag), fieldnames(config{2, 1}.flag));
disp(param_flag)

% other parameters
param_other = cell2struct(struct2cell(config{2, 1}.other), fieldnames(config{2, 1}.other));
disp(param_other)

% solver
switch main.algorithm
    case 'airi'
        param_solver = cell2struct(struct2cell(config{3, 1}.airi), fieldnames(config{3, 1}.airi));
        param_solver_default = cell2struct(struct2cell(config{3, 1}.airi_default), fieldnames(config{3, 1}.airi_default));
        param_solver = cell2struct([struct2cell(param_solver); struct2cell(param_solver_default)], ...
            [fieldnames(param_solver); fieldnames(param_solver_default)]);
        if isfield(NameValueArgs, 'dnnShelfPath')
            param_solver.dnnShelfPath = NameValueArgs.dnnShelfPath;
        end
    case 'cairi'
        param_solver = cell2struct(struct2cell(config{3, 1}.cairi), fieldnames(config{3, 1}.cairi));
        param_solver_default = cell2struct(struct2cell(config{3, 1}.cairi_default), fieldnames(config{3, 1}.cairi_default));
        param_solver = cell2struct([struct2cell(param_solver); struct2cell(param_solver_default)], ...
            [fieldnames(param_solver); fieldnames(param_solver_default)]);
        if isfield(NameValueArgs, 'dnnShelfPath')
            param_solver.dnnShelfPath = NameValueArgs.dnnShelfPath;
        end
    case 'upnp-bm3d'
        param_solver = cell2struct(struct2cell(config{3, 1}.upnp_bm3d), fieldnames(config{3, 1}.upnp_bm3d));
        param_solver_default = cell2struct(struct2cell(config{3, 1}.upnp_bm3d_default), fieldnames(config{3, 1}.upnp_bm3d_default));
        param_solver = cell2struct([struct2cell(param_solver); struct2cell(param_solver_default)], ...
            [fieldnames(param_solver); fieldnames(param_solver_default)]);
    case 'cpnp-bm3d'
        param_solver = cell2struct(struct2cell(config{3, 1}.cpnp_bm3d), fieldnames(config{3, 1}.cpnp_bm3d));
        param_solver_default = cell2struct(struct2cell(config{3, 1}.cpnp_bm3d_default), fieldnames(config{3, 1}.cpnp_bm3d_default));
        param_solver = cell2struct([struct2cell(param_solver); struct2cell(param_solver_default)], ...
            [fieldnames(param_solver); fieldnames(param_solver_default)]);
    otherwise
        error("Algorithm %s not found\n", main.algorithm)
end
param_solver.algorithm = main.algorithm;
disp(param_solver)

% full param list
param_general = cell2struct([struct2cell(param_flag); struct2cell(param_other); struct2cell(param_solver)], ...
    [fieldnames(param_flag); fieldnames(param_other); fieldnames(param_solver)]);
param_general.resultPath = main.resultPath;
param_general.srcName = main.srcName;
param_general.groundtruth = main.groundtruth;

% set fields to default value if missing
% set main path for the program
if isfield(main, 'dirProject') && ~isempty(main.dirProject)
    param_general.dirProject = main.dirProject;
else
    param_general.dirProject = [pwd, filesep];
end
% general flag
if ~isfield(param_general, 'flag_imaging')
    param_general.flag_imaging = true;
end
if ~isfield(param_general, 'flag_data_weighting')
    param_general.flag_data_weighting = true;
end
if ~isfield(param_general, 'verbose')
    param_general.verbose = true;
end
% super-resolution factor
if isfield(main, 'superresolution') && ~isempty(main.superresolution)
    param_general.superresolution = main.superresolution; % the ratio between the given max projection base line and the desired one
else
    param_general.superresolution = 1.0;
end
% compute resources
if isfield(param_general, 'ncpus') && ~isempty(param_general.ncpus)
    navail = maxNumCompThreads;
    nrequested = maxNumCompThreads(param_general.ncpus);
    fprintf("\nINFO: Available CPUs: %d. Requested CPUs: %d\n", navail, maxNumCompThreads)
else
    fprintf("\nINFO: Available CPUs: %d.\n", maxNumCompThreads)
end

disp(param_general)

fprintf("\n________________________________________________________________\n")

%% main function
imager(main.dataFile, main.imPixelSize, main.imDimx, main.imDimy, param_general, main.runID);

end