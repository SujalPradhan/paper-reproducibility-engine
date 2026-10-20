**Wiley Reproducibility Engine: demo ready for tomorrow's pitch**

**Gap:** nobody reproduces Wiley's ecology and health papers systematically. AJPS and Econometrica are already covered, so we narrowed the pitch line to these fields.

**What we did:**
- Screened 32 open-access Wiley papers, picked 4 (Cancer Medicine, 2× Ecology and Evolution, Health Science Reports) and froze 24 headline claims in git before running anything.
- Re-ran every analysis; an independent agent audited all four.

**Results:**
- **Reproduced:** 1 paper (the cancer meta-analysis, 6/6 claims).
- **Partial:** 3 papers.
- **Claims:** 11 reproduced, 9 partial, 4 not reproduced. No audit overrides.
- **Why the misses happened:** each had a concrete cause, e.g. inconsistent Ns, wrong p-values, a reversed age effect, values truncated instead of rounded.

**Also built:** 24 AI-lab eval tasks in CORE-Bench format.

**Links:** live story https://sujalpradhan.github.io/paper-reproducibility-engine/ · client one-pager `summary.md`
