clear 
clc

config = ['.', filesep, 'config', filesep, 'airi_sim.json'];
msFile = ['.', filesep, 'simulated_measurements', filesep, 'dt8', filesep, '3c353_lrs_1.0_seed_0.mat'];
resultPath = ['.', filesep, 'results', filesep, '3c353_dt8_seed0', filesep, 'cAIRI-MRID']; 
algorithm = 'cairi';
shelf_pth = ['.', filesep, 'airi_denoisers', filesep, 'shelf_mrid.csv']
RunID = 0;

run_imager(config, 'msFile', msFile, 'algorithm', algorithm, 'resultPath', resultPath, 'dnnShelfPath', shelf_pth, 'runID', 0)