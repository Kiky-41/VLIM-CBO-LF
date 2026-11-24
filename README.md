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

### 42-unit, 24 hours, 30 runs

| Method | Mean cost (IDR) | Std | Best | Worst | Mean time (s) |
|---|---|---|---|---|---|
| VLIM-CBO-LF | 39,095,869,249.07 | 64,964,165.83 | 38,914,737,218.56 | 39,214,724,516.36 | 0.000014 |
| ABC | 40,145,416,005.95 | 137,671,090.99 | 39,808,214,131.80 | 40,444,974,975.42 | 0.000071 |
| GWO | 40,350,269,863.13 | 185,297,532.94 | 39,810,900,845.61 | 40,693,934,961.34 | 0.000068 |
| PSO | 40,262,058,762.16 | 443,289,771.31 | 39,695,802,167.05 | 41,160,731,985.55 | 0.000066 |
| WOA | 42,761,376,083.84 | 971,992,386.25 | 41,092,311,786.81 | 44,660,103,807.98 | 0.000066 |

VLIM-CBO-LF averages 39.10 billion IDR per day, 2.61% under ABC, 2.90% under PSO and 8.57% under WOA, and its worst run (39.21 billion) still beats the best run of every baseline. Mean solve time is 14 microseconds, 4.7 times faster than the baselines at 66 to 71 microseconds.

### Omnibus tests, 42-unit, 24 hours, 30 runs

| Test | p-value |
|---|---|
| ANOVA (between/within methods) | 1.82e-61 |
| Friedman | 1.29e-20 |
| Friedman, statistic | 0.00 |

ANOVA returns p 1.82e-61 and the Friedman test chi-square 60 with p 1.29e-20, so the five methods do not share a common mean or median over the 30 runs.

### Tukey HSD, all pairs

| Comparison | VLIM_CBO_LF vs ABC | VLIM_CBO_LF vs GWO | VLIM_CBO_LF vs PSO | VLIM_CBO_LF vs WOA | ABC vs GWO | ABC vs PSO | ABC vs WOA | GWO vs PSO | GWO vs WOA | PSO vs WOA |
|---|---|---|---|---|---|---|---|---|---|---|
| Mean difference (IDR) | -1,049,546,756.87 | -1,254,400,614.05 | -1,166,189,513.09 | -3,665,506,834.77 | -204,853,857.18 | -116,642,756.22 | -2,615,960,077.90 | 88,211,100.96 | -2,411,106,220.72 | -2,499,317,321.68 |
| 95% CI | -1,394,411,072.15 to -704,682,441.59 | -1,599,264,929.33 to -909,536,298.77 | -1,511,053,828.37 to -821,325,197.81 | -4,010,371,150.05 to -3,320,642,519.49 | -549,718,172.46 to 140,010,458.10 | -461,507,071.50 to 228,221,559.06 | -2,960,824,393.18 to -2,271,095,762.62 | -256,653,214.32 to 433,075,416.25 | -2,755,970,536.00 to -2,066,241,905.44 | -2,844,181,636.96 to -2,154,453,006.40 |
| p | 4.60e-16 | 0.0 | 4.04e-20 | 0.0 | 4.84e-01 | 8.88e-01 | 0.0 | 9.57e-01 | 0.0 | 0.0 |

VLIM-CBO-LF is separated from all four baselines, with p from 4.6e-16 against ABC down to 0.0 against GWO and WOA. ABC, GWO and PSO are tied among themselves (p 0.48 to 0.96), so the hybrid is the only method outside that block, and WOA sits below all of them.

### Friedman post-hoc, mean rank differences

| Comparison | VLIM_CBO_LF vs ABC | VLIM_CBO_LF vs GWO | VLIM_CBO_LF vs PSO | VLIM_CBO_LF vs WOA | ABC vs GWO | ABC vs PSO | ABC vs WOA | GWO vs PSO | GWO vs WOA | PSO vs WOA |
|---|---|---|---|---|---|---|---|---|---|---|
| Rank difference | -1.733 | -2.433 | -1.833 | -4.000 | -0.700 | -0.100 | -2.267 | 0.600 | -1.567 | -2.167 |
| 95% CI | -2.85 to -0.62 | -3.55 to -1.32 | -2.95 to -0.72 | -5.11 to -2.89 | -1.81 to 0.41 | -1.21 to 1.01 | -3.38 to -1.15 | -0.51 to 1.71 | -2.68 to -0.45 | -3.28 to -1.05 |
| p | 2.11e-04 | 2.47e-08 | 6.95e-05 | 5.18e-23 | 4.25e-01 | 9.99e-01 | 2.80e-07 | 5.82e-01 | 1.17e-03 | 1.11e-06 |

