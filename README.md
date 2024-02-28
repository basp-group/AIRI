# AIRI: "AI for Regularisation in Imaging" plug-and-play algorithms for computational imaging
![language](https://img.shields.io/badge/language-MATLAB-orange.svg)
[![license](https://img.shields.io/badge/license-GPL--3.0-brightgreen.svg)](LICENSE)

- [AIRI: "AI for Regularisation in Imaging" plug-and-play algorithms for computational imaging](#airi-ai-for-regularisation-in-imaging-plug-and-play-algorithms-for-computational-imaging)
  - [Description](#description)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Cloning the project](#cloning-the-project)
    - [Updating submodules (optional)](#updating-submodules-optional)
    - [Add BM3D Library](#add-bm3d-library)
    - [Add pretrained AIRI denoisers](#add-pretrained-airi-denoisers)
  - [Input Files](#input-files)
    - [Measurement file](#measurement-file)
    - [Configuration file](#configuration-parameter-file)
  - [Examples](#examples)

## Description

``AIRI`` and its constraint variant ``cAIRI`` are Plug-and-Play (PnP) algorithms used to solve the inverse imaging problem. By inserting carefully trained AIRI denoisers into the proximal splitting algorithms, one waives the computational complexity of optimisation algorithms induced by sophisticated image priors, and the sub-optimality of handcrafted priors compared to Deep Neural Networks. This repository provides a straightforward MATLAB implementation for the algorithms ``AIRI`` and ``cAIRI`` to solve small scale monochromatic astronomical imaging problem. Additionally, it also contains the implementation of unconstrained PnP and constrained PnP with the [BM3D](https://webpages.tuni.fi/foi/GCF-BM3D/index.html) denoiser as a regularizer. The details of these algorithms are discussed in the following papers.

>[1] Terris, M., Tang, C., Jackson, A., & Wiaux, Y. (2023). [Plug-and-play imaging with model uncertainty quantification in radio astronomy](https://arxiv.org/abs/2312.07137v2). *arXiv preprint arXiv:2312.07137.* 
>
>[2] Terris, M., Dabbech, A., Tang, C., & Wiaux, Y. (2023). [Image reconstruction algorithms in radio interferometry: From handcrafted to learned regularization denoisers](https://doi.org/10.1093/mnras/stac2672). *MNRAS, 518*(1), 604-622.

## Dependencies 

This repository relies on two auxiliary submodules :

1. [`RI-measurement-operator`](https://github.com/basp-group/RI-measurement-operator) for the formation of the radio-interferometric measurement operator [3,4,5];
2. [`BM3D`](https://webpages.tuni.fi/foi/GCF-BM3D/index.html) for the implementation of the Block-matching and 3D filtering (BM3D) algorithm [6].

These modules contain codes associated with the following publications

>[3] Dabbech, A., Wolz, L., Pratley, L., McEwen, J. D., & Wiaux, Y. (2017). [The w-effect in interferometric imaging: from a fast sparse measurement operator to superresolution](http://dx.doi.org/10.1093/mnras/stx1775). *MNRAS, 471*(4), 4300-4313.
>
>[4] Fessler, J. A., & Sutton, B. P. (2003). Nonuniform fast Fourier transforms using min-max interpolation. *IEEE TSP, 51*(2), 560-574.
>
>[5] Onose, A., Dabbech, A., & Wiaux, Y. (2017). [An accelerated splitting algorithm for radio-interferometric imaging: when natural and uniform weighting meet](http://dx.doi.org/10.1093/mnras/stx755). *MNRAS, 469*(1), 938-949.
> 
>[6] Mäkinen, Y., Azzari, L., & Foi, A. (2020). [Collaborative filtering of correlated noise: Exact transform-domain variance for improved shrinkage and patch matching](https://doi.org/10.1109/TIP.2020.3014721). *IEEE TIP, 29*, 8339-8354.

## Installation

### Cloning the project

To clone the project with the required submodules, you may consider one of the following set of instructions.

- Cloning the project using `https`:  you should run the following command
```bash
git clone --recurse-submodules https://github.com/basp-group/AIRI.git
```
- Cloning the project using SSH key for GitHub: you should first edit the `.gitmodules` file, replacing the `https` addresses with the `git@github.com` counterpart as follows: 

```bash
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
```

You can then clone the repository with all the submodules as follows:

```bash
git clone --recurse-submodules git@github.com:basp-group/AIRI.git
```

### Updating submodules (optional)

To update the submodules from your local `AIRI` repository, run the follwing commands: 

```bash
git pull
git submodule sync --recursive # update submodule address, in case the url has changed
git submodule update --init --recursive # update the content of the submodules
git submodule update --remote --merge # fetch and merge latest state of the submodule
```

### BM3D Library
The [BM3D](https://webpages.tuni.fi/foi/GCF-BM3D/index.html) MATLAB library v.3.0.9 can be downloaded from its webpage or directly using [this link](https://webpages.tuni.fi/foi/GCF-BM3D/bm3d_matlab_package_3.0.9.zip). After unpacking the downloaded zip file, the folder ``bm3d`` inside the folder should be copied in  ``./lib/`` folder of this repository.

If you are working on macOS, you may need to run the following commands to remove the system restrictions on MATLAB executable files in the BM3D library.

```bash
# go to the folder of the bm3d library
cd ./lib/bm3d

# remove files from quarantine list
xattr -d com.apple.quarantine bm3d_wiener_colored_noise.mexmaci64
xattr -d com.apple.quarantine bm3d_thr_colored_noise.mexmaci64

# add files to the macOS Gatekeeper exception
spctl --add bm3d_wiener_colored_noise.mexmaci64
spctl --add bm3d_thr_colored_noise.mexmaci64
```

###  Pretrained AIRI denoisers
If you'd like to use our trained AIRI denoisers, you can download the ONNX files from this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/o1aerlgeis93r7f9d0qms/h?rlkey=a6t7qcz19hklsfh1ndi8sgb50&dl=0). You should copy the folders ``shelf_oaid`` and ``shelf_mrid`` in ``./airi_denoisers/`` folder of this repository. Alternatively, make sure to update the full paths to the DDNs in the `.csv` file of the denoiser shelf.

## Input Files
### Measurement file
The current code takes as input data a measurement file in ``.mat`` format containing the following fields:

```matlab
"frequency"       % scalar, observation frequency                       
"y"               % vector, measurements/data (Stokes I)
"u"               % vector, u coordinate (in units of the wavelength)
"v"               % vector, v coordinate (in units of the wavelength)
"w"               % vector, w coordinate (in units of the wavelength)                       
"nW"              % vector, inverse of the standard deviation
"nWimag"          % vector, sqrt of the imaging weights if available (Briggs or uniform), empty otherwise
"maxProjBaseline" % scalar, maximum projected baseline (in units of the wavelength; formally  max(sqrt(u.^2+v.^2)))
```

Instructions to extract a single-channel measurment file from a Measurement Set are provided in the [Readme File](https://github.com/basp-group/AIRI/blob/main/pyxisMs2mat/README.md).
Note that the measurement file is of the same format as the input expected in the library [Faceted Hypersara](https://github.com/basp-group/Faceted-HyperSARA) for wideband imaging.

### Configuration (parameter) file
The configuration file is a ``.json`` format file comprising all parameters to run the different algorithms. A template file is provided in `./config/`. 

## Examples
The scripts that used to generate the reconstructions shown in Figure 3.(g)-(i) in [1] can be found in the folder ``examples``. To launch these tests, please download the simulated measurements from this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/et0o4jl0d9twskrshdd7j/h?rlkey=gyl3fj3y7ca1tmoa1gav71kgg&dl=0) and move the folder ``simulated_measurements`` folder inside ``./examples``. Then change your current directory to ``./examples`` and launch the MATLAB scripts inside the folder. The results will be saved in the folder ``./results/3c353_dt8_seed0``. The groundtruth images of these measurements can be found in this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/mct058u0ww9301vrsgeqj/h?rlkey=hz8py389nay5jmqgzxz4knqja&dl=0).
