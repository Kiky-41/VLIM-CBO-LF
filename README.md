# VLIM-CBO-LF

**Enhanced generator scheduling through the lambda iteration method with clone-based optimization and Lévy flight integration**

Ikhsan, Rifki Rahman Nur · Raharjo, Jangkung · Ramadhan, Ardiansyah · Yustika, Lindiasari Martha  
*Clean Energy Science and Technology, 4(3), 735, 2026*  
[![DOI](https://img.shields.io/badge/DOI-10.18686%2Fcest735-blue)](https://doi.org/10.18686/cest735)

Vectorized Lambda Iteration Method with Clone-Based Optimization and Lévy flight for 42-unit, 24-hour economic dispatch.

## Abstract

One of the hardest parts of running a power system is economic dispatch (ED), which means finding the cheapest way to meet demand and operational limits. To alleviate these limitations, this study presents a hybrid methodology known as Vectorized Lambda Iteration Method–Clone-Based Optimization with Lévy flight (VLIM-CBO-LF). The contribution comprises the synchronized amalgamation of three complementary strategies. The VLIM-CBO-LF improves the accuracy of dispatch calculations, clone-based optimization improves local search by using adaptive cloning, selection, and Lévy flight improves global exploration by letting movements happen over long distances from time to time. The suggested method was tested on a 42-unit economic dispatch system over a 24-h period, running it 30 times to make sure it worked each time. The results show that VLIM-CBO-LF has the lowest average daily fuel cost of IDR 3.9096 × 1010. This is better than the artificial bee colony, particle swarm optimization, grey wolf optimization, and whale optimization algorithm. The cost goes down from IDR 1.050 × 10⁹ to 3.666 × 10⁹ per day, but the performance stays the same, with a standard deviation of 6.50 × 10⁷ IDR. The ANOVA test (F = 19.004, p = 1.820 × 10⁻⁷) and the Friedman test (χ2 = 60, p = 9.358 × 10⁻14) both show that the results are statistically significant. The Wilcoxon signed-rank test (W⁺ = 0) shows that the results are strictly better than all other benchmark methods. Future research may investigate the applicability of the VLIM-CBO-LF model to more complex electrical market mechanisms.


## Proposed method

VLIM-CBO-LF keeps the vectorised lambda iteration as its dispatch engine and adds a metaheuristic layer over the cost coefficients. Clones of $(a_i,b_i,c_i)$ are generated with Gaussian noise (CBO) or with Lévy-flight steps (LF); each clone is dispatched by VLIM, and the clone set with the lowest total cost replaces the incumbent. The metaheuristic therefore searches the coefficient space while the inner solver keeps the fast, exact balance correction.

### Objective and constraints

$$\min F=\sum_{t=1}^{T}\sum_{i=1}^{N}\left(a_i+b_iP_{i,t}+c_iP_{i,t}^2\right)$$

$$\sum_iP_{i,t}=P_{D,t},\qquad P_i^{\min}\le P_{i,t}\le P_i^{\max},\qquad -R_i^{D}\le P_{i,t}-P_{i,t-1}\le R_i^{U}.$$

### Notation

| Symbol | Meaning | Unit |
|---|---|---|
| $N$ | number of units | – |
| $T$ | number of hours | – |
| $P_{i,t}$ | output of unit $i$ at hour $t$ | MW |
| $a_i,b_i,c_i$ | cost coefficients | – |
| $P_{D,t}$ | demand at hour $t$ | MW |
| $\lambda$ | incremental cost | – |
| $\varepsilon_{a,i},\varepsilon_{b,i},\varepsilon_{c,i}$ | Gaussian coefficient perturbations | – |
| $\sigma^2$ | Gaussian variance | – |
| $\beta$ | Lévy stability parameter | – |
| $\sigma$ | Lévy scale factor | – |
| $u,v$ | Lévy numerator and denominator draws | – |
| $R_i^{U},R_i^{D}$ | ramp limits | MW/h |

### VLIM core

For a trial multiplier the dispatch and correction are

$$\mathbf{P}_t(\lambda)=\mathrm{clip}\left(\frac{\lambda\mathbf{1}-\mathbf{b}}{2\mathbf{c}},\mathbf{P}^{\min},\mathbf{P}^{\max}\right),\qquad
\lambda\leftarrow\lambda+\frac{P_{D,t}-\sum_iP_{i,t}}{\sum_i\frac{1}{2c_i}}.$$

The correction is the exact linearisation of the balance equation, as in VLIM. The ramp projection is applied after the dispatch:

$$\mathbf{P}_t\leftarrow\mathbf{P}_{t-1}+\mathrm{clip}\left(\mathbf{P}_t-\mathbf{P}_{t-1},-\mathbf{R}^{D},\mathbf{R}^{U}\right).$$

### Clone-based optimisation

Each coefficient is copied with small Gaussian noise:

$$a_i^{\text{clone}}=a_i+\varepsilon_{a,i},\qquad b_i^{\text{clone}}=b_i+\varepsilon_{b,i},\qquad c_i^{\text{clone}}=c_i+\varepsilon_{c,i},\qquad \varepsilon_{\cdot,i}\sim\mathcal{N}(0,\sigma^2),\quad \sigma^2=0.01.$$

The best clone (lowest 24-hour cost) is kept and the rest are discarded. Repeating the process moves the coefficient vector toward lower-cost dispatches while the VLIM solver guarantees a feasible schedule for every clone.

### Lévy-flight clone

Lévy flights add heavy-tailed steps, so the search occasionally makes a long jump instead of a small Gaussian move. The scale follows

$$\sigma=\left(\frac{\Gamma(1+\beta)\sin\left(\frac{\pi\beta}{2}\right)}{\Gamma\left(\frac{1+\beta}{2}\right)\beta~2^{\frac{\beta-1}{2}}}\right)^{\frac{1}{\beta}},\qquad \text{step}=\frac{u}{|v|^{1/\beta}},\qquad u\sim\mathcal{N}(0,\sigma^2),~v\sim\mathcal{N}(0,1),$$

and the clone is

$$a_i^{\text{clone}}=a_i+0.1~\text{step},\qquad b_i^{\text{clone}}=b_i+0.1~\text{step},\qquad c_i^{\text{clone}}=c_i+0.1~\text{step},$$

with stability parameter $\beta=1.5$. A clone is accepted only if it lowers the 24-hour cost.

### Reported result

42-unit, 24-hour Jamali dispatch, 30 independent runs: IDR $3.9096\times10^{10}$, the lowest cost among ABC, GWO, PSO, WOA and the two ablation variants VLIM and VLIM-CBO.

### Implementation note

The paper writes the Gaussian clone of $b_i$ with $\varepsilon_{a,i}$ in its equation; the implementation and the description above use the matching component $\varepsilon_{b,i}$. This is a typographical inconsistency in the manuscript, not a change of method.

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


## Results

| Metric | Value |
|---|---|
| Test case | 42-unit Jamali, 24 hours |
| Best cost | IDR $3.9096\times10^{10}$ |
| Independent runs | 30 |
| Baselines | ABC, GWO, PSO, WOA, VLIM, VLIM-CBO |
| Levy exponent | $\beta=1.5$ |
| Result file | [`results/1 Kompilasi Data.xlsx`](results/1 Kompilasi Data.xlsx) |
| Result file | [`results/2 Kompilasi Data.xlsx`](results/2 Kompilasi Data.xlsx) |
| Result file | [`results/Comparative_ED_Statistical_Results_Fixed.xlsx`](results/Comparative_ED_Statistical_Results_Fixed.xlsx) |
| Result file | [`results/variants/Statistical_Analysis_VLIM_Variants.xlsx`](results/variants/Statistical_Analysis_VLIM_Variants.xlsx) |
| Result file | [`results/variants/SummaryVLIMVariant.xlsx`](results/variants/SummaryVLIMVariant.xlsx) |


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