On ranks the hybrid is 1.73 places ahead of ABC (p 2.1e-4), 2.43 ahead of GWO (p 2.5e-8), 1.83 ahead of PSO (p 7.0e-5) and 4.00 ahead of WOA (p 5.2e-23). The three middle baselines are again indistinguishable (p 0.42 to 1.00).

### Paired t-test against baselines

| Comparison | t statistic | p | Mean difference (IDR) | 95% CI |
|---|---|---|---|---|
| VLIM_CBO_LF vs ABC | -38.39 | 2.05e-26 | -1,049,546,756.87 | -1,105,464,624.25 to -993,628,889.49 |
| VLIM_CBO_LF vs GWO | -35.37 | 2.10e-25 | -1,254,400,614.05 | -1,326,937,897.26 to -1,181,863,330.84 |
| VLIM_CBO_LF vs PSO | -14.80 | 4.77e-15 | -1,166,189,513.09 | -1,327,371,465.06 to -1,005,007,561.11 |
| VLIM_CBO_LF vs WOA | -20.82 | 5.49e-19 | -3,665,506,834.77 | -4,025,540,588.50 to -3,305,473,081.03 |

All four paired t-tests reject equality with t statistics from minus 14.8 to minus 38.4 and confidence intervals that stay below zero, so the hybrid is cheaper than every baseline run by run, not only on average.

### Paired Wilcoxon against baselines

| Baseline | Signed-rank statistic | p | Mean difference (IDR) | Median difference (IDR) |
|---|---|---|---|---|
| ABC | 0.0 | 1.73e-06 | -1,049,546,756.87 | -1,061,806,149.15 |
| GWO | 0.0 | 1.73e-06 | -1,254,400,614.05 | -1,260,259,829.01 |
| PSO | 0.0 | 1.73e-06 | -1,166,189,513.09 | -1,043,388,030.67 |
| WOA | 0.0 | 1.73e-06 | -3,665,506,834.77 | -3,622,397,595.03 |

Every paired comparison is significant at p 1.73e-6 with a negative mean difference, meaning VLIM-CBO-LF is cheaper than each baseline in the paired run. The gap is smallest against ABC (1.05 billion IDR per day) and largest against WOA (3.67 billion).

### Mean rank across 30 runs

| Method | VLIM-CBO-LF | ABC | PSO | GWO | WOA |
|---|---|---|---|---|---|
| Rank | 1 | 2 | 3 | 4 | 5 |

The average ranks order the methods VLIM-CBO-LF, ABC, PSO, GWO and WOA, the same order as the mean daily cost.

### Sensitivity, beta, 30 runs per setting

| beta | Mean cost (IDR) | Std | Best | Worst |
|---|---|---|---|---|
| 1.1 | 39,962,951,504.10 | 183,964,109.39 | 39,555,104,854.91 | 40,160,715,272.21 |
| 1.3 | 39,461,731,164.16 | 133,652,059.26 | 39,174,603,161.96 | 39,589,886,006.21 |
| 1.5 | 39,096,765,403.77 | 86,107,705.70 | 38,914,737,218.56 | 39,172,418,490.29 |
| 1.7 | 38,795,501,587.25 | 55,162,073.65 | 38,684,770,316.59 | 38,851,266,532.37 |
| 1.9 | 38,471,487,732.03 | 25,932,176.72 | 38,420,201,803.33 | 38,501,668,239.78 |

Mean cost falls monotonically as beta rises, from 39.96 billion at 1.1 to 38.47 billion at 1.9, and the spread shrinks with it (std 184.0 million down to 25.9 million). The default 1.5 sits mid-range at 39.10 billion.

### Sensitivity, levyScaleRatio, 30 runs per setting

| levyScaleRatio | Mean cost (IDR) | Std | Best | Worst |
|---|---|---|---|---|
| 0.02 | 38,330,951,661.62 | 21,500,824.04 | 38,286,200,527.11 | 38,351,705,914.37 |
| 0.05 | 38,714,464,047.03 | 56,504,229.34 | 38,597,909,826.99 | 38,770,418,617.82 |
| 0.08 | 39,096,765,403.77 | 86,107,705.70 | 38,914,737,218.56 | 39,172,418,490.29 |
| 0.1 | 39,349,809,743.43 | 104,325,270.31 | 39,128,362,002.10 | 39,451,485,986.66 |
| 0.15 | 39,981,013,234.86 | 146,503,060.76 | 39,672,215,970.04 | 40,132,402,303.43 |

