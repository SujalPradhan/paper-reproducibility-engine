# Report card: Evidence for a male-biased sex ratio in the offspring of a large herbivore: The role of environmental conditions in the sex ratio variation

- DOI: https://doi.org/10.1002/ece3.8938
- Journal: Ecology and Evolution
- **Overall verdict: Partial**
- Verdicts are computed by `scripts/compare.py` against tolerances frozen in `claims.json` before reproduction.

| Claim | Paper says | We got | Difference | Tolerance | Verdict | Notes |
|---|---|---|---|---|---|---|
| C1: Number of tagged roe deer fawns with known sex in Baden-Württemberg, 1972–2019 (Abstract; Methods 2.1 ('For 3280 of 12,437 marked fawns'); Table 1 caption; Figure 1 caption. Conflicts with Table 2 row ref 47 and Table 3 row ID 90 (12473, '12,473') and with Metafor_roe_sex.csv Hagen row (N = 12475)) | N = 12,437 | 12435.00 | -2.00 | ±0.5 | Partial | Rows with Sex in {f,m} and Year 1972-2019 (stated exclusions only). Hasl-NA rows kept; N excluding Hasl-NA = 11793. Raw file rows = 17260. |
| C2: Proportion of female offspring among tagged fawns in Baden-Württemberg is below parity (male-biased), 95% CI from exact binomial test (Table 2, row reference 47 'Hagen et al., this publication'; also Table 3 row ID 90) | 0.48 [0.47, 0.49] | 0.4778 | -0.0022 | ±0.005 | Reproduced | pf = 5941/12435; exact Clopper-Pearson 95% CI [0.4690, 0.4866] (binom.test); p vs 0.5. Without Hasl-NA rows: pf = 0.4793 [0.4702, 0.4883], n = 11793. |
| C3: Overall effect size d for the prenatal sex ratio (random-effects model, data-set level) is negative, i.e. male-biased (Results 3.2, paragraph after Table 3 (and Figure 3 / Appendix Figure S1)) | −0.06 (CI95 [−0.09, −0.02]) | -0.0503 | 0.0097 | ±0.005 | Partial | metafor rma REML on 37 prenatal rows (paper says 36); tau2 = 0.00137, I2 = 13.59%. |
| C4: Overall effect size d for the secondary sex ratio (random-effects model, data-set level) is negative, i.e. male-biased (Results 3.2, paragraph after Table 3 (and Figure 3). The fixed model at reference level gives the identical −0.04 [−0.06, −0.03]) | −0.04 (CI95 [−0.06, −0.03] | -0.0376 | 0.0024 | ±0.005 | Reproduced | metafor rma REML on 15 secondary rows; tau2 = 0.00000, I2 = 0.01%. |
| C5: Mean temperature Oct(t−1)–Feb(t) (linear term) is associated with offspring sex in the binomial GLM (Equation 2) (Table 1, row 'Temperature (Oct–Feb)') | 0.019 | 0.01351 | -0.00549 | ±0.0005 | Not reproduced | glm binomial logit, n = 11793 (Hasl-NA dropped); T_cor = mean(Oct-Dec t-1, Jan-Feb t) - 0.65*Hasl/100; P_Sep raw mm. Uncorrected-T sensitivity: -0.0041 (SE 0.0904, p 0.964). |
| C6: Quadratic term of mean temperature Oct(t−1)–Feb(t) is positive and significant: relatively cold or warm autumn/winters deviate from the male-biased mean (U-shaped) (Table 1, row 'Temperature (Oct–Feb)2' (SE printed as '0')) | 0.001 | 0.00864 | 0.00764 | ±0.0005 | Not reproduced | Quadratic T_cor term, same model as C5. Uncorrected-T sensitivity: -0.00113 (SE 0.01472, p 0.939). |
