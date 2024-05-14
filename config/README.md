# Configuration (parameter) file

The algorithms implemented in this repository are launched through the function ``run_imager()``. This function accepts a ``.json`` file where all the parameters required by the algorithms are defined. A sample configuration file ``airi_sim.json`` is given in the folder ``$AIRI/config``. In this document, we'll provide explanations for all the fields in this file.

The configuration file is composed by three parts, i.e. Main, General and Denoiser. 

1. Main
    - ``srcName``(optional): Experiment/target source name tag, used in the output filenames. If this field is empty, the script will take the filename given in the ``dataFile``.
    - ``dataFile``: Path to the measurement (data) file. The measurement file must be in ``.mat`` format containing fields discussed [here](https://github.com/basp-group/AIRI?tab=readme-ov-file#measurement-file).
    - ``resultPath``(optional): Path to the output files. The script will create a folder in ``$resultPath`` with name ``${srcname}_${algorithm}_ID_${runID}_heuScale_${heuNoiseScale}_maxItr_${imMaxItr}``. The results will then be saved in this folder. Default: ``$AIRI/results``
    - ``algorithm``: Imaging algorithm, must be set to ``airi``, ``upnp-bm3d``, ``cAIRI`` or ``cpnp-bm3d``.
    - ``imDimx``: Horizontal dimension of the estimated image.
    - ``imDimy``: Vertical dimension of the estimated image.
    - ``imPixelSize``(optional): Pixel size of the estimated image in the unit of arcsec. If empty, its value is inferred from ``superresolution`` such that ``imPixelSize = (180 / pi) * 3600 / (superresolution * 2 * maxProjBaseline)``.
    - ``superresolution``(optional): Imaging super-resolution factor, used when the pixel size is not provided (recommended to be in ``[1.5, 2.5]``). Default: ``1.0``.
    - ``groundtruth``(optional): Path of the groundtruth image. The file must be in ``.fits `` format, and is used to compute reconstruction metrics if a valid path is provided.
    - ``runID``(optional): Identification number of the current task.

    The values of the entries in Main will be overwritten if corresponding name-value arguments are fed into the function ``run_imager()``.

2. General
    - ``flag``
        - ``flag_imaging``(optional): Enable imaging. If ``false``, the back-projected data (dirty image) and corresponding PSF are generated. Default: ``true``.
        - ``flag_data_weighting``(optional): Enable data-weighting scheme. Default: ``true``.

    - ``other``
        - ``dirProject``(optional): Path to project repository. Default: MATLAB's current running path.
        - ``ncpus``(optional): Number of CPUs used for imaging task. If empty, the script will make use of the available CPUs.
        - ``weight_type``(optional): The data-weighting scheme (``briggs``, ``uniform``). Default: ``uniform`` if ``flag_data_weighting`` is ``true``, empty otherwise.
        - ``weight_robustness``(optional): Briggs (robust) parameter to be set in ``[-2, 2]``. Default: ``0``.
        - ``weight_gridsize``(optional): Padding factor involved in the density of the sampling. Default: ``2``.
        - ``weight_load``(optional): Flag to indicate if imaging weights are available in the data file. Default: false.

3. Denoiser
    - ``airi`` and ``airi_default``
        
        If the imaging ``algorithm``is specified as ``airi``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): Adjusting factor applied to the heuristic noise level. Default: ``1.0``.
        - ``dnnShelfPath``: Path of the ``.csv`` file that defines a shelf of denoisers. The ``.csv`` file has two columns. The first column is the training noise level of a denoiser and the second column is the path to the denoiser. The denoiser must be in ``.onnx`` format. Two sample ``.csv`` files are provided in ``$AIRI/airi_denoisers``.
        - ``imPeakEst``(optional): Estimated maximum intensity of the true image. If this field is empty, the default value is the maximum intensity of the back-projected (dirty) image normalised by the peak value of the PSF.
        - ``dnnAdaptivePeak``(optional): Enable the adaptive denoiser selection scheme. The details of this scheme can be found in [[1]](https://arxiv.org/abs/2312.07137v2). Default: ``true``.
        - ``dnnApplyTransform``(optional): Apply random rotation and flipping before denoising then undo the transform after denoising. Default: ``true``.
        - ``imMinItr``(optional): Minimum number of iterations in the forward-backward algorithm. Default: ``200``.
        - ``imMaxItr``(optional): Maximum number of iterations in the forward-backward algorithm. Default: ``2000``.
        - ``imVarTol``(optional): Tolerance on the relative variation of the estimation in the forward-backward algorithm to indicate convergence. Default: ``1e-4``.
        - ``itrSave``(optional): Interval of iterations for saving intermediate results. Default: ``500``.
        - ``dnnAdaptivePeakTolMax``(optional): Initial relative peak value variation tolerance for the adaptive denoiser selection scheme. Default: ``0.1``.
        - ``dnnAdaptivePeakTolMin``(optional): Minimum relative peak value variation tolerance for the adaptive denoiser selection scheme. Default: ``1e-3``.
        - ``dnnAdaptivePeakTolStep``(optional): Decaying factor for the relative peak value variation tolerance in the adaptive denoiser selection scheme. It will be applied to the current tolerance after one time of denoiser reselection. Default: ``0.1``.

    - ``upnp_bm3d`` and ``upnp_bm3d_default``

        If the imaging ``algorithm``is specified as ``upnp-bm3d``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): Adjusting factor applied to the heuristic noise level. Default: ``1.0``.
        - ``dirBM3DLib``(optional): Path to the BM3D MATLAB library. Default: ``$AIRI/lib/bm3d``.
        - ``imMinItr``(optional): Minimum number of iterations in the forward-backward algorithm. Default: ``200``.
        - ``imMaxItr``(optional): Maximum number of iterations in the forward-backward algorithm. Default: ``2000``.
        - ``imVarTol``(optional): Tolerance on the relative variation of the estimation in the forward-backward algorithm to indicate convergence. Default: ``1e-4``.
        - ``itrSave``(optional): Interval of iterations for saving intermediate results. Default: ``500``.

    - ``cairi`` and ``cairi_default``

        If the imaging ``algorithm``is specified as ``cairi``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): Adjusting factor applied to the heuristic noise level. Default: ``1.0``.
        - ``dnnShelfPath``: Path of the ``.csv`` file that defines a shelf of denoisers. The ``.csv`` file has two columns. The first column is the training noise level of a denoiser and the second column is the path to the denoiser. The denoiser must be in ``.onnx`` format. Two sample ``.csv`` files are provided in ``$AIRI/airi_denoisers``.
        - ``imPeakEst``(optional): Estimated maximum intensity of the true image. If this field is empty, the default value is the maximum intensity of the back-projected (dirty) image normalised by the peak value of the PSF.
        - ``dnnAdaptivePeak``(optional): Enable the adaptive denoiser selection scheme. The details of this scheme can be found in [[1]](https://arxiv.org/abs/2312.07137v2). Default: ``true``.
        - ``dnnApplyTransform``(optional): Apply random rotation and flipping before denoising then undo the transform after denoising. Default: ``true``.
        - ``imMinItr``(optional): Minimum number of iterations in the primal-dual algorithm. Default: ``200``.
        - ``imMaxItr``(optional): Maximum number of iterations in the primal-dual algorithm. Default: ``2000``.
        - ``imVarTol``(optional): Tolerance on the relative variation of the estimation in the primal-dual algorithm to indicate convergence. Default: ``1e-4``.
        - ``itrSave``(optional): Interval of iterations for saving intermediate results. Default: ``500``.
        - ``dnnAdaptivePeakTolMax``(optional): Initial relative peak value variation tolerance for the adaptive denoiser selection scheme. Default: ``0.1``.
        - ``dnnAdaptivePeakTolMin``(optional): Minimum relative peak value variation tolerance for the adaptive denoiser selection scheme. Default: ``1e-3``.
        - ``dnnAdaptivePeakTolStep``(optional): Decaying factor for the relative peak value variation tolerance in the adaptive denoiser selection scheme. It will be applied to the current tolerance after one time of denoiser reselection. Default: ``0.1``.

    - ``cpnp_bm3d`` and ``cpnp_bm3d_default``

        If the imaging ``algorithm``is specified as ``cpnp-bm3d``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): Adjusting factor applied to the heuristic noise level. Default: ``1.0``.
        - ``dirBM3DLib``(optional): Path to the BM3D MATLAB library. Default: ``$AIRI/lib/bm3d``.
        - ``imMinItr``(optional): Minimum number of iterations in the primal-dual algorithm. Default: ``200``.
        - ``imMaxItr``(optional): Maximum number of iterations in the primal-dual algorithm. Default: ``2000``.
        - ``imVarTol``(optional): Tolerance on the relative variation of the estimation in the primal-dual algorithm to indicate convergence. Default: ``1e-4``.
        - ``itrSave``(optional): Interval of iterations for saving intermediate results. Default: ``500``.

    

    
