# Wiley Reproducibility Engine — Candidate Papers (gate results)

Prepared 2026-10-20. Every check marked as done below was actually run (curl/Python against the named APIs). Anything not checked is marked "NOT CHECKED".
Test downloads are in `/private/tmp/claude-501/-Users-sujal-Wiley-RP/324b2492-46b2-4d04-9718-e204eec976ef/scratchpad/downloads/`.

**Key gate finding: Dryad cannot be downloaded by a script without logging in.** Anonymous requests to `https://datadryad.org/api/v2/files/<id>/download` and `/api/v2/datasets/<doi>/download` return **HTTP 401** (`{"error":"Unauthorized, must have current bearer token"}`). The web route `/downloads/file_stream/<id>` returned **HTTP 403** to curl. Only the metadata API (HTTP 200) works without a login. For this reason all 4 shortlisted papers use Zenodo or Figshare, and the Dryad-only candidates are reserves.

**Overlap checks run for every candidate DOI listed below:**
- CODECHECK: `https://codecheck.org.uk/register/register.json` (HTTP 200). The only Wiley DOI in it is 10.1002/sim.10186, and none of our DOIs appear. The repository file `register.csv` has no article-DOI column (it only has certificate/repo/venue), so I used register.json instead.
- SEER-Repro (arXiv 2610.23845): I fetched the HTML full text (HTTP 200) and searched it for Wiley DOIs. It contains only cam4.1437, cam4.1757, cncr.20064 and cncr.27834. None of our DOIs or topics appear, and no shortlisted paper uses SEER data.
- ReScience C: I fetched `https://rescience.github.io/read/` (HTTP 200) and searched it for our DOIs, with 0 hits. That page contained no 10.1002/10.1111 DOIs at all, so it may not list the DOIs of the original papers. This check is weak. A title-level check of ReScience was NOT done.
- Web search for "<DOI> replication/reproduction" (done for the 5 papers in the shortlist plus reserve R1): no reproduction or replication found.

---

## 1. Shortlist (ranked)

| Rank | id | Title | DOI | Journal | Year | Article license (how verified) | Data link / license / size / download test | Code | PMCID | Feasibility (1–5) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `cam4-2024-hpd` | Incidence of immunotherapy-related hyperprogressive disease (HPD) across HPD definitions and cancer types in observational studies: a systematic review and meta-analysis | 10.1002/cam4.6970 | Cancer Medicine | 2024 | CC BY 4.0. Crossref `license` field = creativecommons.org/licenses/by/4.0 (HTTP 200); Europe PMC JATS `<license>` = CC BY 4.0 | https://doi.org/10.6084/m9.figshare.22256557 (Figshare article 22256557), **CC BY 4.0** (Figshare API), 1 file, 126 KB (`updated_extracted_data_HPD_22.08.29.xlsx`). Full anonymous GET of https://ndownloader.figshare.com/files/39557335 gave **HTTP 200, 126,259 B, valid xlsx**. Columns: study, year, hpd, total, definition, histology | none | PMC10891462 | **5**: a random-effects meta-analysis of proportions plus meta-regression (metafor/meta), with tidy extracted data in exactly the shape needed. Runs in minutes. Not SEER |
| 2 | `ee-2022-roedeer-sexratio` | Evidence for a male-biased sex ratio in the offspring of a large herbivore: the role of environmental conditions in the sex ratio variation | 10.1002/ece3.8938 | Ecology and Evolution | 2022 | CC BY 4.0 (Crossref license field and Europe PMC JATS) | https://doi.org/10.5281/zenodo.6513932, **CC BY 4.0** (Zenodo API), 3 files, 0.22 MB (Sex_BW.csv, Metafor_roe_sex.csv, Temp_Data_comma_sep.csv). Zenodo API HTTP 200. Ranged GET of Sex_BW.csv gave **206**, and the full GET gave **200, 211,227 B** | none | PMC9120210 | **4**: exact binomial test, a binomial GLM and a metafor meta-analysis on small CSVs. No code is shared, so the model has to be rebuilt from the Methods. The climwin window search is the hard part and can be skipped |
| 3 | `ee-2021-salmon-smr` | Standard metabolic rate does not associate with age-at-maturity genotype in juvenile Atlantic salmon | 10.1002/ece3.8408 | Ecology and Evolution | 2021 | CC BY 4.0 (Crossref and Europe PMC JATS) | https://doi.org/10.5281/zenodo.5255061, **CC BY 4.0**, 21 files, 221 MB in total. Of that, 212 MB is an optional raw respirometry zip; the processed `data-Ash2021-respirometry.txt` is 1.6 MB. Ranged GET of the respirometry txt gave **206**, and HEAD on the raw zip gave **200**. README and the models script downloaded (200) | **Yes**: numbered R scripts in the same Zenodo record (1-prep-functions, 2-prep-data, 4-models-mo2, 4-models-condition, powerAnalysis, …) | PMC8794721 | **4**: lme4 mixed model on processed data, with author code. Risk: depends on the GitHub-only package `axomatic` (eiriksen/axomatic) and on mclust |
| 4 | `hsr-2023-ei-happiness` | Emotional intelligence and happiness in clinical medical students: a cross-sectional multicenter study | 10.1002/hsr2.1745 | Health Science Reports | 2023 | CC BY 4.0 (Crossref and Europe PMC JATS) | https://doi.org/10.6084/m9.figshare.23291780, **CC BY 4.0** (Figshare API), 1 file, 67.5 KB SPSS .sav. Full GET of https://ndownloader.figshare.com/files/41052677 gave **HTTP 200, 67,522 B, valid SPSS file** (variables include AGE, GENDER, PERSONAL(ity), EI1–EI10, EI domain scores) | none | PMC10709659 | **4**: gamma GLM with log link (Stata in the original; R `glm(family=Gamma(link="log"))` is equivalent) on n=405. The second-stage GBRT is stochastic, so match it only loosely |

