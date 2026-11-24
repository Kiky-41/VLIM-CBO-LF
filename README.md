# VLIM-CBO-LF

**Enhanced generator scheduling through the lambda iteration method with clone-based optimization and Lévy flight integration**

Ikhsan, Rifki Rahman Nur · Raharjo, Jangkung · Ramadhan, Ardiansyah · Yustika, Lindiasari Martha  
*Clean Energy Science and Technology, 4(3), 735, 2026*  
[![DOI](https://img.shields.io/badge/DOI-10.18686%2Fcest735-blue)](https://doi.org/10.18686/cest735)

Vectorized Lambda Iteration Method with Clone-Based Optimization and Lévy flight for 42-unit, 24-hour economic dispatch.

## Abstract

One of the hardest parts of running a power system is economic dispatch (ED), which means finding the cheapest way to meet demand and operational limits. To alleviate these limitations, this study presents a hybrid methodology known as Vectorized Lambda Iteration Method–Clone-Based Optimization with Lévy flight (VLIM-CBO-LF). The contribution comprises the synchronized amalgamation of three complementary strategies. The VLIM-CBO-LF improves the accuracy of dispatch calculations, clone-based optimization improves local search by using adaptive cloning, selection, and Lévy flight improves global exploration by letting movements happen over long distances from time to time. The suggested method was tested on a 42-unit economic dispatch system over a 24-h period, running it 30 times to make sure it worked each time. The results show that VLIM-CBO-LF has the lowest average daily fuel cost of IDR 3.9096 × 1010. This is better than the artificial bee colony, particle swarm optimization, grey wolf optimization, and whale optimization algorithm. The cost goes down from IDR 1.050 × 10⁹ to 3.666 × 10⁹ per day, but the performance stays the same, with a standard deviation of 6.50 × 10⁷ IDR. The ANOVA test (F = 19.004, p = 1.820 × 10⁻⁷) and the Friedman test (χ2 = 60, p = 9.358 × 10⁻14) both show that the results are statistically significant. The Wilcoxon signed-rank test (W⁺ = 0) shows that the results are strictly better than all other benchmark methods. Future research may investigate the applicability of the VLIM-CBO-LF model to more complex electrical market mechanisms.

## Contents

```
.gitignore
figures/
  BoxWhisker_VLIM_Variants.png
  Convergence_Comparison_Fixed.png
  DailyCost_BoxWhisker_Fixed.png
  MeanCI_VLIM_Variants.png
  MeanDailyCost_ErrorBar_Fixed.png
  Scatter_VLIM_Variants.png
  Sensitivity_Beta.png
  Sensitivity_Candidates.png
  Sensitivity_Scale.png
matlab/
  VLIMCBOLF.m
  VLIM_variants.m
  stats_compilation.m
  stats_enhancement.m
python/
  ABC (ED).ipynb
  GWO (ED).ipynb
  IH.ipynb
  PSO (ED).ipynb
  VLIM-CBO-LF.ipynb
  VLIM-CBO.ipynb
  VLIM.ipynb
  WOA (ED).ipynb
results/
  1 Kompilasi Data.xlsx
  2 Kompilasi Data.xlsx
  Comparative_ED_Statistical_Results_Fixed.xlsx
  variants/
```

## Data

Input data is **not included**. Place files in `data/` (notebooks) or next to the `.m` script (MATLAB):

| File | Columns |
|---|---|
| `input42u.xlsx` | Sheet1: `Unit`, `a`, `b`, `c`, `pmin`, `pmax`, `rampup`, `rampdown`, `load` |
| `power_demand42u.xlsx` | Sheet1: `load` |

## Requirements

MATLAB, Python. Python notebooks: `numpy`, `pandas`, `scipy`, `matplotlib` (as imported). MATLAB scripts: R2021a+.

## Citation

```bibtex
@article{Ikhsan_2026, title={Enhanced generator scheduling through the lambda iteration method with clone-based optimization and Lévy flight integration}, ISSN={2972-4910}, url={http://dx.doi.org/10.18686/cest735}, DOI={10.18686/cest735}, journal={Clean Energy Science and Technology}, publisher={Universe Scientific Publishing Pte. Ltd.}, author={Ikhsan, Rifki Rahman Nur and Raharjo, Jangkung and Ramadhan, Ardiansyah and Yustika, Lindiasari Martha}, year={2026}, month=June }
```

## License

[![CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](LICENSE)

Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). **Attribution is required**: any use of this code, results, or figures, including in publications, must cite:

> Rifki Rahman Nur Ikhsan; Jangkung Raharjo; Ardiansyah Ramadhan; Lindiasari Martha Yustika (2026). Enhanced generator scheduling through the lambda iteration method with clone-based optimization and Lévy flight integration. *Clean Energy Science and Technology*. https://doi.org/10.18686/cest735
