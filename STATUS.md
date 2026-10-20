# STATUS: Reproducibility Engine demo

Pitch: 2026-10-21 17:30 IST · Freeze: 2026-10-21 15:00 IST
Live site: https://sujalpradhan.github.io/paper-reproducibility-engine/

## Done
- landscape.md: the gap claim is narrowed to Wiley's ecology, life-science, chemistry and materials journals (AJPS and Econometrica are already checked systematically; SEER-Repro included Wiley cancer papers)
- tooling.md: 29 tools ranked; reuse plan; CORE-Bench and PaperBench formats
- candidates.md: 32 papers screened, 8 passed the gate, 4 shortlisted (CC BY 4.0, confirmed through Crossref)
- Claims frozen and tagged for all 4 papers before reproduction (24 claims)
- All 4 papers reproduced **and audited**; no auditor overrides:
  - cam4-2024-hpd: Reproduced (6/6)
  - ee-2022-roedeer-sexratio: Partial (2 reproduced, 2 partial, 2 not)
  - ee-2021-salmon-smr: Partial (3 reproduced, 3 partial; the cause is a date-parsing change that drops midnight readings)
  - hsr-2023-ei-happiness: Partial (4 partial, 2 not; age effect reverses)
- Totals: 11 reproduced, 9 partial, 4 not reproduced of 24 claims
- audit.md, summary.md, update_for_manager.md, tasks.md written
- 24 evaluation tasks (tasks/, tasks.md)
- Site deployed via GitHub Pages; QA done: phone and desktop, light and dark, 45 links (all DOIs resolve)

## In progress
- (none). Ready for the pitch.

## Next (optional, before the 15:00 freeze)
- Rehearse the walkthrough; reset the Dryad API secret after the demo

## Blocked
- (none)

## Papers
| id | journal | stage | verdict | issue |
|---|---|---|---|---|
| cam4-2024-hpd | Cancer Medicine | done | Reproduced | #1 |
| ee-2022-roedeer-sexratio | Ecology and Evolution | done | Partial | #2 |
| ee-2021-salmon-smr | Ecology and Evolution | done | Partial | #3 |
| hsr-2023-ei-happiness | Health Science Reports | done | Partial | #4 |

## Process notes
- The reproducers' "assumption logged before results" is self-reported (single commit). The next version commits the analysis plan first.
