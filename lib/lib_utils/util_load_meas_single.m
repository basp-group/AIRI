function [y, flag_data_weighting] = util_load_meas_single(dataFilename, flag_data_weighting)

    dataloaded = load(dataFilename, 'y', 'nW', 'nWimag');
    if flag_data_weighting && ~isempty(dataloaded.nWimag)
        y = double(dataloaded.y(:)) .* double(dataloaded.nW(:)) .* double(dataloaded.nWimag(:));
    else
        fprintf('\nINFO: imaging weights will not be applied.');
        flag_data_weighting = false;
        y = double(dataloaded.y(:)) .* double(dataloaded.nW(:));
    end

end