Levy step size matters more than beta below 0.10: 0.02 gives the cheapest run at 38.33 billion, 0.08 is the default at 39.10 billion, and 0.15 costs 39.98 billion. Small steps pay here because the local search carries the refinement.

### Sensitivity, numCandidates, 30 runs per setting

| numCandidates | Mean cost (IDR) | Std | Best | Worst |
|---|---|---|---|---|
| 20.0 | 39,129,966,176.55 | 91,940,663.97 | 38,914,737,218.56 | 39,259,297,375.23 |
| 30.0 | 39,108,659,219.12 | 77,595,463.02 | 38,914,737,218.56 | 39,172,418,490.29 |
| 50.0 | 39,096,765,403.77 | 86,107,705.70 | 38,914,737,218.56 | 39,172,418,490.29 |
| 70.0 | 39,063,853,168.30 | 78,507,261.28 | 38,914,737,218.56 | 39,172,418,490.29 |
| 100.0 | 39,051,486,966.75 | 67,940,339.06 | 38,914,737,218.56 | 39,121,888,086.63 |

Candidate count barely moves the mean, 39.13 billion at 20 up to 39.05 billion at 100, while the worst run tightens from 39.26 to 39.12 billion. Above 50 candidates the gain is under 0.1%, which sets the practical ceiling.

### Variants, 30 runs

| Variant | Mean cost (IDR) | Std | Best | Worst |
|---|---|---|---|---|
| VLIM | 36,250,005,749.63 | 8.80 | 36,250,005,735.13 | 36,250,005,764.13 |
| VLIM-CBO | 36,250,003,698.64 | 628.56 | 36,250,002,164.29 | 36,250,004,593.21 |
| VLIM-CBO-LF | 36,249,990,313.58 | 18,232.14 | 36,249,911,691.94 | 36,250,002,274.72 |

The three variants land within 15,436 IDR of each other, or 0.00004% of the daily cost, with VLIM-CBO-LF lowest at 36,249,990,314 IDR. Its spread is larger than the other two (std 18,232 against 629 and 8.8), so the gain is in the best run rather than in stability.

### Variant tests, omnibus ANOVA p 1.42e-07, Friedman p 9.36e-14

| Comparison | VLIM vs VLIM-CBO | VLIM vs VLIM-CBO-LF | VLIM-CBO vs VLIM-CBO-LF | VLIM vs VLIM-CBO | VLIM vs VLIM-CBO-LF | VLIM-CBO vs VLIM-CBO-LF | VLIM-CBO-LF vs VLIM | VLIM-CBO-LF vs VLIM-CBO | VLIM vs VLIM-CBO-LF | VLIM-CBO vs VLIM-CBO-LF |
|---|---|---|---|---|---|---|---|---|---|---|
| Test | Tukey HSD | Tukey HSD | Tukey HSD | Friedman post-hoc | Friedman post-hoc | Friedman post-hoc | Paired t-test | Paired t-test | Wilcoxon | Wilcoxon |
| Difference | 2,050.99 | 15,436.05 | 13,385.06 | 1.000 | 2.000 | 1.000 | -15,436.05 | -13,385.06 | -15,436.05 | -13,385.06 |
| p | 7.32e-01 | 5.32e-07 | 1.20e-05 | 3.17e-04 | 2.26e-14 | 3.17e-04 | 6.95e-05 | 4.01e-04 | 1.73e-06 | 1.73e-06 |

ANOVA (F 19.00, p 1.42e-7) and Friedman (chi-square 60, p 9.36e-14) both reject equality across the three variants. Tukey separates VLIM-CBO-LF from VLIM (p 5.3e-7) and from VLIM-CBO (p 1.2e-5) but not VLIM from VLIM-CBO (p 0.73); paired t-tests and Wilcoxon agree for both pairs. Rank order is VLIM-CBO-LF, VLIM-CBO, VLIM.

### Result workbooks

Raw solver output: [`results/1 Kompilasi Data.xlsx`](results/1 Kompilasi Data.xlsx), [`results/2 Kompilasi Data.xlsx`](results/2 Kompilasi Data.xlsx), [`results/Comparative_ED_Statistical_Results_Fixed.xlsx`](results/Comparative_ED_Statistical_Results_Fixed.xlsx), [`results/variants/Statistical_Analysis_VLIM_Variants.xlsx`](results/variants/Statistical_Analysis_VLIM_Variants.xlsx), [`results/variants/SummaryVLIMVariant.xlsx`](results/variants/SummaryVLIMVariant.xlsx).

The workbooks hold the raw solver output behind the tables above: per-unit schedules, per-hour costs, constraint checks and run statistics.


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
