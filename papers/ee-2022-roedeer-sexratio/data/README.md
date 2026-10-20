# Data: ee-2022-roedeer-sexratio

Source: Zenodo record 6513932, https://doi.org/10.5281/zenodo.6513932 (cited in the paper's Data Availability Statement).
License: CC BY 4.0 (Zenodo API `metadata.license.id = cc-by-4.0`).
Downloaded 2026-10-20 (anonymous HTTPS). The Zenodo MD5 checksums matched for all three files.
No author code is deposited, so `code/author/` stays empty.

| File | Source URL | Bytes | SHA-256 |
|---|---|---|---|
| Sex_BW.csv | https://zenodo.org/api/records/6513932/files/Sex_BW.csv/content | 211227 | fcacfc6a2cd9688593e0a0ac62e167fc5369286c55118856dbabebb6c5667179 |
| Metafor_roe_sex.csv | https://zenodo.org/api/records/6513932/files/Metafor_roe_sex.csv/content | 5359 | 6420d015eae45e34904639edd2f571998279727a744a2532ea8d825a94d4fa77 |
| Temp_Data_comma_sep.csv | https://zenodo.org/api/records/6513932/files/Temp_Data_comma_sep.csv/content | 7142 | 5f32728a4cbea2e164b4930d9b43446fac581cefbdc943c1fb7e35a783f072ab |

## Structure (inspected only; no statistics computed)

- **Sex_BW.csv**: `;`-separated, CRLF, ASCII. 17,260 data rows. Columns: `Year` (1966–2019, integer), `Sex` (`f` / `m` / `NA`), `Hasl` (height above sea level in m, integer or `NA`). One row per tagged fawn. There is no age column and no location coordinates.
- **Metafor_roe_sex.csv**: `;`-separated, decimal comma, CRLF, **Latin-1** encoding (some author names are mangled). 52 data rows (37 `P` = prenatal, 15 `S` = secondary). Columns: `Author; Country; Location; Year; Pub_Year; N; N_female; Sex ratio (P/S); Habitat condition (F/FF/FI/E); Proportion females; Low_95; High_95; d; d_se; North; Eeast` (sic). The row for Hagen et al. (this study) has N = 12475.
- **Temp_Data_comma_sep.csv**: `;`-separated, decimal comma. 52 rows, `Jahr` 1968–2019. `Temp_BW_<Mon>` holds the monthly mean temperature in °C for Baden-Württemberg and `NDS_BW_<Mon>` holds the monthly precipitation (Niederschlag, presumably mm).