Mix: 2 ecology (Ecology and Evolution) and 2 health (Cancer Medicine, Health Science Reports). All 4 are non-Dryad, downloaded anonymously, and published 2021–2024.

---

## 2. Shortlisted papers: claims, methods, risks

### #1 `cam4-2024-hpd` (10.1002/cam4.6970)
**Headline claims (exact values):**
- Pooled HPD incidence **12.4% (95% CI 10.2%–15.0%)**, heterogeneity **Q = 119.32, p < 0.001**. Location: Abstract (Results) and Results text; forest plots in Figures 3–4.
- Meta-regression adjusted ORs versus RCC: AGC **10.83 (2.14–54.65), p < 0.001**; HCC **7.99 (1.68–38.13), p = 0.006**; NSCLC **7.14 (1.58–32.29), p = 0.005**; mixed/other **5.09 (1.12–23.14), p = 0.018**. Location: Table 1 and Abstract.
- Definition B (TGK ratio ≥ 2) versus Definition C: adjusted OR **1.82 (1.08–3.07), p = 0.025**; Definition A **1.20 (0.83–1.74), p = 0.335**. Location: Table 1.

**Methods:**
- Systematic review of observational studies of ICI-treated solid tumours (searches up to 21 June 2022).
- Random-effects meta-analysis of proportions (hpd/total), with Q, I² and 95% prediction intervals.
- Multivariable meta-regression (logit scale) on tumour type and HPD definition.

**Software:** R 4.2.1 with metafor and meta.

**Risks:** The transformation (logit vs. Freeman–Tukey), the τ² estimator (REML vs. DL) and the handling of zero events are not certain to match. Some studies may appear on several rows (one per definition), so the pooling unit has to be inferred. The xlsx has 2 sheets, and the second has not been inspected yet.

### #2 `ee-2022-roedeer-sexratio` (10.1002/ece3.8938)
**Headline claims:**
- Baden-Württemberg proportion of female offspring **0.48 [0.47, 0.49]**. Location: Table 2 (row "Hagen et al., this publication").
- **Built-in discrepancy flag:** Table 2 gives N = **12,473**, but the Abstract and Table 1 give N = **12,437**. Counting rows in Sex_BW.csv will settle it.
- Meta-analysis overall effect size d (fixed model): **−0.05 [−0.07, −0.02]** for the prenatal sex ratio and **−0.04 [−0.06, −0.03]** for the secondary sex ratio. Location: Results 3.2 and Figure 3.
- GLM (Table 1): temperature Oct–Feb estimate **0.019 (SE 0.084), p = .03**; temperature² **0.001, p = .01**; intercept **−0.855 (0.068)**. The SE of 0.084 is far too large for p = .03, which is a possible reporting inconsistency worth testing.

