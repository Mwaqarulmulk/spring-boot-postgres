# Spring Boot + PostgreSQL

[![CI/CD Pipeline](https://github.com/Mwaqarulmulk/spring-boot-postgres/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/Mwaqarulmulk/spring-boot-postgres/actions)
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-waqarulmulk%2Fspringboot--postgres--app-blue)](https://hub.docker.com/r/waqarulmulk/springboot-postgres-app)
[![Java](https://img.shields.io/badge/Java-17-orange)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.1.0-brightgreen)](https://spring.io/projects/spring-boot)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)](https://www.postgresql.org/)

A simple REST API built with Spring Boot and PostgreSQL, packaged with Docker and wired up with a full CI/CD pipeline via GitHub Actions. Great starting point if you want to see how a real DevOps workflow looks end-to-end.

---

## What it does

- Exposes a **Tutorials CRUD API** (`/api/tutorials`)
- Stores data in **PostgreSQL**
- Ships as a **Docker image** pushed to Docker Hub on every merge
- Runs **automated tests and security scans** on every push

---

## Tech used

| Layer | Tools |
|-------|-------|
| Language | Java 17 |
| Framework | Spring Boot 3.1.0 + Spring Data JPA |
| Database | PostgreSQL 15 |
| Containers | Docker, Docker Compose |
| CI/CD | GitHub Actions |
| Security | OWASP Dependency Check, Trivy, Docker Scout |

---

## Getting started

**You'll need:** Docker & Docker Compose installed.

```bash
git clone https://github.com/Mwaqarulmulk/spring-boot-postgres.git
cd spring-boot-postgres
docker-compose up -d
```

That's it. The app starts at **http://localhost:8080** and the database is wired up automatically.

To stop everything:
```bash
docker-compose down
```

### Run locally without Docker

```bash
cd bezkoder-app
mvn spring-boot:run
```

> You'll need a local PostgreSQL instance running. Copy `.env.example` to `.env` and adjust the credentials.

---

## API endpoints

Base URL: `http://localhost:8080`

| Method | Path | What it does |
|--------|------|--------------|
| `GET` | `/api/tutorials` | List all tutorials |
| `GET` | `/api/tutorials/:id` | Get one by ID |
| `POST` | `/api/tutorials` | Create a tutorial |
| `PUT` | `/api/tutorials/:id` | Update a tutorial |
| `DELETE` | `/api/tutorials/:id` | Delete one |
| `DELETE` | `/api/tutorials` | Delete all |
| `GET` | `/api/tutorials/published` | List published ones |
| `GET` | `/actuator/health` | Health check |

**Quick test:**
```bash
curl -X POST http://localhost:8080/api/tutorials \
  -H "Content-Type: application/json" \
  -d '{"title": "Hello", "description": "My first tutorial", "published": true}'
```

---

## CI/CD pipeline

Every push to `main` or `develop` triggers:

1. **Build** — compiles the app and caches Maven deps
2. **Security scan** — OWASP dependency check
3. **Tests** — runs against a real PostgreSQL container
4. **Docker build & push** — multi-stage image pushed to Docker Hub
5. **Container scan** — Trivy + Docker Scout CVE scan
6. **Deploy verification** — confirms the image is pullable

### Required GitHub secrets

Go to **Settings → Secrets → Actions** and add:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

---

## Project layout

```
spring-boot-postgres/
├── .github/workflows/ci-cd.yml   # CI/CD pipeline
├── bezkoder-app/
│   ├── src/                      # Java source code
│   ├── Dockerfile                # Multi-stage Docker build
│   └── pom.xml                   # Maven config
├── scripts/                      # Helper scripts for local testing
├── docker-compose.yml
└── .env.example                  # Copy this to .env
```

---

## Running tests

```bash
cd bezkoder-app
mvn test                          # unit tests
mvn clean test jacoco:report      # with coverage report
```

Coverage report: `target/site/jacoco/index.html`

---

## Troubleshooting

**App won't connect to DB?**
```bash
docker logs postgres-db           # check postgres logs
docker exec postgres-db pg_isready -U postgres
```

**Port 8080 already in use?**
```bash
lsof -i :8080   # find the process, then kill it or change the port
```

**Docker build fails?**
```bash
docker-compose build --no-cache
```

---

## Contributors

- **Waqar ul Mulk** — [@Mwaqarulmulk](https://github.com/Mwaqarulmulk)
- **Ghulam Mujtaba** — [@ghulam-mujtaba5](https://github.com/ghulam-mujtaba5)

PRs are welcome! Fork the repo, make your changes, and open a pull request.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">Made with ❤️ by Waqar ul Mulk — ⭐ star it if it helped you!</div>