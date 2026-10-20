# Independent audit: ee-2022-roedeer-sexratio

Hagen et al. (2022), *Ecology and Evolution*, doi:10.1002/ece3.8938. Auditor: independent agent that did not take part in the reproduction. Audit date: 2026-10-20.

**Bottom line:** the re-run is bit-identical and the data checksums match. No bug was found in `code/reproduce.R`. A second implementation (Python) reproduces every graded number to 6 decimals. All six rule verdicts are justified and there are **no overrides**, so no `audit.json` was written. Three verdicts are flagged below for the lead (C1, C4 and C5).

## 1. Clean re-run

| Item | Result |
|---|---|
| Clone | `git clone https://github.com/SujalPradhan/paper-reproducibility-engine` at HEAD `7991e22` into the scratchpad `audit-roedeer/repo` |
| claims.json vs freeze tag | `git diff claims-frozen-ee-2022-roedeer-sexratio HEAD -- claims.json`: no changes |
| Paper folder vs local copy | Identical apart from `data/`, which the repo does not commit (`diff -rq`) |
| Command | `Rscript code/reproduce.R`, run 3 times from the clone |
| Runtime | 0.55 / 0.52 / 0.55 s wall-clock. `runtime_s` in the JSON: 0.46 / 0.43 / 0.46, against 1.42 in the committed copy |
| Versions | R 4.6.1 (aarch64-apple-darwin, macOS 26.5.1), metafor 5.2.1, jsonlite 2.0.0. The paper used R 3.6.0 |
| Identical? | **Yes.** `results_run1/2/3.json` (in `audit/`) and the committed `outputs/results.json` are identical once `run.runtime_s` is removed. `model_output.txt` is also identical apart from the timestamp line. `checksums_ok: true` in all runs |

## 2. Data checksums

I re-downloaded all three files from the original Zenodo URLs in `data/README.md` (`https://zenodo.org/api/records/6513932/files/<file>/content`). I did not copy them from the local folder.

| File | Bytes | SHA-256 | Match |
|---|---|---|---|
| Sex_BW.csv | 211227 | fcacfc6a…5667179 | yes |
| Metafor_roe_sex.csv | 5359 | 6420d015…a94d4fa77 | yes |
| Temp_Data_comma_sep.csv | 7142 | 5f32728a…3f072ab | yes |

## 3. Code vs paper Methods and pre-registration

