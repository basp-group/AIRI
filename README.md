# AIRI: "AI for Regularisation in Imaging" plug-and-play algorithms for computational imaging
![language](https://img.shields.io/badge/language-MATLAB-orange.svg)
[![license](https://img.shields.io/badge/license-GPL--3.0-brightgreen.svg)](LICENSE)

- [AIRI: "AI for Regularisation in Imaging" plug-and-play algorithms for computational imaging](#parallel-faceted-imaging-in-radio-interferometry-via-proximal-splitting)
  - [Description](#description)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Cloning the project](#cloning-the-project)
    - [Add BM3D Library](#add-bm3d-library)
    - [Add pretrained AIRI denoisers](#add-pretrained-airi-denoisers)

## Description

This repository provides a straightforward MATLAB implementation for the algorithm ``AIRI`` and its constrained variant ``cAIRI`` to solve small scale monochromatic astronomical image problem. ``AIRI`` and ``cAIRI`` are Plug-and-Play (PnP) algorithms used to solve the inverse imaging problem. By inserting carefully trained AIRI denoisers into the proximal splitting algorithms, one waives the one waives the computational complexity of optimisation algorithms induced by sophisticated image priors, and the sub-optimality of handcrafted priors compared to Deep Neural Networks. Additionally, it also contains the implementation of unconstrained PnP and constrained PnP with the [BM3D](https://webpages.tuni.fi/foi/GCF-BM3D/index.html) denoiser as regularizer. The details of these algorithms are discussed in the following papers.

>[1] Terris, M., Tang, C., Jackson, A., & Wiaux, Y. (2023). [Plug-and-play imaging with model uncertainty quantification in radio astronomy](https://arxiv.org/abs/2312.07137v2). *arXiv preprint arXiv:2312.07137.* 
>
>[2] Terris, M., Dabbech, A., Tang, C., & Wiaux, Y. (2023). [Image reconstruction algorithms in radio interferometry: From handcrafted to learned regularization denoisers](https://doi.org/10.1093/mnras/stac2672). *Monthly Notices of the Royal Astronomical Society, 518*(1), 604-622.

## Dependencies 

This repository relies on two auxiliary submodules :

1. [`RI-measurement-operator`](https://github.com/basp-group/RI-measurement-operator) for the formation of the radio-interferometric measurement operator;
2. [`BM3D`](https://webpages.tuni.fi/foi/GCF-BM3D/index.html) for the implementation of the Block-matching and 3D filtering (BM3D) algorithm.

These modules contain codes associated with the following publications

>[3] Dabbech, A., Wolz, L., Pratley, L., McEwen, J. D., & Wiaux, Y. (2017). [The w-effect in interferometric imaging: from a fast sparse measurement operator to superresolution](http://dx.doi.org/10.1093/mnras/stx1775). *Monthly Notices of the Royal Astronomical Society, 471*(4), 4300-4313.
>
>[4] Fessler, J. A., & Sutton, B. P. (2003). Nonuniform fast Fourier transforms using min-max interpolation. *IEEE transactions on signal processing, 51*(2), 560-574.
>
>[5] Onose, A., Dabbech, A., & Wiaux, Y. (2017). [An accelerated splitting algorithm for radio-interferometric imaging: when natural and uniform weighting meet](http://dx.doi.org/10.1093/mnras/stx755). *Monthly Notices of the Royal Astronomical Society, 469*(1), 938-949.
> 
>[6] Mäkinen, Y., Azzari, L., & Foi, A. (2020). [Collaborative filtering of correlated noise: Exact transform-domain variance for improved shrinkage and patch matching](https://doi.org/10.1109/TIP.2020.3014721). *IEEE Transactions on Image Processing, 29*, 8339-8354.

## Installation

To properly clone the project with the submodules, you may need to choose one of following set of instructions.

### Cloning the project

- If you plan to clone the project an SSH key for GitHub, you will first need to edit the `.gitmodules` file accordingly, replacing the `https` addresses with the `git@github.com` counterpart. That is

```bash
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
```

- Cloning the repository from scratch. If you used `https`, issue the following command

```bash
git clone --recurse-submodules https://github.com/basp-group/Faceted-HyperSARA.git
```

If you are using an SSH key for GitHub rather than a personal token, then you will need to clone the repository as follows instead:

```bash
git clone --recurse-submodules git@github.com:basp-group/Faceted-HyperSARA.git
```

You will then also need to update the local repository configuration to use this approach for the sub-modules and update the submodules separately as detailed below.

- Submodules update: updating from an existing `Faceted-HyperSARA` repository.

```bash
git pull
git submodule sync --recursive # update submodule address, in case the url has changed
git submodule update --init --recursive # update the content of the submodules
git submodule update --remote --merge # fetch and merge latest state of the submodule
```

### Add BM3D Library
The [BM3D]() MATLAB library v.3.0.9 can be found on its webpage or directly though [this link](https://webpages.tuni.fi/foi/GCF-BM3D/bm3d_matlab_package_3.0.9.zip). After unpacking the downloaded zip file, please copy the folder ``bm3d`` in the folder to the folder ``lib`` into this repository.

If you are working on macOS, you may need to run the following commands to remove the system restrictions on Matlab executable files in the BM3D library.

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

### Add pretrained AIRI denoisers
If you'd like to use our trained AIRI denoisers, you can download the ONNX files from this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/o1aerlgeis93r7f9d0qms/h?rlkey=a6t7qcz19hklsfh1ndi8sgb50&dl=0). Afterwards, please move the folder ``shelf_astro`` and ``shelf_bio`` to the folder ``airi_denoisers`` in the repository.