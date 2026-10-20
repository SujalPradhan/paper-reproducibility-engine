# Independent audit: ee-2021-salmon-smr

Åsheim et al. (2021), *Ecology and Evolution*, doi:10.1002/ece3.8408. Auditor: an independent agent that did not take part in the reproduction. Audit date: 2026-10-20.

**Bottom line:** three clean re-runs from a fresh clone give identical results, identical to each other and to the committed `results.json` (only timings differ). All data checksums match. The diff between the authors' code and the copy we ran is limited to plotting, axomatic and multidplyr. **No overrides**, so no `audit.json` was written.

The audit found one substantive issue that the reproduction missed. The small, "unexplained" model-1 gaps are **not** caused by the lme4/lmerTest version. They come from an R-version effect in the authors' own data preparation: under R ≥ 4.3, `ymd_hms()` silently drops all 5,377 midnight rows of the temperature log. When those rows are kept, as they would have been under the authors' R 4.0.4, model 1 matches every printed F, DenDF and AIC in Table A1 to the last digit. No graded value moves by more than 3e-5, so no verdict changes.

## 1. Clean re-run

| Item | Result |
|---|---|
| Clone | `git clone https://github.com/SujalPradhan/paper-reproducibility-engine` at HEAD `809d173`, into `/private/tmp/claude-501/-Users-sujal-Wiley-RP/324b2492-46b2-4d04-9718-e204eec976ef/scratchpad/audit-salmon/repo` |
| claims.json vs freeze tag | `git diff claims-frozen-ee-2021-salmon-smr HEAD -- claims.json`: empty. The local copy is byte-identical to the clone |
| Clone vs local folder | `diff -rq`: identical apart from the uncommitted `data/` files, `env/Rlib*` and (after the runs) timing fields in `outputs/` |
| Package library | `env/Rlib` is not in git. **`env/install.R` fails on a clean machine**: it installs `remotes` into `env/Rlib` but never puts `env/Rlib` on `.libPaths()`, so `remotes::install_version` stops with "there is no package called 'remotes'". I re-ran it as `R_LIBS=env/Rlib Rscript env/install.R`, which installed every pinned version (tidyverse 2.0.0, mclust 6.1.3, lmerTest 3.2.1, lme4 2.0.6, cvms 2.0.1, MuMIn 1.48.19, readr 2.2.0, lubridate 1.9.5, Matrix 1.7.5, …) |
| Command | `Rscript code/reproduce.R`, run 3 times from the clone's paper folder (R 4.6.1, macOS arm64) |
| Runtime | 260 / 286 / 308 s wall-clock (power analysis 232–275 s). The committed run took 260.6 s |
| Identical? | **Yes.** `audit/results_run1/2/3.json` and the committed `outputs/results.json` are identical once `runtime_s` and the per-script `time_s` are removed. `git diff` in the clone shows that only timing lines changed. `power_vgll3.csv`, `power_vgll3xsex.csv`, `tb_smr.csv`, `model1_smr_full.txt` and `model2_condition_full.txt` are byte-identical to the committed ones. C6 is identical, as expected with seed 1 |
| Script status | Same as committed: `4-outputs-various.R` stops (raw FishResp zip not downloaded) and `4-models-mo2.R` stops at `cvms::cross_validate(models=…)`. Both stops come after everything that is graded |

## 2. Checksums

I re-downloaded all six data files from the original Zenodo URLs (`https://zenodo.org/api/records/5255061/files/<name>/content`) into the clone's `data/`. I did not copy them from the local folder.

| File | SHA-256 | Match |
|---|---|---|
| data-Ash2021-respirometry.txt | deac6d38…547ee3 | yes |
| data-Ash2021-sampled-fish.xlsx | f5ef8ac8…fb48ee6c | yes |
| data-Ash2021-genotypes.txt | bda6684e…074b60dd | yes |
| data-Ash2021-tank-densities.txt | dbb9f9d2…7c4c3fd | yes |
| data-Ash2021-temp-loggers-small-tanks-Dec2020.txt | 6965ab2f…77c4521 | yes |
| README-Ash2021-description-of-files.txt | 43bad2f5…314718e | yes |

I also re-downloaded the 9 author scripts from Zenodo. `diff -r` against `code/author/` shows no difference.

## 3. Author code vs the code we ran

`diff -r code/author code/author_run` shows changes in every file, because of line endings and encoding. To find the real changes, I decoded `code/author/*.R` from Windows-1252 and stripped CR on both sides. The substantive differences are then:

| File | Change | Category | Touches analysis? |
|---|---|---|---|
| 2-prep-data.R l.6 | `library(axomatic)` commented out | axomatic | No. `axis_x`/`axis_y` are used only in plots |
| 4-models-mo2.R l.69–145 | Everything from "# Plots for model coefficients…" to the end is commented out (tb_coeff, plo_coeff, ggsave, ggpredict plot) | plotting | No. All models, `confint`, `anova`, `AIC` and the cvms call come before l.69 |
| powerAnalysis.R l.49–52, 63, 77 | 3 `multidplyr` cluster-setup lines and 2 `multidplyr::partition(cluster) %>%` pipe lines commented out | multidplyr | No change to the simulation. It is now sequential, so one `set.seed` governs it (author comment: "gives same result, just slower") |
| powerAnalysis.R l.83–134 | Two plot + ggsave blocks commented out | plotting | No |
| 1-prep-functions, 3-prep-plots, 4-models-condition, 4-outputs-various, 4-plot_* | No change | — | — |

No path edits were needed. `reproduce.R` uses `setwd(data/)` instead. **Verdict: the diff is clean.**

Cosmetic findings:
- `1-prep-functions.R` is mostly Windows-1252 but contains UTF-8 "Ṁ" in four roxygen comment lines (59, 62, 63, 65). Re-encoding the file from Windows-1252 turned those into mojibake ("á¹€"). Only comments are affected.
- steps.log says the copies were converted from CRLF to LF, but 6 of the 9 copies still have CRLF.

## 4. Code vs paper