| # | Item | Paper / claims.json | reproduce.R | Assessment |
|---|---|---|---|---|
| 1 | C1/C2 data subset (years) | Paper: "12,437 fawns … from 1972 to 2019". methods_steps: drop Year < 1972 | Keeps Sex ∈ {f,m} and 1972 ≤ Year ≤ 2019, which gives N = 12435 | Follows the stated rule and the pre-registration. **Note:** all f/m rows with no year filter number exactly **12473** (the 38 extra rows are from 1970–71). This is the N printed in Table 2 (ref 47) and Table 3 (ID 90). It suggests the authors' binomial data set included 1970–71, and that 12,437 may be a transposition of 12,473. This is a defensible reading of an inconsistent paper, not a bug. |
| 2 | C1/C2 rows with missing Hasl | Not stated | Kept (N = 12435); sensitivity without them: 11793 | Defensible. Neither count gives 12437. |
| 3 | C2 n | claims.json `n` = 12473 (Table 2 row) | n = 12435 | Minor mismatch with the claim's source row. It has no effect on the verdict: with n = 12473, pf = 0.4780 and the CI is [0.4692, 0.4868], which also rounds to 0.48 [0.47, 0.49]. |
| 4 | C2 estimator | Exact binomial test (Clopper–Pearson) | `binom.test` | Matches. |
| 5 | C5/C6 covariates | T = mean of Oct–Dec (t−1) and Jan–Feb (t). P = Sep (t−1). Lapse rate T − 0.65·hasl/100 (Eq. 3) | Same. The lapse rate is applied to the window mean, which is mathematically identical to applying it to each month | Matches the pre-registration. The reference elevation and any scaling are unstated in the paper. |
| 6 | C5/C6 sample | Table 1: "12,437 roe deer offspring" | n = 11793 (642 Hasl-NA rows cannot be lapse-corrected) | Unavoidable given the data. The paper does not say how missing Hasl was handled. Adding the 1970–71 rows back changes nothing material (T 0.0136, T² 0.0087, both p > 0.15). |
| 7 | C5/C6 model | Binomial GLM, Eq. 2 f(x)=a0+a1x+a2x², fitted "with lme4" | `glm(binomial(logit))`, raw polynomials, no random effect | Defensible. Eq. 2 has no random term, and lme4 cannot fit a GLM without one. |
| 8 | C5/C6 coding | sex 0 = male, 1 = female | y = 1 if female | Matches. |
| 9 | C5/C6 units | Logit per °C (raw scale) | Raw °C and raw mm, not centred | Matches the pre-registration. **Note:** the paper's intercept is −0.855 (ours −0.014), its P_Sep coefficient is +0.003 (ours −0.0016), and the SE of its T² term is printed as 0 (ours 0.006). Together these show the authors' covariates were built or scaled differently in a way the paper does not describe. This is not evidence of a bug in our code: the climate join, columns and decimal parsing were checked. |
| 10 | C3/C4 subset | 36 prenatal and 15 secondary data sets | 37 P rows (all in the CSV) and 15 S rows | Defensible. No exclusion rule is given. By country, the CSV has 29 Great Britain P rows against the paper's 28, so one GB row is extra, but the paper does not say which. |
| 11 | C3/C4 effect size | d = ln(OR)/(π/√3), "two decimal places" | Deposited (2-dp) `d` and `d_se` | Matches the paper. Recomputing d and SE from N_female/N without rounding gives −0.0502 for P (vs −0.0503), so rounding does not drive the result. |
| 12 | C3/C4 estimator | Random-effects. τ² estimator not stated | `rma(..., method = "REML")`, Wald z CI | Defensible default, as pre-registered. With DerSimonian–Laird, P = −0.0520 [−0.0835, −0.0204], which still rounds to −0.05. |

No mismatch was found that is a bug in our code.

## 4. Independent check (Python 3.13, pandas 3.0.6, scipy 1.18.1, statsmodels 0.15.0)

Script: `/private/tmp/claude-501/-Users-sujal-Wiley-RP/324b2492-46b2-4d04-9718-e204eec976ef/scratchpad/audit-roedeer/scripts/indep_check.py`. It reads the freshly downloaded data and shares no code with reproduce.R.

| Number | R (reproduce.R) | Python | Method in Python |
|---|---|---|---|
| C1 N | 12435 | 12435 | pandas filter |
| C2 pf, CI | 0.477764 [0.468951, 0.486588] | 0.477764 [0.468951, 0.486588] | Beta-quantile Clopper–Pearson (scipy) |
| C3 RE mean, CI | −0.050314 [−0.083895, −0.016733] | −0.050313 [−0.083896, −0.016731] | REML likelihood maximised by hand (scipy) |
| C4 RE mean | −0.037635 | −0.037637 | Same |
| C5 T linear (SE, p) | 0.013513 (0.014478, 0.3506) | 0.013513 (0.014478, 0.3506) | statsmodels GLM Binomial |
| C6 T² (SE, p) | 0.008635 (0.006179, 0.1623) | 0.008635 (0.006179, 0.1623) | statsmodels GLM Binomial |

The results agree to at least 5–6 decimals, which rules out a tooling artefact.

A leave-one-out check on C3 was run as a diagnostic only, not as an analysis choice. Estimates range from −0.0591 (dropping MacDonald & Johnsen "Porton", N = 240) to −0.0415. Only that one drop would round to −0.06. Nothing in the paper justifies excluding that row, so it is not used.

## 5. Verdict assessment (`python3 scripts/compare.py papers/ee-2022-roedeer-sexratio`)

