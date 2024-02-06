function param_general = util_set_param_general(param_general)

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
    if ~isfield(param_general, 'nufft_superresolution')
        param_general.nufft_superresolution = 1.0; % the ratio between the given max projection base line and the desired one 
    end

end