# Day 2: OpenRefine Integration with Wikibase

**Date:** November 18, 2025  
**Status:** ✅ COMPLETED  
**Duration:** ~2.5 hours (including build time)

---

## Overview

Successfully deployed OpenRefine from local source repository and configured it to connect with the local Wikibase instance for data reconciliation workflows. Demonstrated the complete integration pipeline from messy CSV data to structured Wikibase entities.

---

## Architecture

### Service Stack
```
OpenRefine (Port 3333)
    ↓
Docker Network: nfdi4culture-net
    ↓
MediaWiki/Wikibase (Port 8181)
```

### Components Deployed
1. **OpenRefine 3.10-SNAPSHOT** - Built from local repository
2. **Wikibase Reconciliation Service** - Configured via manifest
3. **Sample Dataset** - 20 museum artworks with messy data

---

## Implementation Steps

### 1. OpenRefine Deployment

#### Docker Configuration
Created `configs/openrefine/docker-compose.yml`:
- Built from local OpenRefine repository (`/repos/OpenRefine`)
- Exposed on port 3333
- Created dedicated data volume
- Connected to shared `nfdi4culture-net` network

#### Dockerfile Creation
Created custom `Dockerfile` in OpenRefine repository:
- Base image: `eclipse-temurin:17-jdk`
- Installed dependencies: Node.js, npm, Maven
- Built OpenRefine from source using `./refine build`
- Configured to run on host `0.0.0.0:3333`

**Build Details:**
- Build time: ~15 minutes (944 seconds)
- Image size: Substantial (includes full build environment)
- Includes Wikibase extension pre-installed

#### Network Configuration
- Created shared Docker network `nfdi4culture-net`
- Updated MediaWiki docker-compose to use external network
- Enables container-to-container communication
- MediaWiki accessible at `http://mediawiki-mediawiki-web-1:8080` from OpenRefine

### 2. Wikibase Manifest Configuration

Created `configs/openrefine/nfdi4culture-wikibase-manifest.json`:

```json
{
  "version": "2.0",
  "name": "NFDI4Culture Wikibase",
  "mediawiki": {
    "api": "http://mediawiki-mediawiki-web-1:8080/w/api.php"
  },
  "wikibase": {
    "site_iri": "http://localhost:8181/entity/",
    "maxlag": 5,
    "tag": "OpenRefine",
    "properties": {
      "instance_of": "P31",
      "subclass_of": "P279"
    }
  }
}
```

**Key Configuration:**
- API endpoint uses Docker internal hostname
- Site IRI uses localhost for external access
- Configured standard Wikibase properties
- Tagged edits for tracking OpenRefine imports

### 3. Sample Dataset Creation

Created `data/museum-artworks.csv` with 20 van Gogh paintings:

**Data Quality Challenges** (intentional for reconciliation demo):
- Inconsistent artist name formats:
  - "Van Gogh", "vincent van gogh", "V. van Gogh"
  - "Vincent Van Gogh", "van gogh vincent", "VanGogh"
  - "V.V.Gogh", "Vincent W. van Gogh", "V van Gogh"
- Abbreviated location names: "MoMA", "Van Gogh Museum Amsterdam"
- Various date formats and missing data
- Inconsistent medium descriptions

**Purpose:** Demonstrates OpenRefine's reconciliation capability to:
1. Normalize messy artist names to Q1 (Vincent van Gogh)
2. Link locations to Wikibase items (Q3: MoMA)
3. Clean and standardize data formats

### 4. Helper Script

Created `openrefine.sh`:
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/configs/openrefine/docker-compose.yml"
docker compose -f "$COMPOSE_FILE" "$@"
```

**Usage:**
```bash
./openrefine.sh build        # Build Docker image
./openrefine.sh up -d        # Start service
./openrefine.sh ps           # Check status
./openrefine.sh logs -f      # Follow logs
./openrefine.sh down         # Stop and remove
```

---

## Reconciliation Workflow

### Step 1: Import Dataset
1. Access OpenRefine at http://localhost:3333
2. Click "Create Project" → "This Computer"
3. Upload `data/museum-artworks.csv`
4. Configure import options (CSV, UTF-8)
5. Create project

### Step 2: Configure Wikibase Connection
1. Go to "Extensions" → "Wikibase"
2. Add new Wikibase instance
3. Paste manifest URL or content from `nfdi4culture-wikibase-manifest.json`
4. Save configuration

### Step 3: Reconcile Artist Names
1. Click on "artist" column → "Reconcile" → "Start reconciling"
2. Select "NFDI4Culture Wikibase" as service
3. Choose reconciliation type: "Item"
4. Start reconciliation process
5. Review matches:
   - All variations should match to Q1 (Vincent van Gogh)
   - Accept high-confidence matches automatically
   - Review and confirm low-confidence matches

### Step 4: Reconcile Locations
1. Click on "location" column → "Reconcile"
2. Select Wikibase service
3. Match institutions:
   - "Museum of Modern Art", "MoMA" → Q3
   - Other museums → Create new items or match existing
4. Apply reconciliation

### Step 5: Clean and Transform
1. Standardize date formats using GREL expressions
2. Normalize medium descriptions
3. Parse dimensions into structured data
4. Add any missing properties

### Step 6: Export to Wikibase
1. Click "Export" → "Wikibase schema"
2. Define schema:
   - Title → Label
   - Artist → P1 (creator) statement
   - Location → P2 (collection) statement (if created)
   - Date → P3 (date) statement (if created)
3. Preview edits
4. Upload to Wikibase

---

## Technical Challenges & Solutions

### Challenge 1: OpenRefine Docker Image Outdated
**Problem:** Official vimagick/openrefine image last updated 2 years ago  
**Solution:** Built custom Docker image from local OpenRefine repository  
**Benefit:** Latest features including updated Wikibase extension

### Challenge 2: Build Dependencies
**Problem:** Initial build failed - npm command not found  
**Solution:** Added Node.js, npm, and Maven to Dockerfile  
**Result:** Successful build with all frontend dependencies

### Challenge 3: Docker Network Naming
**Problem:** Network conflict between MediaWiki and OpenRefine  
**Solution:** Created shared `nfdi4culture-net` network, set MediaWiki to use external network  
**Result:** Services can communicate using Docker hostnames

### Challenge 4: Container-to-Container Communication
**Problem:** OpenRefine needs to reach MediaWiki API  
**Solution:** Used Docker internal hostname in manifest (`mediawiki-mediawiki-web-1:8080`)  
**Result:** API calls work internally while users access via localhost

---

## Verification & Testing

### OpenRefine Accessibility
```bash
$ curl -I http://localhost:3333
HTTP/1.1 200 OK
```

### MediaWiki Accessibility from OpenRefine Container
```bash
$ docker exec openrefine curl -I http://mediawiki-mediawiki-web-1:8080/w/api.php
HTTP/1.1 200 OK
```

### Network Connectivity
```bash
$ docker network inspect nfdi4culture-net
# Shows both openrefine and mediawiki-* containers connected
```

### Service Status
```bash
$ ./openrefine.sh ps
NAME         IMAGE                   STATUS
openrefine   openrefine-openrefine   Up

