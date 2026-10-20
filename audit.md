# Independent audit: summary

For each paper, an auditor agent that took no part in the reproduction:
1. cloned the repository fresh from GitHub;
2. re-downloaded the data from the original repository and checked SHA-256;
3. re-ran the reproduction script three times;
4. compared the code with the paper's methods;
5. cross-checked key numbers with a different implementation;
6. ruled on every verdict.

It could override a verdict only with a written, demonstrable reason. Full reports are in `papers/<id>/audit.md`, and the run outputs are in `papers/<id>/audit/`.

| Paper | Re-runs identical | Data checksums | Independent cross-check | Bugs in our code | Overrides | Final verdict |
|---|---|---|---|---|---|---|
| [cam4-2024-hpd](papers/cam4-2024-hpd/audit.md) | Yes (3/3) | Match (Figshare) | lme4::glmer and meta::metaprop GLMM give the same estimates | None affecting values (one stale comment) | None | Reproduced (6/6) |
| [ee-2022-roedeer-sexratio](papers/ee-2022-roedeer-sexratio/audit.md) | Yes (3/3) | Match (Zenodo) | Python (scipy, statsmodels, hand-written REML) matches to 5–6 dp | None | None | Partial (2 R, 2 P, 2 NR) |
| [ee-2021-salmon-smr](papers/ee-2021-salmon-smr/audit.md) | Yes (3/3, seeded power analysis included) | Match (Zenodo); author scripts byte-identical to the deposit | Package-version test; diagnosed the date-parsing cause | `env/install.R` failed on a clean checkout (**fixed**); a wrong diagnosis in steps.log (**corrected**, with the correction appended) | None | Partial (3 R, 3 P) |
| [hsr-2023-ei-happiness](papers/hsr-2023-ei-happiness/audit.md) | Yes (3/3) | Match (Figshare) | Python statsmodels GLM Gamma(log) matches to 6 dp | None | None | Partial (4 P, 2 NR) |

## What the auditors found beyond the verdicts

- **cam4-2024-hpd.** The Wald-type Q is the only candidate consistent with the paper's I² of 72%. Of the Table 1 rows, the definition rows match z-based tests, while the histology rows' intervals match no standard test (about t with 4.4 df). Our script uses t-based intervals; these differ from the paper, but point estimates, which are what we graded, match.
- **ee-2022-roedeer-sexratio.** With no year filter, the data give exactly 12,473 sexed fawns, the figure in Tables 2–3. The Abstract's 12,437 is probably a transposition. The C5 standard error printed in Table 1 (0.084) is inconsistent with its printed p (.03). The C4 point estimate reproduces, but its interval does not at 2 dp.
- **ee-2021-salmon-smr.** On R ≥ 4.3, the authors' `ymd_hms()` call drops all 5,377 midnight temperature readings. Keeping them reproduces every Table A1 F, DenDF and AIC exactly. The printed F = 0.248 for vgll3×sex is a decimal slip for 2.48. The Results text p-values (.59, .69) disagree with Table A1 (.322, .117).
- **hsr-2023-ei-happiness.** C1 fails on significance by a hair (p = 0.0504 against 0.05; robust SEs give 0.0496), so the verdict is fragile. Happiness item H7 correlates negatively with the rest of the scale (r = −0.45), which suggests a scoring error in the deposited total. The age effect is not positive under any specification tried, and the paper's own Discussion says it is negative.

## Limitation in our own process

The claims freeze (`claims-frozen-<id>` tags) is verifiable from git history. The reproducers' statement that each assumption was logged before results were seen is **self-reported**: code, log and outputs were committed together. Next version: commit the analysis plan before the first run.
