# Data for cam4-2024-hpd

Paper: Kim MJ, Hong SPD, Park Y, Chae YK. Cancer Medicine 2024;13:e6970. doi:10.1002/cam4.6970 (CC BY 4.0), PMCID PMC10891462.

Data files are gitignored. Re-download them from the URLs below and check the SHA-256.

| File | Source URL | License | Size (bytes) | SHA-256 |
|---|---|---|---|---|
| `updated_extracted_data_HPD_22.08.29.xlsx` | https://ndownloader.figshare.com/files/39557335 (Figshare article 22256557, https://doi.org/10.6084/m9.figshare.22256557) | CC BY 4.0 (Figshare API) | 126259 | `6535d5b38afba2ea4473dea9abb29f00c819824f1ff2fa3cf56472da210b0f3a` |

The Figshare `computed_md5` is `058105fa4c1797ebb1c8a664de398c72`, and the download matches it.

Paper full text (in `../paper/`, not data):

| File | Source URL | License | SHA-256 |
|---|---|---|---|
| `paper/fulltext.xml` | https://www.ebi.ac.uk/europepmc/webservices/rest/PMC10891462/fullTextXML | CC BY 4.0 | `65b842e06b45315daf6108a36adcebdc1f20ee73a76e9294d1070b7ce0f45134` |

## Structure (inspected only; nothing computed)

- Sheet 1, `meta_data_22.02.14_analysis`: 34 rows × 6 columns.
  - `study` (chr): Kim et al appears 4 times, with different years or cohorts.
  - `year` (stored as text).
  - `hpd` (number of HPD events).
  - `total` (number of evaluable patients).
  - `definition`: A, B or C.
  - `histology`: AGC, HCC, NSCLC, RCC, or `mixed or other`.
  - Rows per histology × definition: AGC 2/1/0, HCC 2/0/3, mixed or other 7/3/2, NSCLC 8/1/2, RCC 2/0/1 (A/B/C).
- Sheet 2, `meta_data_22.02.14_analysis-1`: the same 34 studies (`study` has a `^,` suffix, plus `year`, `citation`, `hpd`, `total^`, `category` = definition, `histology`, `citation_1`, and an unnamed column holding author initials for the Kim studies). It ends with an author-entered totals row (558 / 4117). The row order differs a little from Sheet 1 (Wang 2021 is moved). The A/B/C labels are in `category`.
- No author code was deposited.
