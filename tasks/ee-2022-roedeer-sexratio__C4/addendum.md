# Addendum

Clarifications drawn from the paper (frozen before reproduction):

- Read Sex_BW.csv (sep=';', CRLF). Columns: Year (birth year t), Sex ('f'/'m'/'NA'), Hasl (m a.s.l., may be 'NA').
- Drop rows with Sex == 'NA'. The paper's period is 1972–2019, so drop Year < 1972 (file spans 1966–2019). Record the resulting N for C1. Whether rows with Hasl == 'NA' are kept for the binomial test is unspecified: report N both with and without Hasl-NA rows.
- C2: n_female = count(Sex=='f'), n = count(Sex in {f,m}); pf = n_female/n; 95% CI from exact binomial test (R binom.test(n_female, n), Clopper-Pearson). Round to 2 decimals.
- Read Temp_Data_comma_sep.csv (sep=';', dec=','). Jahr = calendar year; Temp_BW_<Mon> = monthly mean temperature (°C); NDS_BW_<Mon> = monthly precipitation.
- For each fawn with birth year t: T_OctFeb = mean(Temp_BW_Oct, Temp_BW_Nov, Temp_BW_Dec at Jahr=t−1; Temp_BW_Jan, Temp_BW_Feb at Jahr=t). P_Sep = NDS_BW_Sep at Jahr=t−1.
- Apply lapse-rate correction (Equation 3) per fawn: T_cor = T_OctFeb − 0.65 * Hasl/100. Requires non-NA Hasl, so drop Hasl-NA rows for the GLM.
- Response y = 1 if Sex=='f', 0 if 'm' (paper: 0 – male, 1 – female).
- C5/C6: fit glm(y ~ P_Sep + I(P_Sep^2) + T_cor + I(T_cor^2), family = binomial(link='logit')). Extract the estimate, SE and Wald p for the T_cor and T_cor^2 terms; compare with Table 1 (intercept −0.855 (0.068); P_Sep 0.003 (0.002) p=.11; P_Sep^2 0 (0) p=.13). Sensitivity check: uncorrected T_OctFeb.
- climwin window search (Equation 1 / Appendix S7–S8) is NOT reproduced; the paper's selected windows (Temp Oct(t−1)–Feb(t), Precip Sep(t−1)) are taken as given.
- Read Metafor_roe_sex.csv (sep=';', dec=',', encoding latin1). Columns: N, N_female, 'Sex ratio' (P=prenatal, S=secondary), d, d_se, Proportion females, Low_95, High_95, North, Eeast.
- Use provided d and d_se (paper: 'calculated using data with two decimal places'). Optional check: d = ln(pf/(1−pf))/(pi/sqrt(3)) from Proportion females.
- C3: metafor::rma(yi=d, sei=d_se, data=subset(Sex ratio=='P'), method='REML') (random effects, data-set level; default estimator assumed). Report the estimate and 95% CI.
- C4: same as C3 on subset(Sex ratio=='S').
- Secondary (not a frozen claim): fixed model at reference level (method='FE') after aggregating data sets by reference (Author+Pub_Year): reported −0.05 [−0.07, −0.02] (P) and −0.04 [−0.06, −0.03] (S); I^2 = 11.4% (P) and 0.16% (S).