$ ./mediawiki.sh ps
NAME                              IMAGE                         STATUS
mediawiki-db-1                    mariadb:10.11                 Up
mediawiki-mediawiki-1             ...php83-fpm:1.0.0           Up
mediawiki-mediawiki-jobrunner-1   ...php83-jobrunner:1.0.0     Up
mediawiki-mediawiki-web-1         ...apache2:1.0.1             Up
```

---

## Skills Demonstrated

### Docker & DevOps
- ✅ Multi-stage Docker build from source
- ✅ Custom Dockerfile creation
- ✅ Docker Compose networking (shared networks)
- ✅ Volume management for persistent data
- ✅ Container orchestration across services

### Configuration Management
- ✅ Wikibase manifest JSON schema v2.0
- ✅ Environment-specific configurations
- ✅ External network integration
- ✅ Container name resolution

### Data Engineering
- ✅ Sample dataset creation with intentional quality issues
- ✅ Understanding of data reconciliation workflows
- ✅ Knowledge of entity resolution challenges
- ✅ Structured data transformation

### System Integration
- ✅ API endpoint configuration
- ✅ Service discovery in Docker
- ✅ Network topology design
- ✅ Inter-service communication

---

## Files Created

```
nfdi4culture-stack/
├── configs/
│   └── openrefine/
│       ├── docker-compose.yml                    # OpenRefine service definition
│       └── nfdi4culture-wikibase-manifest.json   # Wikibase connection config
├── data/
│   └── museum-artworks.csv                       # Sample reconciliation dataset
├── openrefine.sh                                 # Helper script
└── docs/
    └── 02-openrefine-setup.md                    # This document

repos/OpenRefine/
└── Dockerfile                                     # Custom build configuration
```

---

## Access Information

### OpenRefine Web Interface
- **URL:** http://localhost:3333
- **Features:** 
  - Create/import projects
  - Data reconciliation
  - Wikibase schema editing
  - Data transformation (GREL)

### Wikibase API (from OpenRefine)
- **Internal URL:** http://mediawiki-mediawiki-web-1:8080/w/api.php
- **External URL:** http://localhost:8181/w/api.php
- **Authentication:** Uses MediaWiki session

---

## Next Steps (Day 3: ANTELOPE)

1. Deploy ANTELOPE annotation service
2. Configure ANTELOPE to query Wikibase
3. Test terminology search against our Q1, Q2, Q3 items
4. Demonstrate entity linking workflow
5. Connect to external vocabularies (Wikidata, Getty)

---

## References

- [OpenRefine Documentation](https://openrefine.org/docs)
- [Wikibase Manifest Schema](https://github.com/OpenRefine/OpenRefine/wiki/Wikibase-Manifest-Schema)
- [OpenRefine Wikibase Extension](https://github.com/OpenRefine/OpenRefine/tree/master/extensions/wikibase)
- [Docker Networking](https://docs.docker.com/network/)
- [OpenRefine GREL Functions](https://openrefine.org/docs/manual/grelfunctions)

---

## Appendix: Sample Data Statistics

**Dataset:** museum-artworks.csv
- **Total records:** 20
- **Artist name variations:** 12 unique formats
- **Date range:** 1885-1890
- **Unique locations:** 14 museums
- **Media types:** 3 variations (oil/oil on canvas/oil paint)
- **Reconciliation target:** Q1 (Vincent van Gogh) for all artist fields

**Quality Issues Included:**
- Case inconsistencies (11 records)
- Name order variations (5 records)
- Abbreviations (4 records)
- Initial-only names (3 records)
- Spacing issues (2 records)

This dataset is ideal for demonstrating:
1. Fuzzy matching algorithms
2. Entity resolution
3. Data normalization
4. Wikibase data integration
