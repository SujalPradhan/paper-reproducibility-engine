# Independent audit: hsr-2023-ei-happiness

Auditor: independent of the reproduction. Date: 2026-10-20. Repo state audited: GitHub `main` at `7991e22`. `claims.json` is byte-identical to tag `claims-frozen-hsr-2023-ei-happiness`, and `code/reproduce.R` and `outputs/results.json` are byte-identical to the local copy.

## 1. Clean re-run

- Cloned https://github.com/SujalPradhan/paper-reproducibility-engine into the auditor scratchpad (`.../scratchpad/audit-hsr/`).
- Downloaded the data from the **original source** https://ndownloader.figshare.com/files/41052677 into `data/EI_and_Happiness_raw_Data_with_coding.sav` (the name the script expects).
- **Checksum:** SHA-256 `4eb2f96328154cf5f3b96c8572f9eb9f5fec664ceb40fa89fddb24ac333a6455` and 67,522 bytes, matching `data/README.md`. MD5 `3b96b17701cef8b656e5d754be268e13` matches Figshare's `computed_md5`.
- **Environment:** `env/rlib` is not in git, and the system R 4.6.1 library had no `haven`. I installed it with the repo's own `Rscript env/install.R` (pinned haven 2.5.5, jsonlite 2.0.0), so `reproduce.R` picked up `env/rlib` automatically. This dependency is undocumented in the run instructions, but the install script works.
- Ran `Rscript code/reproduce.R` three times. Copies are in `audit/results_run1.json`, `audit/results_run2.json` and `audit/results_run3.json`.
- **Result: identical.** After dropping `run.runtime_s` (wall-clock time: 0.29, 0.24 and 0.24 s), all three runs and the committed `outputs/results.json` give the same SHA-1 (`b47ce134…`). Every claim value, SE, CI and p-value is bit-for-bit equal.

## 2. Code vs paper methods

Sources: paper §2.6 (Statistical analysis), Table 1, Table 2 with its footnote, and the data's SPSS variable and value labels (checked with pyreadstat).

| Item | Paper | claims.json (pre-registered) | reproduce.R | Match? |
|---|---|---|---|---|
| Model | "gamma regression with a log link", Stata 17 | one multivariable gamma GLM (log) | `glm(..., Gamma(link="log"))`, one model | Yes. One model vs separate models is ambiguous in the paper (see note A) |
| Outcome | OHQ total 29–174 divided by 29 | `total_Happiness_score/29` | same | Yes. The 29 items sum exactly to `total_Happiness_score` (max diff 0). Using the total or `Adj_total_happiness` changes Exp(B) by at most 0.0001 |
| n | 405 after excluding 13 incomplete questionnaires | 405, no exclusions | 405 rows asserted, no NA | Yes |
| Gender | ref Men | ref 1 | ref 1 (label 1=Male, 2=Female; 208/197) | Yes |
| Relationship status | ref Single; Married, In a relationship | ref 1 | ref 1 (1=Single, 2=Married, 3=In a relationship) | Yes |
| Clinical grade | ref First-year stager | ref 1 | ref 1 (1=One-year stager) | Yes |
| University | ref Shiraz | ref 1 | ref 1 (1=Shiraz, 2=Fasa, 3=Jahrom) | Yes |
| Place of living | ref Dormitory | ref 1 | ref 1 (1=Dormitory) | Yes |
| Ethnicity | ref Persian | ref 1 | ref 1 (1=Persian, 2=Others) | Yes |
| Part-time job | ref Without | ref 0 | ref 0 (0=Negative) | Yes |
| Salary | ref Without income | ref 1 | ref 1 (1=Without Income) | Yes |
| Siblings | ref One and two | ref 1 | ref 1 (1='1-2') | Yes |
| Top student | ref Not being | ref 0 | ref 0 | Yes |
| Parental living status | ref Joint; Separated, Deceased a parent | ref 1 | ref 1. Label 4 (both deceased) has 0 cases and is dropped by `factor()` | Yes |
| Personality | ref Introvert | ref 1 | ref 1 (1=Introvert, 2=Extrovert; 233/172) | Yes |
| Forced migration | ref Not thinking | ref 0 | ref 0 | Yes |
| Emotional exhaustion | ref Without | ref 0 (`exhustion_to_work`) | same | Yes. The variable mapping is inferred from names only |
| Depersonalization | ref Without | ref 0 (`No_feeling_at_work`) | same | Yes. The variable mapping is inferred from names only |
| Happiness vs before pandemic | ref Get worse | ref 1 | ref 1 (1='Get worsed') | Yes |
| Age | continuous, per year | `AGE` | `AGE` (mean 24.2, SD 1.83, matching Table 1) | Yes |
| Stress VAS | continuous | `Living_stress_score` | same (mean 5.82, matching Table 1) | Yes |
| Somatic health VAS | continuous | `self_physical_examination` | same (mean 81.8, matching Table 1) | Yes |
| EI domains (5) | continuous, all 5 in Table 2 | five domain scores, EI total excluded | same. The labels confirm each domain is the sum of its two items | Yes |
| Variables not in Table 2 | not reported | excluded | excluded | Yes |
| Dispersion / SE | not reported (Stata default for gamma is `scale(x2)`) | Pearson, default (non-robust) SEs | R default Pearson χ²/df = 0.02233. SE(Exp B) = exp(b)·se(b) | Yes (see note B) |
| p-values and CI | "P > Z", z-based | z-based | `2*pnorm(-|z|)`, `exp(b ± 1.96 se)` | Yes |

