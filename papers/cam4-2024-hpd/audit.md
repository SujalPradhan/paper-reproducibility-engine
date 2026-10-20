# Independent audit: cam4-2024-hpd

Paper: Kim MJ, Hong SPD, Park Y, Chae YK. *Incidence of immunotherapy-related hyperprogressive disease (HPD) across HPD definitions and cancer types in observational studies.* Cancer Medicine 2024;13:e6970. doi:10.1002/cam4.6970.

Auditor: independent; did not take part in the reproduction. Audit date: 2026-10-20. Audited commit: `8b60e41` ("Reproduction: cam4-2024-hpd (pre-audit)"). The claims are frozen under tag `claims-frozen-cam4-2024-hpd` (`bc71afa`), and `claims.json` at HEAD is byte-identical to the tagged version.

**Bottom line.** I agree with all six "Reproduced" verdicts, and there are no overrides. The verdicts cover **point estimates only**. The reproduction's Table 1 CIs and p-values (C3–C6) differ from the paper's. This audit traces most of that gap to the paper itself rather than to the reproduction: the paper's definition rows are reproduced exactly by a z-test, and its histology CIs cannot be reproduced by any single standard test. One choice in the reproduction (`test = "t"` for the multivariable meta-regression) is defensible from the Methods, but Table 1's own numbers point the other way. That is a reporting note, not a bug.

---

## 1. Clean re-run

- Fresh `git clone https://github.com/SujalPradhan/paper-reproducibility-engine` into the auditor scratchpad (`.../scratchpad/audit-cam4/repo`, HEAD `8b60e41`). The clone matches the local paper folder except for the gitignored data and the empty `code/author/`.
- Data were re-downloaded from the original source URL in `data/README.md`, https://ndownloader.figshare.com/files/39557335, into the clone's `data/`.
- `Rscript code/reproduce.R` was run 3 times from the clone (R 4.6.1, metafor 5.2.1, meta 8.5.0, lme4 2.0.6). All three runs exited 0. Each run gives the expected warning "Cannot invert the Hessian for the saturated model", which concerns only the residual-heterogeneity test of the meta-regression.
- Copies are in `audit/results_run1.json`, `audit/results_run2.json` and `audit/results_run3.json`.
- **Result: identical.** With `run.runtime_s` removed (1.5 / 1.3 / 1.3 s), all three runs and the committed `outputs/results.json` have the same canonical JSON (md5 `d456fc5f…` for all four). `outputs/sensitivity.json` and `outputs/model_output.txt` from the clone are also byte-identical to the committed ones. The analysis is deterministic and needs no seed.

## 2. Data checksum

| File | Expected SHA-256 (README) | Re-downloaded SHA-256 | Size | Figshare MD5 |
|---|---|---|---|---|
| `updated_extracted_data_HPD_22.08.29.xlsx` | `6535d5b3…0b0f3a` | `6535d5b38afba2ea4473dea9abb29f00c819824f1ff2fa3cf56472da210b0f3a` | 126259 (match) | `058105fa4c1797ebb1c8a664de398c72` (match) |

Sheet 1 has 34 rows, 558 events and 4117 patients, matching the paper. Sheet 2 holds the same multiset of (hpd, total, definition, histology) across its 34 study rows. Choosing sheet 1 therefore has no effect on any result.

## 3. Code vs paper Methods

Sources: the paper's Methods ("Statistical analysis"), its Results and Table 1, `claims.json` `methods_steps`, and `code/reproduce.R`.

