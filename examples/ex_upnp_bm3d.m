clear 
clc

config = ['.', filesep, 'config', filesep, 'airi_sim.json'];
msFile = ['.', filesep, 'simulated_measurements', filesep, 'dt8', filesep, '3c353_lrs_1.0_seed_0.mat'];
resultPath = ['.', filesep, 'results', filesep, '3c353_dt8_seed0', filesep, 'uPnP-BM3D']; 
algorithm = 'upnp-bm3d';
RunID = 0;

run_imager(config, 'msFile', msFile, 'algorithm', algorithm, 'resultPath', resultPath, 'runID', 0)