| # | Claim / item | Paper (Table / text) | reproduce.R extracts | Assessment |
|---|---|---|---|---|
| 1 | C1 model and term | Table A1(A) full model, "Log10 body mass", REML | `mod_rate1` (authors' formula, verbatim), `fixef` for `log10(weight)` | Correct. Units are log10/log10 |
| 2 | C2 term and p | "vgll3 (LL)" estimate, type-III F p .771 | Estimate for `geno_vgll3LL`. p/F/DenDF from `anova(type=3)` for `geno_vgll3` | Correct. The paper's p .771 matches the type-III F test (0.7718), not the coefficient t-test (0.659). F 0.0877 and DenDF 12.943 match exactly |
| 3 | C3 term and p | "vgll3(LL):Sex(male)" −0.014, p .117, F 0.248 | `geno_vgll3LL:sexmale`, `anova` for `geno_vgll3:sex` | Correct. p 0.1176 matches the table. F = 2.480, which shows the paper's 0.248 is a decimal slip |
| 4 | C4 statistic | Random effects "Residual" 0.0269 (Std.dev) | `sigma(mod_rate1)` | Correct. This is the residual SD on the log10 scale |
| 5 | C5 model and term | Table A2(A) "vgll3 (LL)", p .326 | `mod_condition1`, `geno_vgll3LL`, `anova(type=3)` | Correct. Estimate, CI, F 1.049, DenDF 12.177 and p .326 all match at printed precision. Fulton's K uses length in cm (as in the code, and as claims.json pre-registered) |
| 6 | C6 statistic | MDE 4.25% at power ≥ 0.8 | `effect_pct = 10^c_b1*100 − 100`, the smallest grid value with power ≥ 0.8 | Correct. `coeff=18` in the author script is element [3,4] of the 5×4 coefficient matrix, which is the p-value of b1. Units are % |
| 7 | N and coding | N = 150 (76 LL / 74 EE; 69 m / 81 f; 14 families; 10 batches). References EE and female | Same | Matches Table A3 totals |
| 8 | avgTemp covariate | Code comment: batch means 10.17 / 10.64 °C | 10.178 / 10.652 | **Mismatch, now explained, see §5.** Under R 4.6.1 the 5,377 midnight temperature readings are dropped. steps.log wrongly attributes the "5377 failed to parse" warning to `respirometry.txt` (0 failures there) and says no claim is affected |
| 9 | Profile CIs | C1 CI [0.830, 0.928] | [0.82948, 0.92839] | **Numerically fragile.** Refitting from `tb_smr.csv`, or perturbing SMR by a relative 1e-12, flips the profile to a second solution, [0.82999, 0.92835]. The intercept and avgTemp CIs move more (intercept −1.094 vs −1.076). The cause is that the batch variance is near zero (non-monotonic `.sig02` profile). CIs are not graded, but their third decimals should not be read as evidence either way |

No bug was found in `code/reproduce.R`'s extraction logic.

## 5. Version test, and the actual cause of the model-1 gaps

**lme4 1.1-26 / lmerTest 3.1-3 (as requested):** this could not be done within the time box. lme4 1.1-26 does not compile on R 4.6.1 against current RcppEigen and Matrix (`Eigen::CholmodDecomposition` missing). Paper-era RcppEigen 0.3.3.9.1 fails under C++20 (`std::result_of`) and, when forced to C++17, against the current LAPACK prototypes (`dgesdd_`). I stopped after about 15 minutes.

**Proxy test:** I used lme4 **1.1-37** (the last 1.x release) with lmerTest **3.1-3** (the paper's version), in a separate library, and refit model 1 and model 2 from `outputs/tb_smr.csv`. Fixed effects, sigma, REML criterion, and every type-III F, DenDF and p are identical to lme4 2.0-6 / lmerTest 3.2-1 (DenDF for log10 mass 90.518 in both). Four optimizers (nloptwrap default and tight, bobyqa, Nelder–Mead) all reach the same optimum, REMLcrit −598.17768. **The lme4/lmerTest version hypothesis is not supported.** Output: `audit/version_test_model1.txt`.

**Actual cause:** `2-prep-data.R` runs `ymd_hms(dateTime)` on a column that `readr::read_delim` has already parsed to POSIXct. lubridate turns it back into character first. Since R 4.3.0, `as.character(<POSIXct>)` drops "00:00:00" element by element, so all 5,377 midnight readings become `NA` and are filtered out of the temperature log. Under the authors' R 4.0.4 they were kept. I recomputed avgTemp with those rows kept and refit (`audit/scripts/midnight_diag_full.R`, output `audit/avgtemp_midnight_check.txt`):

| Quantity | Paper | Our run (midnight rows dropped) | Midnight rows kept |
|---|---|---|---|
| Model 1 AIC | −580.185 | −580.178 | **−580.185** |
| log10 mass F / DenDF | 1160.548 / 90.347 | 1159.682 / 90.518 | **1160.548 / 90.347** |
| sex DenDF | 129.139 | 129.113 | **129.139** |
| avgTemp DenDF | 6.831 | 6.834 | **6.831** |
| interaction DenDF | 136.132 | 136.127 | **136.132** |
| Intercept CI lower | −1.077 | −1.094 | **−1.077** |
| Simple model AIC / F / DenDF | −606.652 / 1318.099 / 90.954 | −606.643 / 1317.262 / 91.083 | **−606.652 / 1318.099 / 90.953** |
| C1 estimate | 0.878 | 0.877721 | 0.877746 |
| C2 estimate | 0.004 | 0.004585 | 0.004580 |
| C3 estimate | −0.014 | −0.014553 | −0.014547 |
| C4 residual SD | 0.0269 | 0.0269755 | 0.0269753 |

With the authors' avgTemp, our model is numerically the authors' model. The remaining C2–C4 misses therefore come from how the paper prints these values (0.00458 → "0.004", −0.01455 → "−0.014", 0.026975 → "0.0269" look truncated, while 0.87775 → "0.878" and 0.01182 → "0.012" are rounded). They do not come from the reproduction. The graded values change by at most 3e-5, so no verdict changes. This is an environment effect on the authors' unmodified code, not a bug in `reproduce.R`. The reproduction log should still record it.

## 6. Verdicts

I ran `python3 scripts/compare.py papers/ee-2021-salmon-smr` locally. It gives the same verdicts, and `report_card.md` and `report_card.json` were left byte-identical.

| Claim | Paper | Ours | Rule verdict | Auditor assessment |
|---|---|---|---|---|
| C1 scaling coefficient | 0.878 | 0.877721 | Reproduced | **Agree.** Robust: 0.877746 with the paper-era avgTemp. CI [0.829, 0.928] vs [0.830, 0.928] differs only through the fragile profile (§4 #9) |
| C2 vgll3 effect | 0.004 | 0.004585 | Partial | **Agree under the rules.** Misses ±0.0005 by 0.00008. Same sign, CI spans 0, p 0.772 vs .771, F and DenDF exact. The paper's own fit evidently also gave about 0.0046 (§5), so the miss is a printing artefact. The pre-registered rule grades the printed value, so I see no concrete ground to override |
| C3 vgll3 × sex | −0.014 | −0.014553 | Partial | **Agree under the rules.** Misses by 0.00005. p .1176 matches Table A1, and is non-significant as in the paper. Same reasoning as C2 |
| C4 residual SD | 0.0269 | 0.026975 | Partial | **Agree under the rules.** Rel. diff 0.3%. The paper's CV of 6.19% is not reproducible from any fit I ran (6.211%), which suggests the authors used a truncated SD |
| C5 condition, vgll3 | 0.016 | 0.015583 | Reproduced | **Agree.** Exact at printed precision, including CI, F, DenDF and p. Not affected by avgTemp |
| C6 power MDE | 4.25% | 4.25% | Reproduced | **Agree.** Robust to the seed. With 10,000 simulations the Monte Carlo SE of power is about 0.004. Power at 4.00% is 0.772 (7 SE below 0.8) and at 4.25% it is 0.822 (5.5 SE above), so essentially any seed, or the authors' parallel run, gives 4.25% |

**Overrides: none.** Overall: Partial (by rule). Substantively, every graded number and every significance conclusion is reproduced. The three Partials reflect last-digit printing in the paper, not a computational difference.

## 7. Bugs and issues in our pipeline (reported, not fixed)

1. **steps.log misdiagnosis (substantive):** the "5377 failed to parse" warning comes from the temperature log (midnight rows), not `respirometry.txt`, and it does affect avgTemp (§5). The log's "not investigated further" and "no claim affected" are wrong in principle, though the graded values are unaffected at printed precision. The real cause of the "unexplained" model-1 gaps should be recorded.
2. **`env/install.R` fails on a clean checkout** because `env/Rlib` is not on `.libPaths()`, so `remotes::` cannot be found. It also compares `"2.0-6"` and `"3.1-5"` with `as.character(packageVersion())` (which gives `"2.0.6"` and `"3.1.5"`), so lme4 and car are reinstalled on every call. The Dockerfile has never been built.
3. **The environment is only partly pinned:** `reproduce.R` puts `env/Rlib` first but falls back to the system library (Matrix, lubridate, readr are unpinned). The R version (4.6.1 vs the authors' 4.0.4) materially changes the authors' data prep (§5).
4. Cosmetic: comment mojibake in `author_run/1-prep-functions.R`, and the incomplete CRLF→LF note in steps.log.

## 8. What this paper's authors could fix

- Table A1(A): interaction F is printed 0.248 (computes to 2.48). Log10 mass p is printed ">.001" (should be "<.001"). The intercept CI upper bound is printed −0.062 (computes to −0.623). The random-effect term is written "(1+batch)" for (1|batch).
- Rounding is inconsistent across Table A1. Some estimates appear truncated (0.00458 → 0.004, −0.01455 → −0.014, SD 0.026975 → 0.0269) and others rounded (0.87775 → 0.878).
- The Results text gives p = .59 (sex) and p = .69 (sex × vgll3), which disagree with Table A1 (.322, .117) for the same model.
- The CV of residuals (6.19%, full model) does not follow from the reported residual SD (gives 6.21%).
- The simple-model scaling coefficient is given as "0.89 ± 0.24", while its CI half-width is about 0.05. Table A2(B) residual SD is printed 0.004 (Table A2(A) gives 0.061).
- Fulton's K is described with length in mm, but the code uses cm.
- The avgTemp description (fish's own tank, last 3 days before acclimation) differs from the code (mean of all tanks, date − 5 d to date − 2 d).
- Code: `ymd_hms()` is applied to an already-parsed POSIXct column, so results depend on the R version (≥ 4.3 silently drops midnight readings). Using the parsed column directly, or an explicit format, would make this stable.
- Code: `calcSMR` uses `length(time)`, which resolves to `stats::time`, so the 10% class-size safeguard is disabled. `cvms::cross_validate(models=…)` in the SMR script uses an argument name that current cvms rejects. The authors' own condition script uses `formulas=`.
- The power analysis has no seed, and its Figure A2 caption (log mass, scaling 0.8, interaction fixed at 0%) does not match the script (raw mass, 0.83, interaction = −vgll3 effect).
- Package versions could be pinned (e.g. an renv lockfile) and the scripts saved in a single encoding (the files mix Windows-1252 and UTF-8).

## Files

- `audit/results_run1.json`, `results_run2.json`, `results_run3.json`: the three clean re-runs
- `audit/version_test_model1.txt`: lme4 2.0-6 vs 1.1-37/lmerTest 3.1-3, optimizer check, profile-CI fragility
- `audit/avgtemp_midnight_check.txt`: model 1 and the simple model with and without the midnight temperature rows
- `audit/scripts/`: the diagnostic scripts (read `tb_smr.csv` and the Zenodo data; no shared code with `reproduce.R` beyond the model formula)
