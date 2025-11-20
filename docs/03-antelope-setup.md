# Day 3: ANTELOPE Terminology Service + Wikibase Integration

**Date:** November 18, 2025  
**Status:** ✅ COMPLETED  
**Duration:** ~3 hours (repo audit, Docker fixes, configuration, validation)

---

## Overview

Brought the ANTELOPE annotation stack (Spring Boot backend + Vue 3 frontend) online from the local repository and wired its terminology search to the MediaWiki/Wikibase instance deployed on Day 1. The work focused on stabilizing the docker-compose developer workflow, ensuring Node.js tooling exists inside the app container, and making all Wikidata-specific service calls configurable so they can point at the local SPARQL endpoint exposed at `http://localhost:8181/query/sparql`.

---

## Architecture

```
Vue 3 Frontend (Vite, port 9000)
    ↓ REST/WS
Spring Boot Backend (port 8080)
    ↓ (JPA)
PostgreSQL 14.5 (port 5432)
    ↘
JHipster Registry (8761)  ←→  Config Server (native files)

Wikibase stack (Day 1, port 8181)
    ↑
ANTELOPE Terminology Service (configurable SPARQL + entity data endpoints)
```

Key components:

1. **annotationservice-postgresql** – Developer database seeded through Liquibase.
2. **jhipster-registry** – Provides service discovery + config server.
3. **annotationservice-app** – Eclipse Temurin JDK 11 container that runs npm workspaces + Spring Boot dev server.
4. **MediaWiki/Wikibase** – Already running on host port 8181, consumed through the Docker host gateway.

---

## Implementation Steps

### 1. Repository Audit & Docker Fixes

- Verified local repo under `nfdi4culture-stack/repos/annotation-service/` contained both backend and frontend workspaces (mounted via the shared `STACK_REPOS_ROOT` convention).
- Updated `docker-compose-dev.yml` so the `annotationservice-app` container installs `curl`, `nodejs`, and `npm` via `apt-get` **before** running `npm install --workspaces`. This bypasses a 500 error previously encountered with the NodeSource bootstrap script.
- Mounted the entire repository plus `~/.m2` into the container to re-use the host Maven cache.

### 2. Bring Services Online

From the repo root:

```bash
cd repos/annotation-service
docker compose -f docker-compose-dev.yml up -d --build
```

This command:

- Installs JS dependencies, resolves Maven artifacts (`./mvnw dependency:resolve -Pprod`), and finally runs `npm run start:dev` inside the container.
- Starts PostgreSQL (port 5432) and JHipster Registry (port 8761).
- Exposes backend at `http://localhost:8080` and frontend dev server at `http://localhost:9000`.

To confirm the stack:

```bash
cd repos/annotation-service
docker compose -f docker-compose-dev.yml ps
curl -I http://localhost:8080/management/info
curl -I http://localhost:9000
```

### 3. Configure Wikibase Endpoints

To swap Wikidata for the local Wikibase, the following backend changes were made:

| File                                                                                        | Purpose                                                                                                                                |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `backend/src/main/java/org/tib/osl/annotationservice/config/ApplicationProperties.java`     | Added typed `application.wikibase` config (SPARQL endpoint, entity data endpoint, label languages).                                    |
| `backend/src/main/resources/config/application.yml`                                         | Defaulted the fields to Wikidata URLs so prod builds remain unchanged.                                                                 |
| `backend/src/main/resources/config/application-dev.yml`                                     | Pointed the endpoints to the Docker-hosted Wikibase (`http://host.docker.internal:8181/query/sparql` and `/wiki/Special:EntityData/`). |
| `backend/src/main/java/org/tib/osl/annotationservice/service/AnnotationService.java`        | Injected `ApplicationProperties` and configured `EntityRecognition` during `@PostConstruct`.                                           |
| `backend/src/main/java/org/tib/osl/annotationservice/service/EntityRecognition.java`        | Added thread-safe setters/getters for the active endpoints.                                                                            |
| `backend/src/main/java/org/tib/osl/annotationservice/service/HierarchyFetcherWikiData.java` | Replaced hard-coded URLs with the configurable values and added null-safety around SPARQL bindings.                                    |

The developer profile uses the Docker host gateway (`host.docker.internal`) so the container can reach the Wikibase service that is running directly on the host.

### 4. Validation Workflow

1. **Backend health** – `curl -I http://localhost:8080/management/info` returns `200 OK` with the JHipster actuator payload.
2. **Frontend availability** – `curl -I http://localhost:9000` returns `200 OK`, confirming the Vite dev server proxy is active.
3. **Terminology search** – In the frontend UI (`http://localhost:9000`):

   - Enable only the **Wikidata** toggle (or both Wikidata + DBpedia) and run a terminology search for `"Vincent van Gogh"` using the **Terminology Search** mode.
   - Q1/Q2/Q3 items from the local Wikibase appear instantly because all SPARQL queries now travel to `http://localhost:8181/query/sparql`.
   - Expanding an entity reveals the hierarchy fetched via `HierarchyFetcherWikiData`, which now reads labels from the local entity data endpoint instead of Wikidata.

   ![Terminology search showing the Vincent Van Gogh result tree](../screenshots/day3-terminology-search.png)

