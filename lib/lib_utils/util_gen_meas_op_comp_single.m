function [A, At, G, W, nWi, aW] = util_gen_meas_op_comp_single(dataFilename, imDimx, imDimy, flag_data_weighting, param_nufft, param_wproj, param_precond)
                                                                     % nDataSets, ddesfilename
    % Build the measurement operator for a given uv-coverage at pre-defined
    % frequencies.
    %
    % Parameters
    % ----------
    % dataFilename: function handle
    %     Filenames of the data files to load ``u``, ``v`` and ``w`` coordinates and
    %     ``nW`` the weights involved in natural weighting.
    % imDimx : int
    %     Image dimension (x-axis).
    % imDimy : int
    %     Image dimension (y-axis).
    % flag_data_weighting : boolean    
    %      apply data-weighting scheme (e.g., briggs, uniform)
    % param_nufft : struct
    %     Structure to configure NUFFT.
    % param_wproj : struct
    %     Structure to configure w-projection.
    %

    % Returns
    % -------
    % A : function handle
    %     Function to compute the rescaled 2D Fourier transform involved
    %     in the emasurement operator.
    % At : function handle
    %     Function to compute the adjoint of ``A``.
    % G : cell of cell of complex[:]
    %     Cell containing the trimmed-down interpolation kernel.
    % W : cell of cell of double[:]
    %     Cell containing the selection vector.
    % aW : cell of cell of double[:]
    %     Cell containing the preconditioning vectors.
    % nWi : cell of cell of single[:]
    %     Cell containing the imaging weights (uniform/briggs).
    %%
    % speed_of_light = 299792458;

    param_nufft.N = [imDimy, imDimx];
    param_nufft.Nn = [param_nufft.Ky, param_nufft.Kx];
    param_nufft.No = [param_nufft.oy * imDimy, param_nufft.ox * imDimx];
    param_nufft.Ns = [imDimy / 2, imDimx / 2];

    if flag_data_weighting
        load(dataFilename, 'u', 'v', 'w', 'nW', 'frequency', 'nWimag');
        nW = nW .* nWimag;
    else
        load(dataFilename, 'u', 'v', 'w', 'nW', 'frequency');
    end
    % wavelength = speed_of_light / frequency;
    % u v  are in units of the wavelength and will be normalised between [-pi,pi] for the NUFFT
    u = double(u(:)) * pi / double(param_wproj.halfSpatialBandwidth);
    v = -double(v(:)) * pi / double(param_wproj.halfSpatialBandwidth);
    w = -double(w(:)); % !! add -1 to w coordinate
    nW = double(nW(:));

    % measurement operator initialization
    [A, At, G, W] = op_p_nufft_wproj_dde(param_nufft, [{v} {u}], {w}, {nW}, param_wproj);

    % compute uniform weights (sampling density) for the preconditioning
    aW = util_gen_preconditioning_matrix(u, v, param_precond);

    clear u v w nW;
    G = G{1};
    W = W{1};

    if flag_data_weighting
        nWi = double(nWimag(:)); 
        clear nWimag;
    else
        nWi = [];
    end

end