| Paper Methods / Results | claims.json | reproduce.R | Match? |
|---|---|---|---|
| GLMM, "log-odds transformation" | `measure='PLO'` | `rma.glmm(measure="PLO")` | Yes |
| "maximum likelihood estimation" | `method='ML'` | `method="ML"` | Yes |
| "adaptive Gaussian hermite quadrature" (nAGQ not stated) | noted as ambiguity | metafor default (glmer, nAGQ = 7) | Yes. Audit check: nAGQ ≥ 5 with a converged optimizer gives the same rounded ORs. Laplace (nAGQ = 1) would give AGC 10.82, so adaptive quadrature matters here and is used. |
| "95% CIs were estimated using the Student's t-distribution" (small k / heterogeneity) | `test='t'` / HK | `test="t"` for pooled, subgroup, univariable and multivariable models | Pooled C1: yes. The t-based CI 10.20–14.99 matches the paper's 10.2–15.0, while the z-based CI 10.28–14.89 would not, so t is right here. Univariable meta-regression: yes; t reproduces the Results-text p-values exactly (see §4). **Multivariable (Table 1): probably not.** The definition rows match a z-test exactly (see §4). This is a defensible reading, not a bug, and it affects only CIs and p-values, not graded values. |
| Cochran Q for heterogeneity | ambiguity: which Q | `QE.Wld` (Wald-type) | Yes, best-supported reading (see §5, C2) |
| Higgins I² | — | metafor I² 78.7% in notes; meta I² 72.3% also shown | Paper's 72% is meta's I² = (Q_Wald − df)/Q_Wald. Notes report both, which is transparent. |
| 95% PI | — | metafor `predict` gives 4.5–29.6% | Paper 4.5–29.7%. Minor 0.1-point gap at the upper bound; probably package version or PI df (df = 32 gives 29.65). Not graded. |
| All 34 studies, zero-event study (Zheng 2021) kept, no continuity correction | yes | `stopifnot(nrow==34, 558, 4117)`; no exclusions | Yes |
| Meta-regression: tumor type + definition, multivariable | `mods=~histology+definition` | same | Yes |
| Reference levels RCC and definition C (Table 1) | yes | `relevel(..., "RCC")`, `relevel(..., "C")` | Yes |
| Tumor types as subgroups only if > 2 studies, "mixed or other" pooled | encoded in data | uses the data file's `histology` as is | Yes (the coding is in the deposit) |
| R 4.2.1, metafor/meta (versions not given) | — | R 4.6.1, metafor 5.2.1, meta 8.5.0 | Version mismatch, disclosed in steps.log. No observed effect on point estimates. |
| ORs = exp(coef), rounded to 2 dp | yes | unrounded; compare.py applies ±0.005 | Yes |

**Bugs found: none affecting claim values.** One cosmetic issue: a stale code comment ("also gives I2 and IV Q") says meta's GLMM output includes an inverse-variance Q; it does not, as the reproducer's own post-hoc fix in steps.log notes. A post-hoc notes/sensitivity fix after Run 1 is logged honestly and changed no claim values. I confirmed that the committed values are reproduced exactly.

## 4. Independent check (different routes)

Scripts and outputs are in the auditor scratchpad: `scripts/independent.R`, `scripts/table1_probe.R`, `scripts/nagq.R`, `scripts/misc.R` and the matching `*_output.txt`.

**Route A: `lme4::glmer` directly.** Model: `cbind(hpd, total-hpd) ~ 1 + (1|study)`, binomial logit, adaptive GHQ nAGQ = 7. The study-level random intercept is coded by row.

| Quantity | Paper | glmer (nAGQ=7) | meta::metaprop GLMM (HK) | Reproduction |
|---|---|---|---|---|
| C1 pooled incidence | 12.4% (10.2–15.0) | 12.3985% (t33 CI 10.20–14.99) | 12.3985% (10.20–14.99), PI 4.54–29.62 | 12.3985% (10.20–14.99) |
| C2 Q | 119.32 | — | Wald 119.320 / LRT 141.884 | 119.3195 |
| C3 AGC vs RCC | 10.83 | 10.8257 | 10.8265 (metareg) | 10.8265 |
| C4 HCC vs RCC | 7.99 | 7.9931 | 7.9937 | 7.9937 |
| C5 NSCLC vs RCC | 7.14 | 7.1407 | 7.1412 | 7.1412 |
| C6 def B vs C | 1.82 | 1.8195 | 1.8195 | 1.8195 |
| mixed/other vs RCC (not a claim) | 5.09 | 5.0852 | 5.0854 | 5.0854 |
| def A vs C (not a claim) | 1.20 | 1.2014 | 1.2014 | 1.2014 |

