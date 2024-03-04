# Configuration (parameter) file

The algorithms implemented in this repository are launched through the function ``run_imager()``. This function accepts a ``.json`` file where all the parameters required by different algorithms for imaging are defined. A sample configuration file ``airi_sim.json`` is given in the folder ``$AIRI/config``. In this document, we'll provide explanations for all the fields in this file.

The configuration file is composed by three parts, i.e. Main, General and Denoiser. 

1. Main
    - ``srcName``(optional): The name for the reconstruction task. If this field is empty, the script will take the file name given in the ``dataFile`` as the task's name.
    - ``dataFile``: The path of the measurement file. The measurement file should be in ``.mat`` format containing fields discussed [here](https://github.com/basp-group/AIRI?tab=readme-ov-file#measurement-file).
    - ``resultPath``(optional): The path where the result folder will be created. The script will create a folder in ``$resultPath`` with name ``${srcname}_${algorithm}_ID_${runID}_heuScale_${heuNoiseScale}_maxItr_${imMaxItr}``. The results will then be saved in this folder. If this field is empty, the default value is ``$AIRI/results``
    - ``algorithm``: The algorithm that will be used for imaging. It has to be chosen from ``airi``, ``upnp-bm3d``, ``cAIRI`` or ``cpnp-bm3d``.
    - ``imDimx``: The horizontal number of pixels in the final reconstructed image.
    - ``imDimy``: The vertical number of pixels in the final reconstructed image.
    - ``imPixelSize``(optional): The pixel size of the reconstructed image in the unit of arcsec. If this field is empty, the script will infer the value from ``superresolution`` with equation ``imPixelSize = (180 / pi) * 3600 / (superresolution * 2 * maxProjBaseline)``. The value of ``maxProjBaseline`` is given in the measurement file.
    - ``superresolution``(optional): The ratio between the expected maximum projection baseline and the one given in the measurement file. The default value is ``1.0``.
    - ``groundtruth``(optional): The path of the groundtruth image. The image should be in ``.fits `` format. If the path is given, the script will calculate the signal-to-noise ratio (SNR) between the reconstructed images and the groundtruth image and print the SNR result in the log.
    - ``runID``(optional): The identification number of the current task. The default value is ``0``.

    The values of the entries in Main will be overwritten if corresponding name-value arguments are fed into the function ``run_imager()``.

2. General
    - ``flag``
        - ``flag_imaging``(optional): Run imaging algorithms or not. If the value is false, then the script will only generate the back-projected (dirty) images and the PSF. The default value is true.
        - ``flag_data_weighting``(optional): Use the image weighting ``nWimag`` given in the measurement files or not. The default value is true.

    - ``other``
        - ``dirProject``(optional): The path of the local AIRI repository. If this field is empty, the default value is MATLAB's current running path.
        - ``ncpus``(optional): Number of CPUs that will be used for imaging tasks. If it is empty, the script will try to use all the available CPUs.

3. Denoiser
    - ``airi`` and ``airi_default``
        
        If the imaging ``algorithm``is specified as ``airi``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): The factor that will be applied to the heuristic noise level. The default value is ``1.0``.
        - ``dnnShelfPath``: The path of the ``.csv`` file that defines a shelf of denoisers. The ``.csv`` file has two columns. The first column is the training noise level of a denoiser and the second column is the path to the denoiser. The denoiser should be in ``.onnx`` format. Two sample ``.csv`` files are provided in ``$AIRI/airi_denoisers``.
        - ``imPeakEst``(optional): The estimated maximum intensity of the reconstructions. If this field is empty, the default value is the maximum intensity of the back-projected (dirty) image normalised by the peak value of the PSF.
        - ``dnnAdaptivePeak``(optional): Enable the adaptive denoiser selection scheme or not. The details of this scheme can be found in [[1]](https://arxiv.org/abs/2312.07137v2). The default value is true.
        - ``dnnApplyTransform``(optional): Apply random rotation and flipping before denoising and undo the transform after denoising or not. The default value is true.
        - ``imMinItr``(optional): The minimum number of iterations of the algorithm. The default value is ``200``.
        - ``imMaxItr``(optional): The minimum number of iterations of the algorithm. The default value is ``2000``.
        - ``imVarTol``(optional): The image variation tolerance of the algorithm. If the relative variation of the reconstructed images from two consecutive iterations is smaller than the value of ``imVarTol`` and the algorithm has run more iterations than ``imMinItr``, then the imaging process will be ended. The default value is ``1e-4``.
        - ``itrSave``(optional): The interval of iterations for saving intermediate results. The default number is ``500``.
        - ``dnnAdaptivePeakTolMax``(optional): The initial relative peak value variation tolerance for the adaptive denoiser selection scheme. The default value is ``0.1``.
        - ``dnnAdaptivePeakTolMin``(optional): The minimum relative peak value variation tolerance for the adaptive denoiser selection scheme. The default value is ``1e-3``.
        - ``dnnAdaptivePeakTolStep``(optional): The decaying factor for the relative peak value variation tolerance in the adaptive denoiser selection scheme. It will be applied to the current tolerance after one time of denoiser reselection. The default value is ``0.1``.

    - ``upnp_bm3d`` and ``upnp_bm3d_default``

        If the imaging ``algorithm``is specified as ``upnp-bm3d``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): The factor that will be applied to the heuristic noise level. The default value is ``1.0``.
        - ``dirBM3DLib``(optional): The path of the BM3D MATLAB library. The default path is ``$AIRI/lib/bm3d``.
        - ``imMinItr``(optional): The minimum number of iterations of the algorithm. The default value is ``200``.
        - ``imMaxItr``(optional): The minimum number of iterations of the algorithm. The default value is ``2000``.
        - ``imVarTol``(optional): The image variation tolerance of the algorithm. If the relative variation of the reconstructed images from two consecutive iterations is smaller than the value of ``imVarTol`` and the algorithm has run more iterations than ``imMinItr``, then the imaging process will be ended. The default value is ``1e-4``.
        - ``itrSave``(optional): The interval of iterations for saving intermediate results. The default number is ``500``.

    - ``cairi`` and ``cairi_default``

        If the imaging ``algorithm``is specified as ``cairi``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): The factor that will be applied to the heuristic noise level. The default value is ``1.0``.
        - ``dnnShelfPath``: The path of the ``.csv`` file that defines a shelf of denoisers. The ``.csv`` file has two columns. The first column is the training noise level of a denoiser and the second column is the path to the denoiser. The denoiser should be in ``.onnx`` format. Two sample ``.csv`` files are provided in ``$AIRI/airi_denoisers``.
        - ``imPeakEst``(optional): The estimated maximum intensity of the reconstructions. If this field is empty, the default value is the maximum intensity of the back-projected (dirty) image normalised by the peak value of the PSF.
        - ``dnnAdaptivePeak``(optional): Enable the adaptive denoiser selection scheme or not. The details of this scheme can be found in [[1]](https://arxiv.org/abs/2312.07137v2). The default value is true.
        - ``dnnApplyTransform``(optional): Apply random rotation and flipping before denoising and undo the transform after denoising or not. The default value is true.
        - ``imMinItr``(optional): The minimum number of iterations of the algorithm. The default value is ``200``.
        - ``imMaxItr``(optional): The minimum number of iterations of the algorithm. The default value is ``2000``.
        - ``imVarTol``(optional): The image variation tolerance of the algorithm. If the relative variation of the reconstructed images from two consecutive iterations is smaller than the value of ``imVarTol`` and the algorithm has run more iterations than ``imMinItr``, then the imaging process will be ended. The default value is ``1e-4``.
        - ``itrSave``(optional): The interval of iterations for saving intermediate results. The default number is ``500``.
        - ``dnnAdaptivePeakTolMax``(optional): The initial relative peak value variation tolerance for the adaptive denoiser selection scheme. The default value is ``0.1``.
        - ``dnnAdaptivePeakTolMin``(optional): The minimum relative peak value variation tolerance for the adaptive denoiser selection scheme. The default value is ``1e-3``.
        - ``dnnAdaptivePeakTolStep``(optional): The decaying factor for the relative peak value variation tolerance in the adaptive denoiser selection scheme. It will be applied to the current tolerance after one time of denoiser reselection. The default value is ``0.1``.

    - ``cpnp_bm3d`` and ``cpnp_bm3d_default``

        If the imaging ``algorithm``is specified as ``cpnp-bm3d``, then the fields in the section will be loaded.
        - ``heuNoiseScale``(optional): The factor that will be applied to the heuristic noise level. The default value is ``1.0``.
        - ``dirBM3DLib``(optional): The path of the BM3D MATLAB library. The default path is ``$AIRI/lib/bm3d``.
        - ``imMinItr``(optional): The minimum number of iterations of the algorithm. The default value is ``200``.
        - ``imMaxItr``(optional): The minimum number of iterations of the algorithm. The default value is ``2000``.
        - ``imVarTol``(optional): The image variation tolerance of the algorithm. If the relative variation of the reconstructed images from two consecutive iterations is smaller than the value of ``imVarTol`` and the algorithm has run more iterations than ``imMinItr``, then the imaging process will be ended. The default value is ``1e-4``.
        - ``itrSave``(optional): The interval of iterations for saving intermediate results. The default number is ``500``.

    

    