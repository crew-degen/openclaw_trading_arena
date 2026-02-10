# TODO — CrewDegen Arena

## Rules (read before work)
- [x] Before any task, read /root/projects/hackathon/API.md
- [x] DB changes only via Prisma migrations (no manual SQL)

## Hackathon
- [x] Update Colosseum project description with latest features

## Hotfix Task 1: News/Prices not showing
- [x] Check backend API responses for /api/shuttles/prices and /api/shuttles/summaries on prod
- [x] Check frontend JS load errors (module/visx imports) and fix if blocking data renders
- [x] Ensure BTC fallback chart (visx) loads only when needed and does not block main UI
- [x] Verify layout gap = 15px (no collapse) and redeploy

## Hotfix Task 2: BTC chart not rendering
- [x] Confirm price-history response shape (ticks/created_at) and map correctly
- [x] Render BTC line with visx (yellow, 1px), add end-of-line badge "BTC"
- [x] Add right-side legend "BTC Price"
- [x] Verify chart only shows when no shuttles; redeploy

## Hotfix Task 3: BTC badge with last price
- [x] Format last BTC price and append to badge (e.g., "BTC / $89,012.12")
- [x] Adjust badge width to fit text
- [x] Redeploy and verify

## Hotfix Task 4: Mobile layout for news/market
- [x] Force Latest News + Market Snapshot to stack vertically on <1000px
- [x] Verify on mobile and redeploy

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

## Phase 1: Database & Migrations (Prisma)
- [x] Add Prisma schema (agents, decisions, rounds, leaderboard)
- [x] Generate and commit initial migration
- [x] Apply migrations to DB
- [x] Add decisions.rationale TEXT (per API.md)

## Phase 2: Backend (Express API)
- [x] Set up Express server (single app)
- [x] Create GET /skill.md endpoint — connection instructions for agents
- [x] Create GET /api/health endpoint
- [x] Proxy endpoints to CrewMind (prices, summaries, shuttles, auth)
- [x] Add API key auth middleware for agent endpoints (if we add write endpoints)
- [x] Implement rounds cron + status gating for controllers
- [x] Add tests for round status logic

## Phase 3: Frontend Dashboard
- [x] Cover chart component with tests
- [x] Create single-page HTML/JS dashboard
- [x] Add chart showing agent P&L curves
- [x] Add leaderboard table
- [x] Add agent connection instructions section
- [x] Add round status display
- [x] Show API version/commit on dashboard
- [x] Color-code API status indicator
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
- [x] Add git commit hash to /api/health when available

## Ops / Blockers
- [x] Telegram chatId set (-4810105807) for “Crewdegen <> R&D” updates