4. **Entity linking proof** – Switch to the **Entity Linking** tab, keep the example sentence (“Vincent van Gogh was a dutch post-impressionist painter”), and run the default ICONCLASS dictionary. The UI highlights every detected entity fragment and links it to its concept URI.

   ![Entity linking highlighting ICONCLASS hits for the example sentence](../screenshots/day3-entity-linking.png)

5. **External vocabulary mix** – Re-run the terminology search with **Wikidata + DBpedia + ICONCLASS + GND + Getty** toggled on. The results tree proves that ANTELOPE aggregates items from every selected source: blue nodes for Wikidata/DBpedia, yellow nodes for shared types, and grey nodes for GND collections.

   ![Terminology search combining Wikidata, DBpedia, ICONCLASS, GND, and Getty](../screenshots/day3-terminology-external.png)

6. **API spot-check (optional)** –

```bash
curl -X POST "http://localhost:8080/api/annotation/terminology?wikidata=true" \
  -H 'Content-Type: application/json' \
  -d '["Vincent van Gogh"]'
```

Expect the response to include `entities_wikidata` entries referencing `http://localhost:8181/entity/Q1` etc.

---

## Progress Update — ANTELOPE work (Nov 18–20, 2025)

The following summarizes additional work done since Day 3 to make entity-linking tests reproducible locally and to integrate a Vecner-compatible service for ICONCLASS lookups.

- **Test harness:** added and iterated `scripts/test_antelope_api.py` — a small Python test script that exercises `/annotation/status`, `/annotation/terminology`, and `/annotation/entitylinking/text` with a `--verbose` flag to print full responses.

- **Local Vecner wrapper:** implemented `repos/vecNER/antelope_wrapper.py` (Flask) as a lightweight Vecner-compatible service exposing `/entitylinking` and `/visualize`. It supports three paths:

  - Use `ExactMatcher`/`ThresholdMatcher` when a lexicon and model are available.
  - A simple substring fallback matcher when the lexicon is provided but heavy dependencies fail to load.
  - An Iconclass query flow when the backend requests `dict == "iconclass"` or `static_kb_url` contains `iconclass.org`.

- **Docker image & compose:** added a `repos/vecNER/Dockerfile`, pinned `numpy==1.23.5` to avoid binary incompatibilities, pre-downloaded NLTK data, and optionally saved a small gensim KeyedVectors model to `/models/vecner.kv`. The `vecner` service was added to `repos/annotation-service/docker-compose-dev.yml` and the backend environment points `VECNER_SERVICE_URL` to `http://vecner:5000`.

- **Iconclass behavior & canonicalization:** the wrapper queries the Iconclass API and returns candidate `ents` plus an `ids` map. A canonicalization step was added so, when `allowDuplicates=false`, the service emits a single canonical id per token index (normalized, lowercased, with variant suffixes removed).

- **Visualization:** replaced the original list-style visualization with an inline `<mark>`-based renderer in `antelope_wrapper.py` so the HTML returned by `/visualize` more closely matches the reference service (marks with a small `<span>` and a link to the Iconclass entry).

- **Rebuild & test cycle:** rebuilt the `vecner` image multiple times while iterating patches and confirmed via `python3 scripts/test_antelope_api.py --verbose` that:
  - Health and terminology endpoints return 200 OK.
  - `POST /annotation/entitylinking/text` returns `el_result.ents` and a canonical `ids` map when Iconclass is requested.

Quick commands used during development:

```bash
# Rebuild and start only the vecner service
docker compose -f repos/annotation-service/docker-compose-dev.yml up -d --build vecner

# Run the test harness
python3 scripts/test_antelope_api.py --verbose

# Tail vecner logs to inspect behavior
docker compose -f repos/annotation-service/docker-compose-dev.yml logs --tail 200 vecner
```

Notes / next work items:

- Tokenization and `idx` semantics differ between the local wrapper and the reference service; if you need exact parity we should align the tokenizer and word-index calculation.
- The canonicalization heuristic (shortest normalized label) is a lightweight choice for tests; for production parity we should implement ranking by Iconclass relevance or copy the backend's canonicalization logic.
- If you prefer deterministic test output (no external Iconclass calls), I can add a demo mode that returns fixed annotations for the example sentence.

If you want, I can now refine tokenization, adjust canonicalization ranking, or add a deterministic demo mode — tell me which and I'll implement it and run the tests.

---

## Known Issues & Follow-ups

- **Permissions on `/repos/annotation-service/target`** – Run `./scripts/fix-annotation-target-perms.sh` from `nfdi4culture-stack/` whenever Docker-created artifacts lock the directory. The helper script creates the folder if needed and reassigns ownership to the active host user (falling back to `sudo` if direct `chown` fails).
- **Host Gateway Dependency** – The dev profile assumes the Docker host exposes Wikibase on port 8181. Update `application-dev.yml` if the service moves to another host or if you bridge the Docker networks instead.
- **Sass warnings in Vite** – The frontend build emits Sass legacy warnings; they are harmless for Day 3 goals but can be addressed by upgrading the `sass` dependency later.

---

## Next Steps

1. Capture UI screenshots of terminology search + class hierarchy for the final portfolio.
2. Automate permission fixes for the Maven `target` directory (e.g., via a Makefile step).
3. Consider exposing the Wikibase stack through the same Docker network to eliminate the reliance on `host.docker.internal`.
