clear 
clc

cd ..

config = ['.', filesep, 'config', filesep, 'airi_sim.json'];
dataFile = ['.', filesep, 'examples', filesep, 'simulated_measurements', filesep, 'dt8', filesep, '3c353_lrs_1.0_seed_0.mat'];
resultPath = ['.', filesep, 'results', filesep, '3c353_dt8_seed0', filesep, 'cPnP-BM3D']; 
algorithm = 'cpnp-bm3d';
RunID = 0;

run_imager(config, 'dataFile', dataFile, 'algorithm', algorithm, 'resultPath', resultPath, 'runID', 0)