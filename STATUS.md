# STATUS — Reproducibility Engine demo

Pitch: 2026-10-21 17:30 IST · Freeze: 2026-10-21 15:00 IST

## Done
- landscape.md: the gap claim is narrowed to Wiley's ecology, life-science, chemistry and materials journals. AJPS and Econometrica are already checked systematically. SEER-Repro (AI agent, arXiv 2610.23845) included 4 Wiley cancer papers.
- tooling.md: 29 tools ranked. Paper text from Europe PMC JATS; data from Zenodo/Figshare REST; tasks in CORE-Bench task.json + PaperBench rubric.json format (MIT)
- R 4.x + lme4/glmmTMB/car/emmeans/renv installed
- candidates.md: 23 screened, 4 shortlisted (all CC BY 4.0, confirmed through Crossref; Zenodo/Figshare data downloads tested)
- Repo skeleton, verdict rules (`scripts/compare.py`) + unit tests (6 passing), file contracts (`CLAIMS_SCHEMA.md`)

## In progress
- Claim extraction (4 agents in parallel) → `papers/<id>/claims.json`

## Blocked
- Dryad file downloads return 401 without an API token (verified). The hunter is steering to Zenodo/Figshare/OSF data. A Dryad token from the user would unlock Dryad-only papers.

## Papers
| id | journal | stage | verdict | issue |
|---|---|---|---|---|
| cam4-2024-hpd | Cancer Medicine | extracting claims | — | #1 |
| ee-2022-roedeer-sexratio | Ecology and Evolution | extracting claims | — | #2 |
| ee-2021-salmon-smr | Ecology and Evolution | extracting claims | — | #3 |
| hsr-2023-ei-happiness | Health Science Reports | extracting claims | — | #4 |
