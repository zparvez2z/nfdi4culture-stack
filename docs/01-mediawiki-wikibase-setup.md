# MediaWiki + Wikibase Deployment

## Objective

Deploy MediaWiki with Wikibase extension using local repositories and Wikimedia official development images, demonstrating knowledge graph and semantic web capabilities for the TIB RSE position.

## Architecture

### Services

1. **mediawiki** (PHP-FPM 8.3)

   - Image: `docker-registry.wikimedia.org/dev/bookworm-php83-fpm:1.0.0`
   - Purpose: PHP processing for MediaWiki application
   - Mounts local MediaWiki and Wikibase repositories

2. **mediawiki-web** (Apache 2.4)

   - Image: `docker-registry.wikimedia.org/dev/bookworm-apache2:1.0.1`
   - Purpose: Web server with PHP-FPM proxy
   - Port: 8181
   - Mounts same repositories as mediawiki service

3. **mediawiki-jobrunner**

   - Image: `docker-registry.wikimedia.org/dev/bookworm-php83-jobrunner:1.0.0`
   - Purpose: Background job processing
   - Handles async tasks and maintenance

4. **db** (MariaDB 10.11)
   - Database: `wikibase`
   - User: `wikibase` / `WikiBase2024UserPass`
   - Persistent storage via Docker volume

### Network

- Network: `wikibase-net` (bridge)
- Internal communication between services
- External access: `localhost:8181`

## Implementation Steps

### 1. Repository Preparation

Local repositories used (checked out under `nfdi4culture-stack/repos`):

- `repos/mediawiki` (MediaWiki 1.46.0-alpha)
- `repos/mediawiki-extensions-Wikibase`

> Tip: all helper scripts export `STACK_REPOS_ROOT` to the repository root so Docker Compose resolves these mounts correctly inside Codespaces and local shells. Override `STACK_REPOS_ROOT` if you keep the repos elsewhere.

### 2. Docker Compose Configuration

Created `configs/mediawiki/docker-compose.local.yml` with:

- Volume mounts using **absolute paths** (relative paths failed initially)
- User mapping: `${MW_DOCKER_UID:-1000}:${MW_DOCKER_GID:-1000}`
- Environment variables for database connection
- Shared volumes across mediawiki, web, and jobrunner services

**Key Learning:** Docker volume mounts need the real host path. The compose file now derives it from `STACK_REPOS_ROOT` (defaulting to the workspace root), so the stack works both locally and in Codespaces without editing the file.

### 3. Dependency Installation

```bash
# MediaWiki dependencies (already present in repo)
docker compose exec mediawiki composer install --no-dev --working-dir=/var/www/html/w

# Wikibase dependencies
docker compose exec mediawiki composer install --no-dev --working-dir=/var/www/html/w/extensions/Wikibase
```

Installed 61 packages for Wikibase including:

- DataValues libraries (data-values/\*)
- Serialization (diff/diff, serialization/serialization)
- Semantic web tools (wikimedia/purtle for RDF)
- Graph support (webonyx/graphql-php)

### 4. MediaWiki Installation

```bash
docker compose exec mediawiki php /var/www/html/w/maintenance/install.php \
  --dbtype=mysql --dbserver=db --dbname=wikibase \
  --dbuser=wikibase --dbpass=WikiBase2024UserPass \
  --pass=AdminPassword2024Wiki \
  "NFDI4Culture Wikibase" Admin
```

Generated `LocalSettings.php` with:

- Database configuration
- Admin user: `Admin` / `AdminPassword2024Wiki`
- Enabled skins: Vector (default)
- Server URL initially: `http://localhost` (fixed to `http://localhost:8181`)

### 5. Wikibase Configuration

Added to `LocalSettings.php`:

```php
// Enable Wikibase Repository
wfLoadExtension( 'WikibaseRepository', "$IP/extensions/Wikibase/extension-repo.json" );
require_once "$IP/extensions/Wikibase/repo/config/Wikibase.example.php";

// Basic Wikibase configuration
$wgWBRepoSettings['siteLinkGroups'] = [];
$wgWBRepoSettings['specialSiteLinkGroups'] = [];

// Set the base URI for the repository
$wgWBRepoSettings['conceptBaseUri'] = 'http://localhost:8181/entity/';
```

### 6. Database Schema Update

```bash
docker compose exec mediawiki php /var/www/html/w/maintenance/update.php --quick
```

Created Wikibase tables:

- `wb_changes` - Change tracking
- `wb_id_counters` - Entity ID assignment
- `wb_items_per_site` - Site links
- `wb_property_info` - Property metadata
- `wb_changes_subscription` - Change notification subscriptions
- `wbt_text` - Term storage

### 7. Configuration Fix

Fixed `$wgServer` setting to include port:

```bash
# Changed from: $wgServer = "http://localhost";
# Changed to: $wgServer = "http://localhost:8181";
```

This fixed redirects after login/logout to use correct port.