**Route B: `meta::metaprop(method="GLMM", method.tau="ML")` + `meta::metareg(~histology+definition)`.** This independently gives the same values (table above). glmer and metafor differ only in the 4th decimal, because of optimizer settings. Across bobyqa, Nelder–Mead and nAGQ 5–25, every OR rounds to the paper's value.

**Q statistic candidates (C2).**

| Q | Value |
|---|---|
| Wald-type (QE.Wld) | 119.32 |
| Likelihood-ratio (QE.LRT) | 141.88 |
| Inverse-variance Cochran Q, logit with 0.5 continuity correction | 122.07 |
| Inverse-variance Q, Freeman–Tukey | 140.44 |
| Inverse-variance Q, raw proportions | 168.05 |

Only the Wald Q matches. The paper's I² = 72% also equals (119.32 − 33)/119.32 = 72.3%. The LRT Q would give 76.7%. So the paper's printed Q and I² are internally consistent only with the Wald Q.

**Table 1 CIs and p-values (C3–C6), checked independently.**

| Row | Paper CI, p | z-test (ML GLMM) | t-test, df = 27 (reproduction) | Implied critical value: paper CI half-width / z-SE |
|---|---|---|---|---|
| AGC | 2.14–54.65, <0.001 | 3.31–35.44, 0.0001 | 3.13–37.47, 0.0005 | 2.678 |
| HCC | 1.68–38.13, 0.006 | 2.55–25.10, 0.0004 | 2.41–26.49, 0.0014 | 2.674 |
| NSCLC | 1.58–32.29, 0.005 | 2.36–21.57, 0.0005 | 2.25–22.71, 0.0017 | 2.675 |
| mixed/other | 1.12–23.14, 0.018 | 1.68–15.43, 0.0041 | 1.59–16.25, 0.0078 | 2.674 |
| def A | 0.83–1.74, 0.335 | **0.83–1.74, 0.335** | 0.81–1.77, 0.343 | 1.946 |
| def B | 1.08–3.07, 0.025 | **1.08–3.07, 0.025** | 1.05–3.15, 0.033 | 1.957 |

Findings:

- The paper's **definition rows are reproduced exactly by the z-test** (Wald, normal) version of the same model. The reproduction has this in `sensitivity.json` (`metareg_z_test`) but grades with the t-test version.
- The paper's **histology CIs** are, on the log scale, the correct point estimate ± **2.675 × the z-SE**, with the same multiplier for all four rows. That multiplier corresponds to no standard choice: 1.96, t with df 27 or 33, or a Bonferroni z all fail, and t would need df ≈ 4.4. Profile-likelihood CIs (AGC 3.61–41.12) and the lme4 RX-based vcov do not reproduce them either.
- The paper's **histology p-values** fit no single test either. They are larger than the z or LRT p-values (LRT: AGC 1.6e-5, HCC 7.6e-5, NSCLC 6.0e-5, mixed 9.9e-4). A t-test with df ≈ 9 matches HCC (0.006) and mixed (0.018) but not AGC (0.003 vs "<0.001") or NSCLC (0.007 vs 0.005). They are also smaller than what the paper's own CIs imply (about 0.004, 0.009, 0.011 and 0.035, as already recorded in `claims.json` ambiguities).
- The Results-text univariable p-values (histology omnibus 0.004, definition 0.17; AGC <0.001, HCC 0.002, NSCLC 0.002, mixed 0.005) are reproduced exactly by `rma.glmm(..., test="t")`. So the authors used t for at least the univariable models.

**Conclusion.** The paper's Table 1 is internally inconsistent: the point estimates are correct, the definition-row intervals and p-values come from a z-test, and the histology intervals and p-values come from no procedure I could identify. The reproduction's CI/p mismatch for C3–C5 is therefore not evidence of a wrong model. For C6, switching the reproduction to z would match the paper exactly.

## 5. Per-claim verdict assessment

`python3 scripts/compare.py papers/cam4-2024-hpd` (run locally) gives: overall Reproduced; C1–C6 all Reproduced. The regenerated report_card files are unchanged from the committed ones.

