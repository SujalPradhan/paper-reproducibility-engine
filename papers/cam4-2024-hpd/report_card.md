# Report card: Incidence of immunotherapy-related hyperprogressive disease (HPD) across HPD definitions and cancer types in observational studies: A systematic review and meta-analysis

- DOI: https://doi.org/10.1002/cam4.6970
- Journal: Cancer Medicine
- **Overall verdict: Reproduced**
- Verdicts are computed by `scripts/compare.py` against tolerances frozen in `claims.json` before reproduction.

| Claim | Paper says | We got | Difference | Tolerance | Verdict | Notes |
|---|---|---|---|---|---|---|
| C1: Pooled incidence of HPD across 34 observational studies is 12.4% (Abstract (Results); Results paragraph 4 ('The overall estimated incidence of HPD was 12.4% (95% CI, 10.2%–15.0%)'); also reported there: I2 = 72%, 95% PI 4.5%–29.7%; 558 events / 4117 patients) | 12.4% | 12.398 | -0.002 | ±0.05 | Reproduced | Pooled incidence % from rma.glmm(PLO, ML, test='t'), back-transformed; t-based 95% CI 10.2-15.0%, 95% PI 4.5-29.6%, I2=78.7%, k=34, events/N=558/4117. |
| C2: Significant between-study heterogeneity in HPD incidence (Cochran Q) (Abstract (Results); Results paragraph 4) | 119.32 | 119.3195 | -0.0005 | ±0.005 | Reproduced | Wald-type heterogeneity Q (QE.Wld) from rma.glmm, df=33. LRT Q=141.88 (sensitivity.json). meta::metaprop Wald Q=119.32; meta I2=72.3% (metafor I2=78.7%). |
| C3: Advanced gastric cancer has higher odds of HPD than RCC, adjusted for definition type (Table 1, row 'AGC'; Abstract; Results paragraph after Figure 4) | 10.83 | 10.8265 | -0.0035 | ±0.005 | Reproduced | Adjusted OR AGC vs RCC from rma.glmm(PLO, ML, test='t', mods=~histology+definition; ref RCC, C); t-based 95% CI 3.13-37.47, df=27. |
| C4: Hepatocellular carcinoma has higher odds of HPD than RCC, adjusted for definition type (Table 1, row 'HCC'; Abstract) | 7.99 | 7.9937 | 0.0037 | ±0.005 | Reproduced | Adjusted OR HCC vs RCC from rma.glmm(PLO, ML, test='t', mods=~histology+definition; ref RCC, C); t-based 95% CI 2.41-26.49, df=27. |
| C5: NSCLC has higher odds of HPD than RCC, adjusted for definition type (Table 1, row 'NSCLC'; Abstract) | 7.14 | 7.1412 | 0.0012 | ±0.005 | Reproduced | Adjusted OR NSCLC vs RCC from rma.glmm(PLO, ML, test='t', mods=~histology+definition; ref RCC, C); t-based 95% CI 2.25-22.71, df=27. |
| C6: Definition B (TGK ratio >= 2) yields higher HPD incidence than Definition C (RECIST PD + deltaTGR > 50), adjusted for tumor type (Table 1, row 'B (Saâda-Bouzid et al)'; Abstract; Results paragraph after Figure 4) | 1.82 | 1.8195 | -0.0005 | ±0.005 | Reproduced | Adjusted OR definition B vs C from rma.glmm(PLO, ML, test='t', mods=~histology+definition; ref RCC, C); t-based 95% CI 1.05-3.15, df=27. |