**Methods:**
- Exact binomial test of the female proportion against 0.5 (n ≈ 12.4k tagged fawns, 1972–2019).
- Binomial GLM (lme4) of offspring sex on Sep precipitation and Oct–Feb temperature, including quadratic terms. Windows were chosen with climwin.
- Effect size d = ln(OR)/(π/√3) (Chinn 2000), with fixed and random-effects meta-analysis in metafor and I².

**Software:** R 3.6.0, lme4, climwin, metafor.

**Risks:** No code. The temperature covariate in Temp_Data_comma_sep.csv has to be joined to the sex data correctly, and elevation classes may matter. Reproducing the climwin window selection is out of scope; take the paper's chosen window as given.

### #3 `ee-2021-salmon-smr` (10.1002/ece3.8408)
**Headline claims:**
- N = **150** fish (76 vgll3\*LL, 74 vgll3\*EE). Location: Results first paragraph.
- No significant effect of vgll3 on mass-adjusted SMR. Sex **p = .59**, sex:vgll3 **p = .69**, genotype on body condition **p = .33**. Location: Results and Appendix 2, Tables A1–A2.
- Metabolic scaling coefficient **0.88 ± 0.05 (95% CI)** in the full model (0.89 ± 0.24 in the simple model). CV of residuals **6.23% / 6.19%**. Residual SD **0.027**. Location: Results and Figure 3b.
- Power analysis: minimum detectable effect **4.25%** (vgll3) and **6%** (vgll3:sex). Location: Results (last paragraph).

**Methods:**
- Intermittent-flow respirometry. SMR is extracted per fish from about 50–60 measurement phases (processed slopes are provided).
- Linear mixed model: log10 SMR ~ log10 mass + vgll3 × sex + temperature, with family/batch random effects (lme4). Models are compared by AIC and cross-validation.
- Simulation-based post-hoc power analysis.

**Software:** R with tidyverse, lme4, car, mclust, readxl and `axomatic` (GitHub-only).

**Risks:** Install `axomatic` from GitHub, and pin its version if possible. SMR extraction (mclust/quantile of the slopes) must match. The power analysis is simulation-based (use a seed and accept approximate agreement). Do not download the 212 MB raw zip; it is not needed.

### #4 `hsr-2023-ei-happiness` (10.1002/hsr2.1745)
**Headline claims:**
- n = **405** participants (208 men / 197 women), mean age **24.2**. Location: Abstract and Results.
- Gamma regression Exp(B): women **0.966 (SE 0.016, p = 0.037, 95% CI 0.935–0.998)**; age **1.016/yr, p < 0.001**; extrovert **1.076, p < 0.001**; somatic health **1.002, p < 0.001**; stress **0.990, p = 0.01**. Location: Table 2 and Abstract. Note that the Abstract says p = 0.04 for women while Table 2 says 0.037, which is just rounding.
- GBRT: regulation of own emotions is the top predictor, **Exp(B) = 1.042, p < 0.001**. Location: Abstract and Figure 3.
- Mean EI **34.6/50**, mean happiness **3.78/6**. Location: Results.

**Methods:**
- Multicentre cross-sectional online survey (Iran, Dec 2021 to Jun 2022) using the BEIS-10 and the Oxford Happiness Questionnaire.
- Stage 1: gamma regression (log link) of the happiness score on demographic, personality, health, stress and EI domain variables.
- Stage 2: gradient-boosted regression trees on the significant variables.

**Software:** Stata 17 (gamma regression) and R 4.1.1 (GBRT).

**Risks:** The happiness total score may have to be rebuilt from items, and reverse-coding of the Oxford HQ is unknown. The exact covariate set and reference categories must be read from Table 2. GBRT is stochastic and its "Exp(B)" output is unusual. The data are SPSS .sav files, which need `haven`/`pyreadstat`.