## First Wikibase Item

Successfully created **Q1: Vincent van Gogh**

- Label: "Vincent van Gogh"
- Description: "Dutch post-impressionist painter"
- URL: http://localhost:8181/wiki/Item:Q1
- Created via Special:NewItem page

## Technical Challenges & Solutions

### Challenge 1: Docker Volume Mounts Not Working

**Problem:** Relative paths in docker-compose volumes (`../../repos/mediawiki`) resulted in empty directories inside containers.

**Solution:** Introduced the `STACK_REPOS_ROOT` convention so compose files compute absolute paths at runtime (defaulting to the stack root). Restarted containers after exporting `STACK_REPOS_ROOT`.

**Result:** MediaWiki files successfully visible in all three containers (mediawiki, mediawiki-web, mediawiki-jobrunner).

### Challenge 2: Composer Dependencies Missing

**Problem:** Wikibase extension requires numerous Composer packages (DataValues, serialization libraries, etc.) that weren't installed.

**Solution:** Ran `composer install` inside the mediawiki container for both MediaWiki core and Wikibase extension.

**Result:** All 61 required packages installed successfully.

### Challenge 3: URL Redirects Using Wrong Port

**Problem:** After login, MediaWiki redirected to `http://localhost/wiki/Main_Page` (port 80) instead of `http://localhost:8181`.

**Solution:** Updated `$wgServer` in LocalSettings.php to include `:8181` port.

**Result:** All redirects now use correct port.

### Challenge 4: URL Rewriting Not Working

**Problem:** Accessing `/wiki/` or `/w/` returned 404 errors.

**Workaround:** Access MediaWiki using full path with query parameters: `/w/index.php?title=Page_Name`

**Status:** Not critical for development/testing. Can be fixed later by configuring Apache rewrite rules properly.

## Testing & Validation

✅ MediaWiki accessible at http://localhost:8181/w/index.php?title=Main_Page  
✅ Admin login successful  
✅ Wikibase extension loaded (Special:NewItem available)  
✅ Database tables created  
✅ First item (Q1) created successfully  
✅ Item display page working with labels and descriptions

## Console Warnings

```
[ERROR] InvalidArgumentException: Setting siteGlobalID is missing from both Repo and Client settings...
```

**Status:** Non-critical. This warning appears because we haven't configured site linking (interwiki links) which requires setting up a Client instance. For a standalone Wikibase repository, this can be ignored.

## Access Information

- **URL:** http://localhost:8181/w/index.php
- **Admin User:** Admin
- **Admin Password:** AdminPassword2024Wiki
- **Database:** MariaDB on `db:3306`
- **DB Name:** wikibase
- **DB User:** wikibase / WikiBase2024UserPass

## Files Created/Modified

1. `nfdi4culture-stack/configs/mediawiki/docker-compose.local.yml`

   - Complete docker-compose configuration
   - 4 services with proper volume mounts

2. `nfdi4culture-stack/.env`

   - Secure alphanumeric passwords
   - Database credentials

3. Local repository files (under `nfdi4culture-stack/repos`):
   - `repos/mediawiki/LocalSettings.php` (generated)
   - `repos/mediawiki/composer.lock` (updated)
   - `repos/mediawiki-extensions-Wikibase/composer.lock` (generated)
   - `repos/mediawiki-extensions-Wikibase/vendor/` (61 packages)

## Development Workflow

This setup follows Wikimedia's official development workflow:

1. **Local repositories mounted as volumes** - Code changes immediately reflected
2. **Composer in container** - All dependencies installed in correct environment
3. **Separate PHP-FPM and web containers** - Mirrors production architecture
4. **Background job runner** - Async processing for change propagation

This approach demonstrates:

- Docker orchestration skills
- Understanding of MediaWiki/Wikibase architecture
- DevOps best practices
- Ability to work with complex multi-service applications

## Next Steps (Day 2)

1. Create additional Wikibase items (Q2, Q3, ...)
2. Create properties (P1, P2, ...)
3. Add statements linking items
4. Deploy OpenRefine for data reconciliation
5. Configure Wikibase reconciliation service

✅ Docker Compose orchestration  
✅ Volume mount debugging  
✅ PHP-FPM + Apache configuration understanding  
✅ Composer dependency management  
✅ MediaWiki/Wikibase architecture knowledge  
✅ Database setup and migration  
✅ Configuration file management  
✅ Troubleshooting and debugging  
✅ Browser automation with Playwright  
✅ Semantic web / knowledge graph concepts

## References

- MediaWiki Development: https://www.mediawiki.org/wiki/MediaWiki
- Wikibase Repository: https://www.mediawiki.org/wiki/Wikibase
- Wikimedia Development Images: https://docker-registry.wikimedia.org/
- Local MediaWiki Repo: nfdi4culture-stack/repos/mediawiki
- Local Wikibase Repo: nfdi4culture-stack/repos/mediawiki-extensions-Wikibase
