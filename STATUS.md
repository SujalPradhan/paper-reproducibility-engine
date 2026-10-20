# STATUS — Reproducibility Engine demo

Pitch: 2026-10-21 17:30 IST · Freeze: 2026-10-21 15:00 IST

## Done
- landscape.md: the gap claim is narrowed to Wiley's ecology, life-science, chemistry and materials journals. AJPS and Econometrica are already checked systematically. SEER-Repro (AI agent, arXiv 2610.23845) included 4 Wiley cancer papers.
- tooling.md: 29 tools ranked. Paper text from Europe PMC JATS; data from Zenodo/Figshare REST; tasks in CORE-Bench task.json + PaperBench rubric.json format (MIT)
- R 4.x + lme4/glmmTMB/car/emmeans/renv installed
- Repo skeleton, verdict rules (`scripts/compare.py`) + unit tests (6 passing), file contracts (`CLAIMS_SCHEMA.md`)

## In progress
- Paper hunter + license/data gate → `candidates.md`

## Blocked
- Dryad file downloads return 401 without an API token (verified). The hunter is steering to Zenodo/Figshare/OSF data. A Dryad token from the user would unlock Dryad-only papers.

## Papers
| id | stage | verdict | issue |
|---|---|---|---|
| — | hunting | — | — |