---

## 3. Reserve candidates

| id | DOI / PMCID | Journal, year | Article license | Data, license, size, test | Code | Feasibility | Notes |
|---|---|---|---|---|---|---|---|
| R1 `ee-2024-bumblebee-cyan` | 10.1002/ece3.70328 / PMC11445450 | Ecology and Evolution, 2024 | CC BY 4.0 (Crossref and JATS) | Zenodo 7649989, CC BY 4.0, 1 xlsx 23 KB. Ranged GET **206** | none | 4 | Claims: cumulative mortality control/best/worst **63%/65%/59%**; mean body-weight loss **22.42%**; fat **28.72%** (Results 3.1–3.3, Figs 1–3). Binomial GLMM plus MuMIn model averaging (R 4.2.2, lme4). The text has CI typos ("95% CI = 63.24 to 52.1", "−23.25 to 856.22"), which makes it a good report-card example. Strongest reserve |
| R2 `ee-2023-drosophila-nonadditive` | 10.1002/ece3.10713 / PMC10630047 | Ecology and Evolution, 2023 | CC BY 4.0 (Crossref and JATS) | Zenodo 8382826, CC BY 4.0, 11 files 5.7 MB. CGE1 xlsx full GET **200** (36,040 B); Rmd **200** | **Yes** (2 Rmd + diagnostic_fcns.r) | 3 | Code and data are complete, but the claims are mostly qualitative (frequency dependence, Fig 2). Exact numbers would have to be taken from the Rmd output |
| R3 `ee-2024-ambystoma-hatching` | 10.1002/ece3.11160 / PMC10948370 | Ecology and Evolution, 2024 | CC BY 4.0 (Crossref and JATS) | **Dryad 10.5061/dryad.f4qrfj72k: needs token / manual browser download.** CC0. Metadata API 200; 1 xlsx 81,409 B + README 2,004 B. File download **401**, web file_stream **403** | Yes: Zenodo 10070149 (R script 20 KB, MIT) | 3 | Headline claims not yet extracted |
| R4 `ee-2023-honeybee-vairimorpha` | 10.1002/ece3.10528 / PMC10511299 | Ecology and Evolution, 2023 | CC BY 4.0 (Crossref and JATS) | **Dryad 10.5061/dryad.vt4b8gtxt: needs token / manual browser download.** CC0, 5 files 0.21 MB (NosemaAnalysis.csv 87 KB, etc.). File download **401** | Yes: Zenodo 7999767 (3 R scripts, about 150 KB, MIT) | 2 | Large GLMM script set; claims not extracted |

---

## 4. "Data on request" / data-sharing compliance flag examples

1. **10.1002/brb3.70643** (PMC12177200), Brain and Behavior 2025, "The Power of Posing: Do Body Display Instructions Have an Impact on Behavior in Daily Life?" (article CC BY 4.0). DAS: *"The data that support the findings of the study are available on request from the corresponding author. The data can be shared upon completion of a data‐sharing agreement. Syntaxes will be made available at the Open Science Framework … upon acceptance of the manuscript."* The OSF link given is a `view_only` link.
2. **10.14814/phy2.15775** (PMC10400406), Physiological Reports 2023, "Association of postprandial postexercise muscle protein synthesis rates with dietary leucine…" DAS: *"The datasets generated and/or analyzed during the study implementation are available from the corresponding author upon request."* (Also 10.14814/phy2.16054 / PMC11176737: *"Raw data are available from the corresponding author upon reasonable request."*)

Bonus flags (dead or vague links, same compliance chart):
- **10.1002/cam4.70965** (PMC12062952), Cancer Medicine 2025. DAS says data are *"openly available in Zenodo at https://zenodo.org/"* and gives no record ID. It also uses SEER data.
- **10.1002/brb3.70409** (PMC11904935), Brain and Behavior 2025. DAS says *"openly available on … OSF at https://osf.io/4ugc9/…"*, but the OSF API for node 4ugc9 returned **HTTP 401** (the node is private).

---

## 5. Rejected / screened log

Screened: 23 DOIs checked in detail against the gate (plus around 60 titles skimmed from search results). Passed gate: 4 shortlisted and 4 reserves.

