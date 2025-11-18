# NFDI4Culture Technology Stack: Deployment & Integration

> **Project Goal:** Deploy and orchestrate the complete NFDI4Culture research data management stack (MediaWiki, Wikibase, OpenRefine, ANTELOPE, Kompakkt) using Docker, demonstrating production-ready infrastructure skills for cultural heritage digitization.

## 🎯 Overview

This project demonstrates the deployment, orchestration, and integration of five interconnected open-source research data management systems used in the NFDI4Culture (National Research Data Infrastructure for Culture) ecosystem:

1. **MediaWiki + Wikibase** - Knowledge graph and semantic data storage
2. **OpenRefine** - Data cleaning and reconciliation
3. **ANTELOPE** - Terminology service and entity linking
4. **Kompakkt** - 3D object visualization and annotation
5. **Integration Layer** - Connecting all systems for end-to-end workflows

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    NFDI4Culture Stack                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Kompakkt    │  │  ANTELOPE    │  │ OpenRefine   │       │
│  │ (3D Viewer)  │  │(Terminology) │  │(Data Clean)  │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                  │                  │                │
│         └──────────────────┼──────────────────┘                │
│                            ▼                                   │
│                 ┌──────────────────────┐                       │
│                 │  MediaWiki+Wikibase  │                       │
│                 │  (Knowledge Graph)   │                       │
│                 └──────────────────────┘                       │
│                                                                │
│  Docker Compose Orchestration | Health Monitoring | Backups   │
└────────────────────────────────────────────────────────────────┘
```

## 📦 Technologies

- **Container Orchestration:** Docker, Docker Compose
- **Knowledge Graphs:** Wikibase, MediaWiki, SPARQL
- **Backend:** Spring Boot (ANTELOPE), Node.js (Kompakkt), PHP (MediaWiki)
- **Frontend:** Vue.js 3 (ANTELOPE), Angular (Kompakkt)
- **Databases:** PostgreSQL, MySQL, MongoDB
- **Data Processing:** OpenRefine reconciliation API

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+ and Docker Compose V2
- 8GB RAM minimum (16GB recommended)
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/nfdi4culture-stack.git
cd nfdi4culture-stack

# Copy environment template and configure
cp .env.example .env
# Edit .env with your passwords and configuration
nano .env

# Start MediaWiki + Wikibase
./mediawiki.sh up -d

# Check status
./mediawiki.sh ps

# View logs
./mediawiki.sh logs -f
```

### Access

- **MediaWiki/Wikibase:** http://localhost:8181/w/index.php
- **OpenRefine:** http://localhost:3333
- **Admin Login:** Use credentials from `.env` (MW_ADMIN_USER / MW_ADMIN_PASS)

### Management Commands

#### MediaWiki/Wikibase
```bash
# Start services
./mediawiki.sh up -d

# Stop services
./mediawiki.sh down

# View logs
./mediawiki.sh logs -f mediawiki

# Execute commands in container
./mediawiki.sh exec mediawiki bash

# Restart services
./mediawiki.sh restart
```

#### OpenRefine
```bash
# Start OpenRefine
./openrefine.sh up -d

# Stop OpenRefine
./openrefine.sh down

# View logs
./openrefine.sh logs -f

# Check status
./openrefine.sh ps
```

## 📖 Documentation

- [Day 1: MediaWiki + Wikibase Setup](./docs/01-mediawiki-wikibase-setup.md)
- [Day 2: OpenRefine Integration](./docs/02-openrefine-setup.md)
- [Architecture Details](./ARCHITECTURE.md) (coming soon)
- [Deployment Guide](./DEPLOYMENT.md) (coming soon)
- [Integration Guide](./INTEGRATION.md) (coming soon)

## 🎬 Demo

[View Demo Video](./demo/demo-video.mp4) - 10-minute walkthrough of the complete system

### End-to-End Workflow Example

1. **Data Preparation (OpenRefine)**: Import messy museum data, reconcile entities to Wikibase
2. **Knowledge Base (Wikibase)**: Store structured metadata with SPARQL queries
3. **3D Upload (Kompakkt)**: Upload 3D cultural objects with Wikibase links
4. **Annotation (ANTELOPE)**: Semantic annotation using external vocabularies
5. **Query (SPARQL)**: Federated queries across local and external data

## 🎓 Skills Demonstrated

✅ **Docker orchestration** of multi-container applications  
✅ **Semantic web** technologies (RDF, SPARQL, Linked Open Data)  
✅ **Microservices** architecture and API integration  
✅ **DevOps** practices (health checks, monitoring, backups)  
✅ **Research data management** workflows  
✅ **Technical documentation** and system administration

## 📝 Project Status

- [x] Project structure created
- [x] MediaWiki + Wikibase deployed with local repositories
- [x] Docker Compose orchestration with environment variables
- [x] First Wikibase item created (Q1: Vincent van Gogh)
- [x] Documentation written (Day 1 complete)
- [ ] OpenRefine configured
- [ ] ANTELOPE integrated
- [ ] Kompakkt deployed
- [ ] End-to-end integration tested
- [ ] Demo video recorded
- [ ] Demo video recorded

## 🤝 Contributing

This project was created as a demonstration of deployment and orchestration skills for research software engineering positions in the NFDI4Culture ecosystem.

## 📄 License

MIT License - See [LICENSE](./LICENSE) for details

## 🔗 References

- [NFDI4Culture](https://nfdi4culture.de/)
- [TIB Open Science Lab](https://www.tib.eu/en/research-development/research-groups-and-labs/open-science)
- [Wikibase](https://wikiba.se/)
- [OpenRefine](https://openrefine.org/)
- [ANTELOPE](https://service.tib.eu/annotation)
- [Kompakkt](https://kompakkt.de/)
