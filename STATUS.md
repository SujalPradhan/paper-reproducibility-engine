# STATUS: Reproducibility Engine demo

Pitch: 2026-10-21 17:30 IST · Freeze: 2026-10-21 15:00 IST
Live site: https://sujalpradhan.github.io/paper-reproducibility-engine/

## Done
- landscape.md: the gap claim is narrowed to Wiley's ecology, life-science, chemistry and materials journals (AJPS and Econometrica are already checked systematically; SEER-Repro included Wiley cancer papers)
- tooling.md: 29 tools ranked; reuse plan; CORE-Bench and PaperBench formats
- candidates.md: 32 papers screened, 8 passed the gate, 4 shortlisted (CC BY 4.0, confirmed through Crossref)
- Claims frozen and tagged for all 4 papers before reproduction (24 claims)
- 3 papers reproduced **and audited**; no auditor overrides:
  - cam4-2024-hpd: Reproduced (6/6)
  - ee-2022-roedeer-sexratio: Partial (2 reproduced, 2 partial, 2 not)
  - hsr-2023-ei-happiness: Partial (4 partial, 2 not; age effect reverses)
- 18 evaluation tasks (tasks/, tasks.md)
- Site v1 deployed via GitHub Pages (Actions)

## In progress
- ee-2021-salmon-smr: reproducing (authors' code)

## Next
- Audit salmon, then repackage tasks and rebuild the site
- summary.md, update_for_manager.md, root audit.md
- Final visual QA (desktop/mobile, light/dark)

## Blocked
- (none)

## Papers
| id | journal | stage | verdict | issue |
|---|---|---|---|---|
| cam4-2024-hpd | Cancer Medicine | done | Reproduced | #1 |
| ee-2022-roedeer-sexratio | Ecology and Evolution | done | Partial | #2 |
| ee-2021-salmon-smr | Ecology and Evolution | reproducing | — | #3 |
| hsr-2023-ei-happiness | Health Science Reports | done | Partial | #4 |

## Process notes
- The reproducers' "assumption logged before results" is self-reported (single commit). The next version commits the analysis plan first.