| Claim | Paper | Ours | Rule verdict | Auditor | Comment |
|---|---|---|---|---|---|
| C1 | 12,437 | 12435 | Partial | **Agree (flag)** | Correct under the frozen rules. However, the 2-unit gap is probably a coincidence. The file reproduces the paper's *other* figure, 12473, exactly when the 1970–71 rows are kept. Calling a count claim "Partial" on a direction test is generous, but it is what the pre-registered rule says. |
| C2 | 0.48 [0.47, 0.49] | 0.4778 [0.4690, 0.4866] | Reproduced | Agree | Point estimate and CI match to 2 dp under either N. |
| C3 | −0.06 [−0.09, −0.02] | −0.0503 [−0.0839, −0.0167] | Partial | Agree | Same sign, CI excludes 0, relative deviation 0.16. The 37-vs-36 row discrepancy is a plausible cause, but the paper does not let us resolve it. |
| C4 | −0.04 [−0.06, −0.03] | −0.0376 [−0.0524, −0.0229] | Reproduced | **Agree (flag)** | The point estimate is within ±0.005. The CI bounds do **not** match at 2 dp (they round to [−0.05, −0.02] against [−0.06, −0.03]), and the paper's interval is asymmetric about −0.04. "Reproduced" is correct under the point-value rule, but it sits at the generous end. |
| C5 | 0.019 (SE 0.084, p = .03) | 0.0135 (SE 0.0145, p = 0.35) | Not reproduced | **Agree (flag)** | The rule fails because the significance conclusion differs. However, the paper's own SE and p are mutually inconsistent: 0.019/0.084 gives z ≈ 0.23 and p ≈ 0.82. If the SE is correct, both results are non-significant and the rule would give Partial. We cannot tell which number is misprinted, and the paper's intercept and precipitation terms also differ. So there is no concrete basis for an override. |
| C6 | 0.001 (p = .01) | 0.0086 (p = 0.16) | Not reproduced | Agree | The value is about 8.6 times the paper's (relative deviation 7.6) and the significance differs. This is clearly outside Partial. |

Overall verdict: **Partial**. Overrides: **none**.

## 6. What this paper's authors could fix

- **Sample size.** The Baden-Württemberg N is given as 12,437 (Abstract, Methods, Table 1, Figure 1), 12,473 (Tables 2 and 3) and 12,475 (deposited Metafor CSV). The deposited Sex_BW.csv has 12,473 sexed fawns for 1970–2019 and 12,435 for 1972–2019. Neither period yields 12,437. State the exclusion rules and the year range actually used.
- **Deposited meta-analysis row.** The Hagen row has N_female = 5857 of N = 12475 (pf 0.4695). This contradicts its own "Proportion females" of 0.48 and the 5,962 females in Sex_BW.csv.
- **Table 1.** The temperature linear term (0.019, SE 0.084, p = .03) is internally inconsistent. The SEs of the squared terms and the P_Sep² estimate are printed as 0. Report more decimals or standardised covariates.
- **Covariate construction.** Say whether temperature and precipitation were centred or scaled, what reference elevation the lapse-rate correction (Eq. 3) uses, and how fawns without elevation were handled. Our covariates do not reproduce the published intercept (−0.855).
- **Software.** The GLMs are said to have been fitted with lme4, but Eq. 2 has no random effect. Name the function and any random terms.
- **Meta-analysis counts.** The text says 36 prenatal data sets, but the deposit has 37 (29 for Great Britain against the stated 28). Several N values differ between the CSV and Table 2 (for example Stubbe 166 vs 116, Majzinger 53 vs 73). The τ² estimator, and how data sets were aggregated to references for the fixed model, are not stated.
- **Mortality-corrected sex and age.** Say whether Sex_BW.csv contains the sex as corrected at death (97 corrections). Provide fawn age so that the <3-day and <7-day analyses (Figures S5–S6) can be reproduced.
- **Author code.** No analysis code is deposited.
