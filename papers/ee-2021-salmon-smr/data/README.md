# Data provenance for `ee-2021-salmon-smr`

Source: Zenodo record 5255061, version 1. DOI https://doi.org/10.5281/zenodo.5255061
License: **CC BY 4.0** (`cc-by-4.0` in the Zenodo record metadata)
Authors: Åsheim, Prokkola, Morozov, Aykanat, Primmer (2021)
Downloaded: 2026-10-20 with anonymous `curl` from `https://zenodo.org/api/records/5255061/files/<name>/content`.
Each file's MD5 matches the checksum in the Zenodo API.

The data files in this directory are gitignored. Only this README is committed.

## Data files (`data/`)

| File | Bytes | SHA-256 | Source URL |
|---|---|---|---|
| data-Ash2021-respirometry.txt | 1635924 | deac6d387e99829ccb16bba819fde127d670388f87185eac26b7a14564547ee3 | https://zenodo.org/api/records/5255061/files/data-Ash2021-respirometry.txt/content |
| data-Ash2021-sampled-fish.xlsx | 24135 | f5ef8ac895a88bdb4deb2037f61c677d14fa6020f2f28726edad817fcb48ee6c | https://zenodo.org/api/records/5255061/files/data-Ash2021-sampled-fish.xlsx/content |
| data-Ash2021-genotypes.txt | 2258 | bda6684ee43aee8dedf2af87115679bccba48838fe3796eb566699bc074b60dd | https://zenodo.org/api/records/5255061/files/data-Ash2021-genotypes.txt/content |
| data-Ash2021-tank-densities.txt | 110 | dbb9f9d2b410793b6d14da989cd6547055053f66f6ffaecf8e3da46c7164c3fd | https://zenodo.org/api/records/5255061/files/data-Ash2021-tank-densities.txt/content |
| data-Ash2021-temp-loggers-small-tanks-Dec2020.txt | 7783119 | 6965ab2feded5a7b37619d7cc66c2b2b6222c87f6ac9555cd6347ac3677c4521 | https://zenodo.org/api/records/5255061/files/data-Ash2021-temp-loggers-small-tanks-Dec2020.txt/content |
| README-Ash2021-description-of-files.txt | 4744 | 43bad2f5963bd68d729041a6704a7a31c6699028a0955d6c1c6d3f3ab314718e | https://zenodo.org/api/records/5255061/files/README-%C3%85sh2021-description-of-files.txt/content |

Not downloaded: `data-Ash2021-raw-respirometry.zip` (211,844,070 B, md5 e56446e5200cf7e3d5a53b8ba8da18d1). It holds the raw O2 traces used to extract slopes with FishResp. The processed per-phase file above already contains those slopes and MO2 values. `2-prep-data.R` reads it only for `tb_resp_raw` (descriptive O2-minimum statistics), not for any claim.

## Author code (`code/author/`, CC BY 4.0, same record)

The record also contains `script-Åsh2021-*.R` files. They have the same MD5 as their ASCII-named `script-Ash2021-*.R` twins, so only the ASCII-named copies were downloaded. The scripts are encoded in Windows-1252, not UTF-8.

| File | Bytes | SHA-256 |
|---|---|---|
| script-Ash2021-1-prep-functions.R | 5888 | eee3aa17f85566ab94bebb2de17067d1ed88d1fcd2ce4a18439044a778a75ce0 |
| script-Ash2021-2-prep-data.R | 3001 | 10188c3338330f108be1d0b0417578cc9e1c44e900da449416de8bac937a27f3 |
| script-Ash2021-3-prep-plots.R | 2186 | 32aaa13b24faef629e74506c4296038b0a0b8a110cf5028b37706aa505012fe3 |
| script-Ash2021-4-models-condition.R | 1570 | c28e42571d056558ad64e3d708b319d2359b4e0b7b65b8569a54c84221f1dba9 |
| script-Ash2021-4-models-mo2.R | 4524 | a46ad2930313a653659bac023967dee33a3952a8b56f2741502cebe5df6c69c3 |
| script-Ash2021-4-outputs-various.R | 3766 | 475d6c6d8d9b64573288ba0640e1f168733cd7ff4aaeeec654250491d9978391 |
| script-Ash2021-4-plot_temperature.R | 1763 | 52bf94b0c5c7858898dd0ffd642b13cce00b625a28d341cf702e13cc65b55dd4 |
| script-Ash2021-4-plot-massVsRate.R | 1844 | 649fbab192a8839c6c8b3c8a96fbc16d8824caaa0ad86f2ff6471c95d6741764 |
| script-Ash2021-powerAnalysis.R | 4220 | 985e9e9bdd727cc3e61e767d21530dbfb783e7c6da89dd7ea5e4faa6e66f409f |

Each script is at `https://zenodo.org/api/records/5255061/files/<name>/content`.

`axomatic` (GitHub eiriksen/axomatic) is loaded in `2-prep-data.R`, but the only functions the scripts call from it are `axis_x()` and `axis_y()`. Both are ggplot axis helpers used in plotting code: `4-models-mo2.R` (plo_coeff), `4-plot_temperature.R`, `4-plot-massVsRate.R` and `powerAnalysis.R`. No model or statistic depends on axomatic.

## Paper full text (`paper/fulltext.xml`)

| File | Bytes | SHA-256 | Source URL | License |
|---|---|---|---|---|
| fulltext.xml (JATS) | 165206 | 40012821fef3a267fe32b4eddbebfcb8d8f2a3503c36b5d5c5b29854141d71ae | https://www.ebi.ac.uk/europepmc/webservices/rest/PMC8794721/fullTextXML | CC BY 4.0 |

## Structure (inspected only, no statistics computed)

- `data-Ash2021-respirometry.txt`: tab-separated, 7311 data rows, one per accepted measurement phase per fish. This matches the paper's "N = 7311" slopes. There are 153 distinct `Ind` values. Columns: Chamber.No (`CH1`..`CH16`), Ind (= ID_fish, `batch-Ffamily-Cchamber`), Mass (g), Volume (47.3 ml), DO.unit (`mg O2`), Date.Time (format `(2020-Jul-03 16:25:32)`), Phase (`M5`..), Temp, Slope.with.BR, Slope, SE, R2, MR.abs.with.BR, BR (%), MR.abs (mg O2 h^-1), MR.mass (mg O2 kg^-1 h^-1).
- `data-Ash2021-sampled-fish.xlsx`: sheet 1 is "data - JUNR - sampled fish", with 165 rows (6 blank rows have no batch or family). Columns: ID_sample, family (1–14), ID_fish, chamber (1–16), batch (1–10; batch 2 has 15 fish), weight (g), length_standard (mm), length_fork, date (d.mm.yy, the respirometry end date), use, comment_sampling, comment_analysis. `use` takes the values 1, 0.9, 0.5, 0.2, 0 and blank, and the authors keep `use > 0.5`. Sheet 2 ("batch1") is a scratch sheet with 18 rows and is not used by the code.
- `data-Ash2021-genotypes.txt`: tab-separated, 165 rows. Columns: sex (female/male), geno_vgll3 (EE/LL), ID_sample.
- `data-Ash2021-tank-densities.txt`: 14 rows (tank, n_fish).
- `data-Ash2021-temp-loggers-small-tanks-Dec2020.txt`: tab-separated, 258,365 rows (dateTime, temp, tank). Tank labels are 1–20 and `10_0`. The code keeps tanks 1–14 and dateTime < 2020-07-15.