**Mismatches found: none that count as bugs.** Interpretation notes:

- **A. One model vs separate models.** Ambiguous in the paper. The pre-registered multivariable reading is the more defensible one. The univariable sensitivity models (`outputs/sensitivity.json`) are much further from Table 2 (for example Gender 0.939, Extrovert 1.120, Stress 0.965, Regulation 1.101). In contrast, the multivariable SEs are close to Table 2's (Gender 0.0157 vs 0.016, Extrovert 0.0175 vs 0.018, Stress 0.0039 vs 0.004, Regulation 0.0079 vs 0.008). The reading is defensible, not a bug.
- **B. Stata's IRLS vs ML optimiser.** Stata `glm` uses ML (Newton-Raphson) with observed-information (OIM) SEs by default. R's IRLS gives expected-information (EIM) SEs. With a non-canonical log link these differ slightly. I recomputed the SEs with OIM, and the changes are at most 0.0004 in SE and 0.003 in p (C1 p 0.05038 → 0.05034). Point estimates are unaffected. This choice does not change any verdict.
- The sensitivity-only "reduced model" correctly includes `Living_stress_score` after the post-hoc fix logged in `steps.log`. That model is not graded.

## 3. Independent check (Python statsmodels)

`uvx --with pandas --with statsmodels --with pyreadstat python -I`: I fitted `smf.glm(..., family=Gamma(Log()))` with `scale="X2"` on the freshly downloaded file, building treatment contrasts explicitly with the same reference levels. The script is in the scratchpad (`indep.py`), and its output is in `audit/statsmodels_check.json`.

| Claim | Paper Exp(B) (p) | R `reproduce.R` | statsmodels (EIM) | statsmodels (OIM SEs) |
|---|---|---|---|---|
| C1 Women | 0.966 (0.037) | 0.968694 (p 0.05038) | 0.968694 (p 0.05038) | 0.968694 (p 0.05034) |
| C2 Age | 1.016 (<0.001) | 0.996905 (p 0.534) | 0.996905 (p 0.534) | 0.996905 (p 0.531) |
| C3 Extrovert | 1.076 (<0.001) | 1.077305 (p 4.7e-6) | 1.077305 (p 5e-6) | 1.077305 |
| C4 Stress | 0.990 (0.008) | 0.986494 (p 0.00050) | 0.986494 (p 0.00050) | 0.986494 (p 0.00052) |
| C5 Somatic health | 1.002 (<0.001) | 1.001070 (p 0.0302) | 1.001070 (p 0.0302) | 1.001070 (p 0.0286) |
| C6 Regulation own | 1.042 (<0.001) | 1.040286 (p 1.8e-7) | 1.040286 | 1.040286 |

R and statsmodels agree to 6 decimals in Exp(B), SE, CI and p. Scale (Pearson) is 0.022327 in both, with 375 residual df.

