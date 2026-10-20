# File contracts

## `papers/<id>/claims.json` — written by the claim extractor, frozen (git tag `claims-frozen-<id>`) before reproduction

```json
{
  "paper_id": "ee-2022-example",
  "title": "…",
  "doi": "10.1002/ece3.0000",
  "journal": "Ecology and Evolution",
  "year": 2022,
  "article_license": "CC BY 4.0",
  "pmcid": "PMC0000000",
  "data": {"url": "https://doi.org/10.5061/dryad.xxxx", "license": "CC0", "files": ["data.csv"]},
  "code": {"url": "https://… or null", "language": "R"},
  "claims": [
    {
      "id": "C1",
      "text": "Body size declined with temperature",
      "statistic": "regression slope",
      "reported": {"value": -0.42, "text": "-0.42", "se": 0.11, "ci": [-0.64, -0.20], "p": "<0.001"},
      "units": "g per °C",
      "n": 312,
      "location": "Table 2, row 3",
      "tolerance": {"type": "reported_precision"},
      "significance": {"alpha": 0.05}
    }
  ],
  "methods_steps": ["Load …", "Exclude …", "Fit lmer(y ~ x + (1|site))"],
  "software": ["R 4.1", "lme4 1.1-27"],
  "ambiguities": ["Paper does not say whether …"]
}
```

Optional `null_value` sets the no-effect value used for "direction" (default 1 for ratio statistics, else 0).

`tolerance.type` is one of `reported_precision` (default: half a unit of the last reported digit), `abs` (`value`), `rel` (`value` as a fraction). An optional `partial_rel` (default 0.5) sets the largest relative deviation that can still count as Partial. Choose these **before** seeing any reproduced number. If a looser tolerance is justified (stochastic method, rounding in a figure), write the justification in `tolerance.reason`.

## `papers/<id>/outputs/results.json` — written by the reproduction script itself (not by hand)

```json
{
  "paper_id": "ee-2022-example",
  "run": {"script": "code/reproduce.R", "used_author_code": true, "runtime_s": 42, "software": {"R": "4.5.1", "lme4": "1.1-37"}, "seed": 1},
  "claims": [
    {"id": "C1", "status": "ok", "value": -0.4137, "p": 0.0002, "notes": "…"},
    {"id": "C2", "status": "not_computable", "reason": "Site covariate not in deposit"}
  ]
}
```

## `papers/<id>/audit.json` — optional, written only by the auditor

```json
{"overrides": [{"claim": "C2", "verdict": "Partial", "reason": "…"}]}
```

`python scripts/compare.py papers/<id>` produces `report_card.json` and `report_card.md`.
