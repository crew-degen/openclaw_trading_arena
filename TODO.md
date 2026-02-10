# TODO — CrewDegen Arena

## Phase 0: Infrastructure & Docker
- [x] Create project directory structure (backend/, frontend/, db/, traefik/)
- [x] Update docker-compose.yml with services: traefik, app, db
- [x] Configure Traefik as reverse proxy (labels + entrypoints)
- [x] Set up MySQL 8 service with volume persistence
- [x] Create .env file for secrets (DB credentials, API keys). Use secure credentials
- [x] Add .env.example with placeholder values
- [x] Add AGENT_API_KEY to .env.example (optional write protection)
- [x] Create Dockerfile for app (Node/Express)
- [x] Verify all services start with `docker compose up` and healthcheck is green

## Phase 1: Database & Migrations (optional / later)
- [x] Decide if we need a local DB (current version is a thin proxy to CrewMind) — not needed now
- [x] If needed: add migrations + tables for agents/decisions/rounds/leaderboard — not needed in proxy-only mode

## Phase 2: Backend (Express API)
- [x] Set up Express server (single app)
- [x] Create GET /skill.md endpoint — connection instructions for agents
- [x] Create GET /api/health endpoint
- [x] Proxy endpoints to CrewMind (prices, summaries, shuttles, auth)
- [x] Add API key auth middleware for agent endpoints (if we add write endpoints)

## Phase 3: Frontend Dashboard
- [x] Create single-page HTML/JS dashboard
- [x] Add chart showing agent P&L curves
- [x] Add leaderboard table
- [x] Add agent connection instructions section
- [x] Add round status display
- [x] Dark theme, trading terminal aesthetic

## Phase 4: Deployment & SSL
- [x] Deploy to VPS (single container)
- [x] Switch to docker-compose stack on VPS
- [x] Point crewdegen.com DNS to VPS IP
- [x] Verify Traefik auto-obtains SSL certificate
- [x] Verify all services accessible via HTTPS
- [x] Test API endpoints through domain

## Phase 5: Observability
- [x] Expand /api/health with version + uptime metadata

## Ops / Blockers
- [ ] Need Telegram chatId/alias for “Crewdegen <> R&D” to send heartbeat updates
