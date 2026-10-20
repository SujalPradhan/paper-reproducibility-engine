# Tooling scout: reproducibility engine for Wiley papers

Scouted 2026-10-20. Licences and "last update" dates come from the GitHub API (`license.spdx_id`, `pushed_at`) on that day unless a different source is noted. Rows marked **(live-tested)** were called anonymously from this machine on 2026-10-20.

Licence rule applied: MIT, Apache or BSD means we can reuse with attribution. GPL, custom or no licence means we take ideas only and copy no code.

---

## 1. Ranked shortlist

| Rank | Tool | What | License | Last update | Adapt effort | Pipeline step | Decision | Reason |
|---|---|---|---|---|---|---|---|---|
| 1 | **Europe PMC REST API** (live-tested) | Search, plus `/{PMCID}/fullTextXML` (JATS) and `/{PMCID}/supplementaryFiles` (zip) | Free service. Article text follows the article licence (Wiley OA is mostly CC-BY) | Live service | Low | 1 (paper text, DAS, tables) | **Reuse** | This gets around Wiley's block: `onlinelibrary.wiley.com/doi/pdfdirect/...` returned **403** to a script, while Europe PMC returned the full JATS. The JATS has `<sec sec-type="data-availability-statement">`, 11 `<table-wrap>` tables and `ext-link` DOIs to Zenodo/Dryad. 15,149 OA *Ecol Evol* full texts are in EPMC. |
| 2 | **CORE-Bench task format + evaluator** (`siegelz/core-bench`) | Task JSON (prompt + question→value results, repeated over runs) and a scorer that uses a 95% prediction interval | MIT | 2025-11-23 | Low | 4 + 6 (tolerance check, task packaging) | **Reuse** | It is already a claims-as-questions format with a numeric tolerance rule. Mirror the schema and copy `eval_result_json` (about 60 lines). |
| 3 | **PaperBench rubric format** (`openai/frontier-evals`, `project/paperbench`) | Hierarchical weighted rubric tree (`rubric.json`) with binary leaves and categories; LLM judge | MIT | 2026-10-12 | Low (format) / High (their harness) | 5 + 6 (audit rubric, task rubric) | **Adapt** | Copy the `TaskNode` JSON schema and the category questions. Do not run their nanoeval/GPU container harness. |
| 4 | **Zenodo REST API** (live-tested) | `GET /api/records/{id}` gives a file list with `links.self` (`.../files/{key}/content`) | Service. Code is GPL-2 (not needed) | Live | Low | 2 (fetch) | **Reuse** (plain REST) | Anonymous download works (HTTP 206). Rate-limit header showed `x-ratelimit-limit: 133`. |
| 5 | **Figshare API v2** (live-tested) | `GET api.figshare.com/v2/articles/{id}` gives `files[].download_url` | Docs CC0. Service is free | Docs 2026-10-08 | Low | 2 | **Reuse** (plain REST) | Anonymous download works (206 via `ndownloader.figshare.com`). |
| 6 | **Dryad API v2** (live-tested) | `/api/v2/datasets/{doi}` → `/versions/{id}/files` → `/files/{id}/download` | Service. dryad-app code MIT | 2026-10-19 | Low–Med | 2 | **Reuse, with token** | **Downloads need a token.** Metadata is anonymous (200), but file download and dataset zip returned **401** `"Unauthorized, must have current bearer token"`. The web `file_stream` URL returned 403. Anonymous limit is 30 req/min with a lower limit on downloads; an API account allows up to 120/min. Tokens last 10 h (client_credentials). **Action: create an API account today** (ORCID login → *My account* page). |
| 7 | **Crossref REST API** (live-tested) | DOI metadata, `link[]`, `relation` (is-supplemented-by), licence | Service. Metadata is CC0 | Live | Low | 1 (metadata, sanity) | **Reuse** | Polite pool via `?mailto=` gave `x-rate-limit-limit: 10` per 1 s. `relation` is often empty for Wiley, so the JATS DAS is the main route to data DOIs. |
| 8 | **GEOquery (R)** | Fetch GEO series/platforms into Bioconductor objects | MIT + file LICENSE (DESCRIPTION, `devel`) | 2026-10-16 | Low | 2 (GEO) | **Reuse** | Most health/omics authors' R code already calls `getGEO()`. Maintained. |
| 9 | **GEOparse (Python)** | Parse GEO SOFT files | BSD-3-Clause | 2024-07-27 | Low | 2 (GEO) | **Reuse (fallback)** | Stale but simple. GEO FTP is reachable anonymously (206 from `ftp.ncbi.nlm.nih.gov/geo/series/...`). |
| 10 | **uv** | Fast Python env/lockfile manager (`uv venv`, `uv pip install -r`, `uv run`) | Apache-2.0 | 2026-10-20 (0.9.1 released 2026-08-04) | Low | 3 (env) | **Reuse** | One command per paper environment, takes seconds. |
| 11 | **renv** | R project lockfiles (`renv::restore()`, `renv::snapshot()`) | MIT | 2026-10-17 | Low | 3 (env) | **Reuse** | Use it when the authors ship `renv.lock`; otherwise snapshot our own for the audit trail. |
| 12 | **rocker images** (`rocker/r-ver:<ver>`, `rocker/tidyverse`) | Version-pinned R Docker images with dated CRAN snapshot (P3M) | GPL-2 (image build scripts). Using the images is fine | 2026-10-15 | Low | 3 (env, R) | **Reuse images** (don't copy scripts) | `FROM rocker/r-ver:4.x.y` pins R and the CRAN date. Pulling images carries no licence obligation for our code. |
| 13 | **pdfplumber** | Text, words and tables from PDFs | MIT | 2026-10-15 | Low | 1 (fallback for supplements/PDF-only) | **Reuse** | Pure-Python with no Java/Ghostscript. Only needed when there is no JATS. |
| 14 | **GROBID** (+ `grobid_client_python`) | PDF → TEI XML (sections, refs, figures, tables) | Apache-2.0 (both) | 2026-10-20 / 2026-10-16. Release 0.9.1 (2026-04-23 per release API) | Med (Docker service) | 1 (fallback) | **Adapt / optional** | Strong, but it means a Java/Docker service. JATS from EPMC makes it unnecessary for the OA demo set. |
| 15 | **camelot** | Lattice/stream PDF table extraction | MIT | 2026-10-14 | Med | 1 (fallback) | **Drop for demo** | pdfplumber covers it with fewer dependencies (Ghostscript/opencv). |
| 16 | **CORE-Agent** (AutoGPT-CORE in `core-bench/agents/`) | GPT-4o agent scaffold tuned for CORE-Bench | MIT (inside core-bench; AutoGPT fork carries its own LICENSE) | 2025-11-23 | High | 3 | **Ideas only** | The authors say CORE-Bench is "solved" by Opus 4.5 + Claude Code scaffold (HAL leaderboard paused). Use Claude Code directly. Prompt-tier ideas (easy/medium/hard) are worth copying. |
| 17 | **statcheck (R)** | Regex-extracts APA test stats (t, F, χ², r, z) and recomputes p | **GPL-3** | 2026-07-03 | Low | 1/4 (consistency check) | **Ideas only** | GPL. Reimplement the idea in about 40 lines of scipy: recompute p from (stat, df) and flag mismatches. |
| 18 | **statcheck_python** (`hplisiecki`) | Python port of statcheck | **GPL-3.0** | 2025-09-17 | Low | 1/4 | **Ideas only** | GPL and small. Same plan as above. |
| 19 | **RunThePaper / PRAgent** (`xi-zhao/RunThePaper`) | Library of independently reproduced papers (physics) with `outputs/checks/target_checks.json` | Code MIT (`LICENSE-CODE`), content CC-BY-4.0 | 2026-10-14 | Med | 4/5 (check records) | **Ideas only → Adapt schema** | Good model for a per-claim evidence record (`schema_version`, `paper_id`, `status`, parameters, paper vs reproduced values, explicit "reproduction boundaries"). Domain is physics, not ecology. |
| 20 | **OpenAlex API** (live-tested) | Works/authors/OA locations | Data CC0. Since Feb 2026 the API is metered: about $0.10/day keyless, $1/day with a free key. Single-DOI lookups are free | Live | Low | 1 (paper discovery, OA status) | **Reuse (light)** | Good for building the candidate paper list (`best_oa_location`, `is_oa`). Its `pdf_url` points to Wiley `pdfdirect`, which is blocked, so use it for metadata only. Library `pyalex` is MIT (2026-10-05). |
| 21 | **repo2docker** | Build Docker image from repo conventions (`requirements.txt`, `environment.yml`, `install.R`, `runtime.txt`) | BSD-3-Clause | 2026-10-05 (release 2026.04.0) | Med | 3 (env) | **Ideas only for demo** | Heavy (Jupyter image, slow builds). We borrow its file-detection order in our env-detect script. |
| 22 | **AutoExperiment** (`j1mk1m/AutoExperiment`, ICLR 2026) | Paper + repo with *n* functions masked → agent re-implements → compare to results of the original code | **No licence** | 2025-09-19 | High | 3/6 (difficulty knob) | **Ideas only** | Progressive masking is a clean way to give one claim several difficulty tiers. |
| 23 | **PRBench** (arXiv 2603.27646, Mar 2026) | 30 physics paper-reproduction tasks, agentic grading. Best agent 34% mean, 0% end-to-end | Paper CC-BY-4.0. No code repo found | 2026-03 | n/a | 5/6 | **Ideas only** | Shows the "fabricated output data" failure mode, so our audit must re-run code rather than trust reported numbers. |
| 24 | **Replica / Faraday** ("Training AI Scientists to Replicate Research", arXiv 2608.13331, Aug 2026) | 310 figure-replication tasks from 100 papers, auto-generated per-task rubric judge, RL-trained 27B agent | Paper only. No public repo found | 2026-08 | n/a | 6 (rubric design) | **Ideas only** | Their rubric rewards faithful scale-downs and penalises hard-coded outputs and look-alike plots. Add those as rubric leaves. |
| 25 | **MLR-Bench / MLR-Agent** (`chchenhui/mlrbench`) | 201 open-ended ML research tasks from workshops, MLR-Judge | MIT | 2026-09-08 | High | none | **Drop** | Open-ended research generation, not reproduction of fixed claims. |
| 26 | **Sakana AI Scientist v1/v2** | End-to-end idea → experiment → paper | Custom "AI Scientist Source Code License" (RAIL-based) | 2025-12-19 | High | none | **Drop** | Wrong problem (generation, not verification). Restrictive custom licence. |
| 27 | **Paper2Code / PaperCoder** (`going-doer/Paper2Code`) | Multi-agent plan → analyse → code from an ML paper | Apache-2.0 | 2026-03-25 | Med | 3 (script-from-methods) | **Ideas only** | Its plan→analysis→code prompt staging is a useful template when no author code exists. Too ML-specific to run as is. |
| 28 | **paper2code agent skill** (`PrathamLearnsToCode/paper2code`) | SKILL.md that turns an arXiv paper into an implementation | MIT | 2026-04-03 | Low | 3 | **Adapt (prompt ideas)** | Closest existing "paper reproduction" skill. Its prompts are arXiv/ML-oriented. |
| 29 | **K-Dense `claude-scientific-skills`** | 140+ Claude skills (statsmodels, pydeseq2, scikit-survival, `database-lookup`, `peer-review`, …) | MIT | 2026-10-19 | Low | 3 (stats helpers) | **Adapt (optional)** | Drop-in skills for the methods we will re-run (GLMs, survival, DESeq2). Nothing reproduction-specific. |

Not found or not usable: a public "CORE-Agent" repo separate from `core-bench/agents/AutoGPT-CORE`; a public Replica/PRBench code repo; a dedicated paper-reproduction Claude skill outside the two listed above.

---

## 2. Reuse plan (24-hour build, Python + R)

### Copy (verbatim, with attribution)
1. **CORE-Bench `eval_result_json`** (`benchmark/evaluations.py`, MIT). This is the numeric scorer:
   - Numeric answers are correct if they fall inside the 95% prediction interval `mean ± t(0.975, n-1) · sd · sqrt(1 + 1/n)` over *n* ground-truth runs.
   - Strings are compared by case-insensitive exact match, and lists by exact match.
   - We wrap it with our **pre-registered tolerance** (abs/rel). Rule: `pass = within_PI OR |x − paper| ≤ max(abs_tol, rel_tol·|paper|)`. This matters because a deterministic R script gives `sd = 0`, which collapses the PI to an exact match.
2. **PaperBench `TaskNode` schema** (`paperbench/rubric/tasks.py`, MIT): the field names, the three `task_category` values with their judge questions, and the fine-grained categories. We copy the JSON shape and the category question strings, not the OpenAI-client code.

### Adapt (thin wrappers we write over tools we reuse)
3. **`fetch_paper.py`**: DOI → (OpenAlex/EPMC search) PMCID → `fullTextXML` + `supplementaryFiles`. Parse with `lxml`:
   - `sec[@sec-type="data-availability-statement"]` gives the DAS text plus `ext-link/@xlink:href`.
   - `table-wrap` gives the tables, written out as CSV.
   - Fallback when the paper is not OA in PMC: pdfplumber on a PDF the user supplies.
4. **`fetch_data.py`**: route on DOI prefix.
   - `10.5281/zenodo.*` → Zenodo `/api/records/{id}`.
   - `10.6084/m9.figshare.*` → Figshare `/v2/articles/{id}`.
   - `10.5061/dryad.*` → Dryad v2 with Bearer token.
   - `GSE*` → GEOquery (R) / GEOparse.
   - `osf.io/*` → OSF API v2 `/v2/nodes/{id}/files/osfstorage/` (not live-tested; public nodes are anonymous per OSF docs).

   Every downloaded file gets a SHA-256 checksum, and each fetch writes a `manifest.json`.
5. **`env.sh`** (detection order borrowed from repo2docker):
   - `renv.lock` → `renv::restore()` inside `rocker/r-ver:<R version from lock>`.
   - `requirements.txt` / `pyproject.toml` → `uv venv && uv pip install -r`.
   - `install.R` / `DESCRIPTION` → `Rscript install.R`.
   - Nothing found → our pinned default image.
6. **Claim extractor**: an LLM over the JATS sections and tables gives `{claim_id, text, value, unit, location (section/table/cell), stat_type}`. A **statcheck-style check** (our own scipy code, inspired by GPL statcheck) recomputes p from `t(df)=x`, `F(df1,df2)=x`, `χ²(df)=x` and flags internal inconsistencies before any re-run.
7. **Audit rubric**: a PaperBench-style tree per claim with leaves for *data fetched + checksum*, *code ran (Code Execution)*, *value within tolerance (Result Analysis)*, plus Replica-style anti-cheat leaves (*no hard-coded output*, *uses the paper's data, not a synthetic substitute*), graded by a second independent agent.
8. **Check record**: model it on RunThePaper `target_checks.json`, with `status`, the paper value, the reproduced value and explicit boundaries/limitations.

### Build ourselves
- Orchestrator (one Python CLI: `paper → claims → fetch → env → run → compare → audit → package`).
- Tolerance pre-registration file (`tolerances.yaml`, frozen and hashed before any run).
- Packager that writes **CORE-Bench-compatible** `task.json` plus a **PaperBench-compatible** `rubric.json` per verified claim (see §3).
- Small HTML/Markdown report for the pitch.

### Skip for the demo
GROBID (Docker/Java), camelot, repo2docker builds, AI Scientist, MLR-Bench, the PaperBench/nanoeval harness, CORE-Agent.

### Risks to flag now
- **Dryad needs a token for every file download.** Create the API account before starting.
- Europe PMC full text exists only for the OA/PMC subset. Pick demo papers from `OPEN_ACCESS:y AND IN_EPMC:y` (e.g. *Ecology and Evolution*).
- OpenAlex keyless budget is $0.10/day. Use DOI lookups, which are free, or get a free key.
- Crossref: send `mailto` and stay under 10 req/s.

---

## 3. Task format

### 3a. CORE-Bench task format (source: `siegelz/core-bench`, `benchmark/dataset/core_train.json` + `benchmark/benchmark_prompts.json` + `benchmark/evaluations.py`, MIT)

**Dataset file**: a JSON array of task objects. `core_train.json` has 45 objects (CS 19, Social Sciences 14, Medical Sciences 12). The test set is shipped GPG-encrypted (`core_test.json.gpg`) to avoid contamination. Each object:

| Field | Type | Meaning |
|---|---|---|
| `field` | str | `"Computer Science"` / `"Social Sciences"` / `"Medical Sciences"` |
| `language` | str | `"Python"` or `"R"` |
| `capsule_title` | str | Paper/capsule title |
| `capsule_id` | str | e.g. `"capsule-9168639"`. The agent's working dir is a capsule of this name (CodeOcean layout: `code/`, `data/`, `results/`, `environment/`, README/REPRODUCING.md) |
| `task_prompt` | str | What to run, inserted into the difficulty template |
| `results` | list[dict] | **One dict per independent ground-truth run** (≥3 runs). Keys are the questions (str), values are the answers (number / str / list). A key containing `"fig"` marks a vision question that needs a figure or table to be read |
| `capsule_doi` | str | Code Ocean DOI |

**Difficulty templates** (`benchmark_prompts.json`). `{task_prompt}` and `{json_fields}` (the question keys) are substituted in:
- `codeocean_easy`: results are already in `results/`; "You should not actually run or execute any code".
- `codeocean_medium`: run per `REPRODUCING.md` (environment/Dockerfile provided).
- `codeocean_hard`: "install all of the requirements found in the Readme file and then run the commands".
- All three: "Save your report to a file named `report.json` … whose keys are the questions and values are the answers."

**Agent output**: `report.json` = `{ "<question>": <answer>, ... }`.

**Scoring** (`eval_result_json`):
- Numeric: correct if inside the 95% prediction interval over the `results` runs. A `"%"` is stripped and the value cast to float.
- String: case-insensitive exact match. List: exact match.
- The function returns counts of correct/total written and vision questions. The paper counts a task as solved only if *all* its questions are correct.

**Minimal example** (verbatim from `core_train.json`, an R task in medicine):
```json
{
  "field": "Medical Sciences",
  "language": "R",
  "capsule_title": "Research Ethics Committees as an intervention point to promote a priori sample size calculations",
  "capsule_id": "capsule-9168639",
  "task_prompt": "Run the analysis.Rmd file using Rscript and output the results in the 'results' directory.",
  "results": [
    {"fig Report Institutions Sampled for US in Table 1.": 19,
     "fig Report Institutions Sampled for UK in Table 1.": 14},
    {"fig Report Institutions Sampled for US in Table 1.": 19,
     "fig Report Institutions Sampled for UK in Table 1.": 14},
    {"fig Report Institutions Sampled for US in Table 1.": 19,
     "fig Report Institutions Sampled for UK in Table 1.": 14}
  ],
  "capsule_doi": "https://doi.org/10.24433/CO.0124369.v1"
}
```
A Python example from the same file has `results[i] = {"Report the average AUC score of Had using the CTGCN-C method on the UCI dataset.": 0.93757}` with three runs (0.93757, 0.93724, 0.93195). The run-to-run spread sets the tolerance.

### 3b. PaperBench rubric format (source: `openai/frontier-evals`, `project/paperbench/`, MIT)

**Per-paper directory**: `data/papers/<paper-id>/`:
- `config.yaml` (`id`, `title`)
- `paper.pdf`, `paper.md`
- `addendum.md`: author clarifications given to the agent
- `judge.addendum.md`: judge-only notes; optional
- `blacklist.txt`: URLs the agent may not visit, e.g. the authors' repo
- `assets/`
- `rubric.json`

**`rubric.json`**: a recursive tree of `TaskNode` objects. Every node has exactly these 6 keys:

| Field | Type | Rules |
|---|---|---|
| `id` | str (UUID) | unique |
| `requirements` | str | natural-language criterion. The root is `"Reproduce the paper \"<title>\""` |
| `weight` | int ≥ 0 | relative importance among siblings |
| `sub_tasks` | list[TaskNode] | empty means leaf |
| `task_category` | str or null | **required on leaves, null on internal nodes**. One of `"Code Development"`, `"Code Execution"`, `"Result Analysis"` |
| `finegrained_task_category` | str or null | one of `"Environment & Infrastructure Setup"`, `"Dataset and Model Acquisition"`, `"Data Processing & Preparation"`, `"Method Implementation"`, `"Experimental Setup"`, `"Evaluation, Metrics & Benchmarking"`, `"Logging, Analysis & Presentation"` |

**Judge question per leaf category** (verbatim from `tasks.py`):
- Code Development: "Does the code in the submission contain a correct implementation of this? …"
- Code Execution: "Does running the reproduce.sh script lead to this being successfully executed?"
- Result Analysis: "Did the reproduce.sh script execution produce evidence that agrees with these results?"

**Scoring**: each leaf is graded 0/1 by the LLM judge, and each parent's score is the weighted mean of its children's scores. The root score is the replication score. The agent's submission is a repo with `reproduce.sh`, which is re-executed in a fresh container before grading.

The real `pinn` rubric has 2,551 nodes. Leaves split into 1,815 Code Execution, 126 Code Development and 22 Result Analysis. One real root → leaf path:
```json
{"id": "fb064013-c6f9-4e60-a49a-edf142baeb10",
 "requirements": "Reproduce the paper \"Challenges in Training PINNs: A Loss Landscape Perspective\"",
 "weight": 1, "task_category": null, "finegrained_task_category": null,
 "sub_tasks": [
  {"id": "62362fae-50bc-4079-82cc-61efb02c9b29",
   "requirements": "The results of Table 3 have been reproduced",
   "weight": 1, "task_category": null, "finegrained_task_category": null,
   "sub_tasks": [
    {"id": "e7d45c85-3ec6-4f44-9d34-a22b27ed1561",
     "requirements": "The measured per-iteration wall-clock times show that NNCG is slower than L-BFGS across all problem domains by at least 5x",
     "weight": 2, "task_category": "Result Analysis",
     "finegrained_task_category": "Logging, Analysis & Presentation",
     "sub_tasks": []}]}]}
```

### 3c. What our packager should emit (one directory per verified claim)
```
tasks/<doi-slug>__<claim_id>/
  task.json        # CORE-Bench object + our extension fields (below)
  rubric.json      # PaperBench TaskNode tree (3–6 leaves)
  inputs/          # fetched data (or a fetch manifest with DOIs + SHA-256)
  addendum.md      # clarifications (PaperBench-style)
  blacklist.txt    # authors' code URL for "hard" tier
```
`task.json` = CORE-Bench keys (`field`, `language`, `capsule_title`, `capsule_id`, `task_prompt`, `results` [≥3 runs], `capsule_doi`→paper DOI) **plus** `difficulty` (`easy|medium|hard`, as in CORE-Bench; optional AutoExperiment-style `masked_functions`), `paper_value`, `tolerance` (`{"abs":…, "rel":…, "rule":"PI95_or_tol"}`, pre-registered with hash), `source_location` (section/table/cell in JATS), `data_sources` (DOI, URL, SHA-256), `env` (`rocker/r-ver:4.x` + `renv.lock`, or `uv.lock`), `audit` (status, auditor id, timestamp). The only question key in `results` is the claim prompt itself, e.g. `"Report the slope of log body mass on latitude (Table 2, model 3)."`. Leaves in `rubric.json`: Dataset and Model Acquisition (correct DOI + checksum), Code Execution (script runs), Result Analysis (value within tolerance), Result Analysis (no hard-coded value, which is the Replica idea), Logging (reports units/CI).

---

## 4. Attribution (things we may copy)

| What we copy | From | License | URL |
|---|---|---|---|
| Task JSON schema, difficulty prompt templates, `eval_result_json` prediction-interval scorer | CORE-Bench (Siegel et al., 2024) | MIT, © 2024 Zachary Siegel | https://github.com/siegelz/core-bench |
| `rubric.json` TaskNode schema, task-category names and judge questions, per-paper dir layout | PaperBench (OpenAI, 2025) | MIT | https://github.com/openai/frontier-evals/tree/main/project/paperbench |
| Check-record schema idea (`target_checks.json`) | RunThePaper | Code MIT, content CC-BY-4.0 | https://github.com/xi-zhao/RunThePaper |
| Prompt staging (plan → analyse → code) | Paper2Code | Apache-2.0 | https://github.com/going-doer/Paper2Code |
| Skill prompt ideas | paper2code skill | MIT | https://github.com/PrathamLearnsToCode/paper2code |
| Optional stats skills | K-Dense claude-scientific-skills | MIT | https://github.com/K-Dense-AI/claude-scientific-skills |
| Libraries used as dependencies | uv (Apache-2.0), renv (MIT), pdfplumber (MIT), GEOparse (BSD-3), GEOquery (MIT), pyalex (MIT), GROBID (Apache-2.0, optional), lxml (BSD) | as listed | GitHub links in §5 |
| Docker base images (used, not copied) | rocker-versioned2 | GPL-2 build scripts; images used as-is | https://github.com/rocker-org/rocker-versioned2 |
| Article full text (data, not code) | Europe PMC OA subset | Per article (Wiley OA: mostly CC-BY 4.0). Cite each paper | https://europepmc.org/RestfulWebService |

**Ideas only, copy no code:** statcheck (GPL-3), statcheck_python (GPL-3), AutoExperiment (no licence), AI Scientist (custom RAIL-based licence), Zenodo server code (GPL-2), PRBench / Replica (papers only).

---

## 5. Sources

Benchmarks and agents
- CORE-Bench repo: https://github.com/siegelz/core-bench (files read: `benchmark/dataset/core_train.json`, `benchmark/benchmark_prompts.json`, `benchmark/evaluations.py`, `LICENSE`)
- CORE-Bench paper: https://arxiv.org/abs/2409.11363 · HAL leaderboard (paused, "solved"): https://hal.cs.princeton.edu/corebench_hard · author note: https://substack.com/@sayash/note/c-183913356
- PaperBench: https://github.com/openai/frontier-evals/tree/main/project/paperbench (files read: `paperbench/rubric/tasks.py`, `README.md`, `data/papers/pinn/{config.yaml,addendum.md,rubric.json}`) · paper https://arxiv.org/abs/2504.01848
- AutoExperiment: https://arxiv.org/abs/2506.19724 · https://github.com/j1mk1m/AutoExperiment
- PRBench: https://arxiv.org/abs/2603.27646
- Replica / Faraday: https://arxiv.org/abs/2608.13331
- RunThePaper: https://github.com/xi-zhao/RunThePaper
- MLR-Bench: https://github.com/chchenhui/mlrbench
- Sakana AI Scientist: https://github.com/SakanaAI/AI-Scientist · https://github.com/SakanaAI/AI-Scientist-v2
- Paper2Code: https://github.com/going-doer/Paper2Code · paper2code skill: https://github.com/PrathamLearnsToCode/paper2code · K-Dense skills: https://github.com/K-Dense-AI/claude-scientific-skills

Data APIs
- Dryad API docs (in repo): https://github.com/datadryad/dryad-app/tree/main/documentation/apis (`README.md`, `api_accounts.md`) · https://datadryad.org/api (rate limits: 30/min anon, up to 120/min with account)
- Zenodo REST API: https://developers.zenodo.org/
- Figshare API: https://docs.figshare.com/ · https://github.com/figshare/user_documentation
- Europe PMC REST: https://europepmc.org/RestfulWebService
- Crossref REST: https://api.crossref.org/swagger-ui/index.html
- OpenAlex auth/pricing: https://developers.openalex.org/api-reference/authentication · https://docs.openalex.org/how-to-use-the-api/rate-limits-and-authentication
- OSF API v2: https://developer.osf.io/
- GEOquery: https://github.com/seandavi/GEOquery · GEOparse: https://github.com/guma44/GEOparse

Extraction and environments
- GROBID: https://github.com/kermitt2/grobid · client: https://github.com/kermitt2/grobid_client_python
- pdfplumber: https://github.com/jsvine/pdfplumber · camelot: https://github.com/camelot-dev/camelot
- statcheck: https://github.com/MicheleNuijten/statcheck · statcheck_python: https://github.com/hplisiecki/statcheck_python
- uv: https://github.com/astral-sh/uv · renv: https://github.com/rstudio/renv · rocker: https://github.com/rocker-org/rocker-versioned2 · repo2docker: https://github.com/jupyterhub/repo2docker

Live tests (2026-10-20, anonymous, UA with mailto)
- Dryad `GET /api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7` → 200. `GET /api/v2/files/94868/download` → 401. `GET .../datasets/.../download` → 401. Web `file_stream` → 403.
- Zenodo `GET /api/records/7116024` → 200, file `.../content` → 206.
- Figshare `GET /v2/articles/1000000` → 200, `ndownloader` → 206.
- Europe PMC `PMC12434340/fullTextXML` (*Ecol Evol*, 10.1002/ece3.72157) → 200 JATS with `sec-type="data-availability-statement"` linking Zenodo 10.5281/zenodo.16762445. `/supplementaryFiles` → 200 zip (5.5 MB).
- Wiley `onlinelibrary.wiley.com/doi/pdfdirect/10.1002/ece3.72157` → 403.
- Crossref → 200 (`x-rate-limit-limit: 10`/1s). OpenAlex DOI lookup → 200 ($0 cost). GEO FTP SOFT → 206.
