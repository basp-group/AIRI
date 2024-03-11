clear 
clc

path = fileparts(mfilename('fullpath'));
cd(path)
cd ..

config = ['.', filesep, 'config', filesep, 'airi_sim.json'];
dataFile = ['.', filesep, 'data', filesep, '3c353_meas_dt_1_seed_0.mat'];
groundtruth = ['.', filesep, 'data', filesep, '3c353_gdth.fits'];
resultPath = ['.', filesep, 'results']; 
algorithm = 'cairi';
shelf_pth = ['.', filesep, 'airi_denoisers', filesep, 'shelf_mrid.csv'];
RunID = 4;

run_imager(config, 'dataFile', dataFile, 'algorithm', algorithm, 'resultPath', resultPath, 'dnnShelfPath', shelf_pth, 'groundtruth', groundtruth, 'runID', 0)