- 10.1002/hsr2.70756 (appendicitis ML, PMC12010561): dataset Zenodo 7669442 is **CC BY-NC 4.0**, and 523 MB is ultrasound images.
- 10.1002/cam4.5608 (PMC10134365): data are CC BY-NC-ND, and Zenodo 6369996 is **restricted** (0 public files).
- 10.1002/cam4.3366 (PMC7541152): data are CC BY-NC-ND (Zenodo 582272).
- 10.1002/cam4.6828 (PMC10807554): only partial data on OSF/Zenodo; census-tract data are withheld and the rest is "upon request".
- 10.1002/cam4.70965 (PMC12062952): no Zenodo record ID in the DAS, and the paper is SEER-based (avoid).
- 10.1002/hsr2.71672 (PMC12715330): Zenodo 15073308 has **no license** (all rights reserved by default).
- 10.1002/hsr2.2271 (PMC11286539): article is **CC BY-NC**, and data are on Mendeley Data.
- 10.1002/hsr2.1848 (PMC10826239): article is CC BY-NC-ND and has no data.
- 10.1002/hsr2.2168 (PMC11186102): article is **CC BY-NC-ND** (the data are CC BY on Figshare).
- 10.1002/hsr2.71125 (PMC12540911): article is CC BY-NC-ND, and data are only in the supporting information.
- 10.1002/hsr2.71493 (PMC12598194): DAS says "not applicable", so there are no data.
- 10.1002/brb3.70542 (PMC12060217): OSF xm3ea is public but has **no license**.
- 10.1002/brb3.70020 (PMC11410860): Figshare data is CC BY, but the raw data are a 517 MB rar plus 328 MB of EEG, which is too heavy. The analysed .sav is only 3 KB.
- 10.1002/brb3.70897 (PMC12457727): OSF P8ZQF is not resolvable as a node through the API (404).
- 10.1002/brb3.70409 (PMC11904935): OSF node 4ugc9 returned 401 (private).
- 10.1002/brb3.70643 (PMC12177200): data on request.
- 10.1002/ece3.11021 (PMC10867597): Zenodo 8329522 is 48 GB of video and has no license.
- 10.1002/ece3.10528 and 10.1002/ece3.11160: moved to reserves because of the Dryad token requirement.
- 10.1002/ece3.11061 (PMC10918743): data in BExIS under a 5-year embargo.
- 10.1002/ece3.8225 (PMC8717356): data in the Hakai catalogue, not a standard open repository. Not tested.
- 10.1002/ece3.7147 and 10.1002/ece3.7501: biologging data portals (AODN/AADC) with GIS/tracking-heavy workflows.
- 10.1002/ece3.8757 (PMC8956859): heritability of cortisol, which needs a quantitative-genetics animal model (likely MCMC), so it is too slow.
- 10.1002/ece3.8348 (PMC8668767): simulation model, with no empirical data to reproduce.

---

## 6. Sources

- Europe PMC REST search and full text: https://www.ebi.ac.uk/europepmc/webservices/rest/search , https://www.ebi.ac.uk/europepmc/webservices/rest/<PMCID>/fullTextXML
- Crossref: https://api.crossref.org/works/<DOI> (license field, all 8 shortlist and reserve DOIs: HTTP 200, CC BY 4.0)
- Zenodo API: https://zenodo.org/api/records/{6513932,5255061,7649989,8382826,10070149,7999767,15073308,7669442,6369996,8329522}
- Figshare API: https://api.figshare.com/v2/articles/{22256557,23291780,25442425,26342269}
- Dryad API v2: https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.f4qrfj72k , …dryad.vt4b8gtxt (metadata 200, file downloads 401)
- OSF API: https://api.osf.io/v2/nodes/{xm3ea,p8zqf,4ugc9}/
- CODECHECK register: https://codecheck.org.uk/register/register.json and https://raw.githubusercontent.com/codecheckers/register/master/register.csv
- SEER-Repro: https://arxiv.org/abs/2610.23845 (HTML full text searched)
- ReScience C: https://rescience.github.io/read/
- Article pages: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10891462/ , https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9120210/ , https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8794721/ , https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10709659/ , https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11445450/