**These verdicts cover point estimates only** (compare.py tests `value` against the reported precision). CIs and p-values are not graded. For C3–C6 they differ from the paper as described in §4, mostly because of the paper itself.

| Claim | Paper | Ours | Margin to tolerance edge | Assessment |
|---|---|---|---|---|
| C1 pooled incidence | 12.4% | 12.398% | 0.002 of 0.05 | **Agree.** The CI also matches (t-based 10.20–14.99 vs 10.2–15.0). |
| C2 Cochran Q | 119.32 | 119.3195 | 0.0005 of 0.005 | **Agree.** See the Q-choice note below. |
| C3 AGC OR | 10.83 | 10.8265 | 0.0035 of 0.005 | **Agree.** Tight but robust: all converged adaptive-GHQ fits (nAGQ 5–25, bobyqa/Nelder–Mead) give 10.825–10.827. Only a Laplace fit (10.817) would fail. CI/p differ (paper's histology CIs are unexplained; see §4). Significance agrees. |
| C4 HCC OR | 7.99 | 7.9937 | 0.0037 of 0.005 | **Agree.** Robust across routes (7.9924–7.9945). Same CI/p caveat. |
| C5 NSCLC OR | 7.14 | 7.1412 | 0.0012 of 0.005 | **Agree.** Same CI/p caveat. |
| C6 def B OR | 1.82 | 1.8195 | 0.0005 of 0.005 | **Agree.** The graded t-test CI/p (1.05–3.15, 0.033) differ from the paper. The ungraded z-test version (1.08–3.07, 0.025) matches it exactly. |

**Q choice (C2): was it decided before results, and is it the most natural reading?**

- *Timing.* `steps.log` records the Wald-Q decision ("Decided before running") under a 14:00:26 timestamp, before the "RUN 1 … 14:01:40" entry. However, all eight opening entries share the same second as START, so the log was clearly written in a batch and its timestamps are coarse. Git has a single commit (`8b60e41`, 14:01:57) holding code, outputs and log together, so **git cannot independently confirm the order**. The frozen `claims.json` (13:55) lists the Q ambiguity but leaves it open. The reproducer also knew the target 119.32 in advance. So the "decided before results" statement rests on the log alone.
- *Naturalness.* The choice is nevertheless well supported independently of timing. (a) meta's GLMM printout, which the paper's methods name, lists the Wald-type Q first. (b) The paper's I² = 72% is arithmetically (Q_Wald − df)/Q_Wald. Neither the LRT Q nor any inverse-variance Q gives 72%. (c) No other candidate Q is within 2.7 of 119.32. I judge Wald-Q to be the most natural reading, and the verdict does not depend on trusting the log timing.

**Overrides: none.** No `audit.json` was written.

## 6. What this paper's authors could fix

1. **Table 1 / Abstract: make the CIs and p-values come from one stated test.** The definition rows match a Wald z-test, while the histology rows' CIs (≈ ±2.675 SE) and p-values match no standard test and are mutually inconsistent. Please state the test (z, t and df, or LRT) and the CI method used for the multivariable meta-regression, and correct the histology rows.
2. **Name the heterogeneity statistic.** For a GLMM there are Wald-type and likelihood-ratio Q tests (119.32 vs 141.88 here); the paper reports one as "Cochran Q" without saying which. Also note that I² was derived from that Q.
3. **Clarify where the t-distribution was applied.** It evidently applies to the pooled estimate and the univariable meta-regressions, but apparently not to the multivariable model.
4. **Report quadrature points and package versions.** The number of quadrature points (nAGQ) and the metafor/meta/lme4 versions are missing. With Laplace instead of adaptive quadrature, the AGC OR moves from 10.83 to 10.82.
5. **Deposit the analysis code.** None was deposited. A short R script would have resolved items 1–4.
6. **Minor.** The PI upper bound (29.7%) is not exactly reproduced (29.6%). The Abstract reads ORs as "risk". Sheet names ("22.02.14") do not match the file name ("22.08.29"), and the deposit contains two sheets with the same 34 studies in different orders. Please state which sheet is the analysis input and how "mixed or other" was composed.
