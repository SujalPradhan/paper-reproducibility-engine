# Reproducibility Engine for Wiley journals: summary

*Straive innovation team · prototype · 21 October 2026*
*Live data story: https://sujalpradhan.github.io/paper-reproducibility-engine/*

## The problem

Reviewers rarely re-run a paper's analysis. Existing reproduction efforts are human-run and narrow:
- **CODECHECK, ReScience C and I4R** each cover a few hundred papers, mostly in GIScience, computational science or economics.
- **Two Wiley social-science titles are already checked systematically:** AJPS (by the Odum Institute) and Econometrica (by its Data Editor).
- **An AI-agent study (SEER-Repro, Oct 2026)** included four Wiley cancer papers.

Nothing systematically covers Wiley's **ecology, life-science and health portfolio**. That is the gap. See `landscape.md` for sources.

## What we built (end-user flow)

1. **Submit**: a paper, a journal issue or a batch.
2. **Check**: read the data availability statement (Europe PMC full text); verify the article is CC BY; test that the data actually downloads. Papers with "data on request" are flagged.
3. **Pre-register**: extract each headline number exactly as printed, the methods and the ambiguities; fix a tolerance; **commit it to git before any analysis**.
4. **Reproduce**: run the authors' code unchanged if it exists, otherwise write one script from the methods, logging every assumption.
5. **Verdict**: a fixed script compares the numbers. Possible verdicts are Reproduced, Partial, Not reproduced and Not reproducible.
6. **Audit**: a separate agent re-downloads the data, re-runs everything three times, cross-checks with a different implementation and rules on each verdict. A human expert reviews before anything is published.

## Results (4 papers, 24 headline claims, all independently audited)

| Paper | Journal | Verdict | Claims |
|---|---|---|---|
| Immunotherapy hyperprogressive disease (meta-analysis) | Cancer Medicine 2024 | **Reproduced** | 6 of 6 reproduced |
| Roe deer offspring sex ratio | Ecology and Evolution 2022 | **Partial** | 2 reproduced, 2 partial, 2 not reproduced |
| Salmon metabolic rate vs vgll3 genotype (authors' code) | Ecology and Evolution 2021 | **Partial** | 3 reproduced, 3 partial (last-digit misses) |
| Emotional intelligence and happiness in medical students | Health Science Reports 2023 | **Partial** | 4 partial, 2 not reproduced |

**Totals:** 11 claims reproduced, 9 partial, 4 not reproduced, out of 24. The auditors overrode no verdicts.

We screened 32 papers to find these. 8 passed the licence and data gate; 3 were flagged "data on request"; the rest failed on licence, missing data or size. Papers were chosen for tractability, so **this is not a reproducibility rate**.

**What the misses look like.** Every miss had a specific, checkable cause:
- a sample size printed three different ways;
- standard errors that cannot produce the printed p-values;
- a Discussion that contradicts its own table;
- a decimal slip in a printed statistic;
- in the salmon paper, a software update that silently drops midnight readings when the authors' own code is re-run today.

## Business value

- **Readers:** a "Reproduced" badge on the article page, linked to a claim-level report card.
- **Editors:** pre-publication signals: internal inconsistencies, unclear methods, non-compliant data statements ("on request", missing licence, private repositories).
- **AI labs:** each audited claim becomes an evaluation task with a known answer, in CORE-Bench format with a PaperBench-style rubric. **24 tasks** are packaged so far (`tasks/`).
  - The most valuable tasks are those where the paper's printed number does *not* reproduce. An agent that copies the paper fails; only one that does the analysis passes.
  - The same tasks can serve as private evaluation sets or RL training environments.

## What we reused vs built

- **Reused** (open licences, attributed):
  - Europe PMC, Crossref, Zenodo, Figshare and Dryad APIs;
  - the R packages the papers used (metafor, meta, lme4, haven);
  - the CORE-Bench task format and PaperBench rubric format (both MIT).
- **Built:** the verdict engine (`compare.py`, with rules and tests committed before any reproduction), the task packager and this data story.
- **Ideas only:** statcheck (GPL).
- **Dropped:** GROBID; JATS XML made PDF parsing unnecessary.

See `tooling.md`.

## Caveats

- Four papers is a demonstration, not a measurement.
- Dryad, the main repository for Wiley ecology data, needs an API token for machine downloads.
- One step in our process (assumptions logged before results) is self-reported today. The next version commits the analysis plan to git before the first run.
