# STATUS — Reproducibility Engine demo

Pitch: 2026-10-21 17:30 IST · Freeze: 2026-10-21 15:00 IST

## Done
- landscape.md: the gap claim is narrowed to Wiley's ecology, life-science, chemistry and materials journals. AJPS and Econometrica are already checked systematically. SEER-Repro (AI agent, arXiv 2610.23845) included 4 Wiley cancer papers.
- tooling.md: 29 tools ranked. Paper text from Europe PMC JATS; data from Zenodo/Figshare REST; tasks in CORE-Bench task.json + PaperBench rubric.json format (MIT)
- R 4.x + lme4/glmmTMB/car/emmeans/renv installed
- Claims frozen and tagged for all 4 papers (`git tag -n1`): 24 claims total. compare.py fixed before the freeze (number parsing; direction measured from the null value)
- Dryad API token stored outside the repo (`~/.dryad_token`), which unblocks Dryad reserves
- candidates.md: 23 screened, 4 shortlisted (all CC BY 4.0, confirmed through Crossref; Zenodo/Figshare data downloads tested)
- Repo skeleton, verdict rules (`scripts/compare.py`) + unit tests (6 passing), file contracts (`CLAIMS_SCHEMA.md`)

## In progress
- Reproduction (4 agents in parallel, 1.5 h box each)

## Blocked
- (none)

## Papers
| id | journal | stage | verdict | issue |
|---|---|---|---|---|
| cam4-2024-hpd | Cancer Medicine | reproducing | — | #1 |
| ee-2022-roedeer-sexratio | Ecology and Evolution | reproducing | — | #2 |
| ee-2021-salmon-smr | Ecology and Evolution | reproducing | — | #3 |
| hsr-2023-ei-happiness | Health Science Reports | reproducing | — | #4 |