Further diagnostics (not graded; not used to change verdicts):
- **Age (C2).** No specification I tried gives a positive, significant age effect: multivariable 0.997 (p 0.53), univariable 1.004 (p 0.51), multivariable without Clinical_Grade 1.002 (p 0.73), Spearman ρ = 0.028 (p 0.58). The paper's 1.016 with SE 0.003 is also inconsistent with the paper's own Discussion ("negative statistically significant relationship with aging").
- **C1's p-value is close to 0.05 and depends on the SE method.** Primary (Pearson, EIM) 0.0504; OIM 0.0503; robust HC0 0.0496; deviance scale 0.0565; deposited 2-decimal `Adj_total_happiness` outcome 0.0495. The Exp(B) gap (0.9687 vs 0.966) is small.
- **Deposit data issue: item H7.** Its item-rest correlation is r = −0.45, while all other 28 items are +0.29 to +0.79. This strongly suggests H7 is mis-keyed in the deposited total (and probably in the authors' analysis). Re-keying H7 (7 − H7) gives Gender 0.963 (p 0.027), Age 0.996 (p 0.46), Extrovert 1.078, Stress 0.986, Health 1.0012, Regulation 1.041. This is not a bug in our code: we used the outcome exactly as the paper and deposit define it. It does not explain C2.

## 4. Verdicts

`python3 scripts/compare.py papers/hsr-2023-ei-happiness` re-run locally gives overall **Partial**: C1 Not reproduced, C2 Not reproduced, C3–C6 Partial. This matches the committed report card exactly (no diff).

| Claim | Rule verdict | Assessment | Reasoning |
|---|---|---|---|
| C1 Women 0.966 | Not reproduced | **Agree** (flag) | Exp(B) is 0.0027 off (outside ±0.0005), and the frozen rule needs the same significance conclusion. Ours is p = 0.0504 (`significant()` uses p < 0.05, applied correctly) vs paper 0.037. No bug: two implementations and both SE methods (EIM, OIM) give p > 0.05. The verdict is fragile, though. Robust SEs or the rounded deposited outcome give p ≈ 0.0496 and would make this Partial. There is no concrete bug, so no override. |
| C2 Age 1.016 | Not reproduced | **Agree** | Opposite side of 1 (0.997) and not significant (p 0.53). Every alternative specification tried agrees. The paper is internally inconsistent about the direction of the age effect. |
| C3 Extrovert 1.076 | Partial | **Agree** | 1.0773 vs 1.076, same direction and significance. The 0.0013 gap is outside the 3-decimal tolerance. |
| C4 Stress 0.990 | Partial | **Agree** | 0.9865 vs 0.990, same direction and significance (ours p 0.0005 vs 0.008). |
| C5 Somatic health 1.002 | Partial | **Agree** | 1.0011 vs 1.002, same direction, and significant in both. Ours is much weaker (p 0.03 vs <0.001, CI lower bound 1.0001), which the binary significance rule does not capture. |
| C6 Regulation of own emotions 1.042 | Partial | **Agree** | 1.0403 vs 1.042, same direction and significance. It is also the largest EI-domain Exp(B) in our model, so the "strongest EI predictor" ranking holds. |

**Overrides: none.** I found no bug in `reproduce.R`, so I did not write `audit.json`.

## 5. What this paper's authors could fix

1. State whether Table 2 comes from one multivariable model or separate models, and list the covariates in each.
2. Deposit the Stata do-file (glm options: optimiser, `scale()`, `vce()`) and the GBRT R script (package, hyperparameters, seed, and which variables entered).
3. Reconcile the age effect. Table 2 and the Abstract report Exp(B) 1.016 (positive), the Discussion and Conclusion describe a negative relationship, and the deposited data shows no significant association either way.
4. Check the scoring of OHQ item 7 in the deposited data. Its item-rest correlation is negative (−0.45), which suggests a reverse-keying error in the total score.
5. Correct the Table 2 internal inconsistencies: the Ethnicity "Others" CI (0.966–1.070) does not match Exp(B) 1.033 and SE 0.019, and the Siblings CI is a copy of the Salary row's CI.
6. Report Std. Err. and p with enough precision (somatic health SE printed as "0.000"), and say whether Std. Err. is for B or Exp(B).
7. In the Abstract, do not attribute an Exp(B) and p-value to the GBRT model. Make the Abstract p-values (0.04, 0.01) consistent with Table 2 (0.037, 0.008).
8. Document the variable-name mapping in the deposit (e.g. `No_feeling_at_work` = depersonalization, `exhustion_to_work` = emotional exhaustion) and the divisors used for the `Adj_` domain scores.
