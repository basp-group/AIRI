function [y, flag_data_weighting] = util_load_meas_single(dataFilename, flag_data_weighting)

    try dataloaded = load(dataFilename, 'y', 'nW', 'nWimag');
    catch
        dataloaded = load(dataFilename, 'y', 'nW');
    end
    
    if flag_data_weighting && isfield(dataloaded, 'nWimag') && ~isempty(dataloaded.nWimag)
        y = double(dataloaded.y(:)) .* double(dataloaded.nW(:)) .* double(dataloaded.nWimag(:));
    else
        fprintf('\nINFO: imaging weights will not be applied.');
        flag_data_weighting = false;
        y = double(dataloaded.y(:)) .* double(dataloaded.nW(:));
    end

end