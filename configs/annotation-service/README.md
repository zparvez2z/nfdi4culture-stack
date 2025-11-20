# ANTELOPE Deployment Helpers

This folder captures the extra artifacts required to launch the ANTELOPE stack without modifying the source repositories directly.

## Files

- `docker-compose-dev.yml`

  - Mirrors the compose definition that was run from `repos/annotation-service` but uses relative paths (`../repos/annotation-service`) so it can be launched from the workspace root.
  - Starts PostgreSQL, the JHipster registry, and the Spring Boot / Vue.js application (it installs Node.js/npm, resolves Maven dependencies, and streams the dev server).

- `postgresql-driver.patch`

  - Adds the missing `org.postgresql:postgresql` dependency that the Spring Boot backend needs for `HikariDataSource`.
  - Apply it by running `git apply configs/annotation-service/postgresql-driver.patch` from the workspace root (the patch assumes the annotated file lives under `repos/annotation-service/backend/pom.xml`).

- `vecner` (local Vecner wrapper)
  - A lightweight Vecner-compatible Flask wrapper lives under `repos/vecNER` in the workspace. It's used by the backend for ICONCLASS entity linking when the `VECNER_SERVICE_URL` environment variable points at it.
  - You can build and run it from the configs compose file (the compose in this folder will build `../repos/vecNER`):

```bash
# Build and start vecner plus the annotation stack (from workspace root)
git apply configs/annotation-service/postgresql-driver.patch
docker compose -f configs/annotation-service/docker-compose-dev.yml up -d --build
```

- The vecner service listens on port `5000` inside the compose network and will be reachable from the backend at `http://vecner:5000` when started via this compose file. The compose file sets `VECNER_SERVICE_URL` for the `annotationservice-app` container to `http://vecner:5000`.

## Usage

```bash
cd /workspaces/nfdi4culture-stack
# ensure the repositories are present under repos/annotation-service
git apply configs/annotation-service/postgresql-driver.patch
docker compose -f configs/annotation-service/docker-compose-dev.yml up -d
```

The compose file exposes ports `8080` (backend), `9000` (frontend dev server), `8761` (JHipster registry), and `5432` (PostgreSQL). A health check endpoint is available at `http://localhost:8080/management/health` after the application starts. Adjust the patch/application workflow if you need to customize the build or skip the dependency install step.
