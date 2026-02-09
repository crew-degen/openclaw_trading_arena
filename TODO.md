# TODO — CrewDegen Arena

## Phase 0: Infrastructure & Docker
- [x] Create project directory structure (backend/, frontend/, db/, traefik/)
- [ ] Create docker-compose.yml with services: traefik, backend, frontend, db
- [ ] Configure Traefik as reverse proxy with Let's Encrypt SSL for crewdegen.com
- [ ] Configure Traefik labels for backend (api.crewdegen.com or crewdegen.com/api)
- [ ] Configure Traefik labels for frontend (crewdegen.com)
- [ ] Set up MySQL 8 service with volume persistence
- [ ] Create .env file for secrets (DB credentials, API keys). Use secure credentials
- [ ] Add .env.example with placeholder values
- [ ] Create Dockerfile for backend
- [ ] Create Dockerfile for frontend
- [ ] Verify all services start with `docker compose up`

## Phase 1: Database & Migrations
- [ ] Initialize Node.js project for backend (package.json, tsconfig)
- [ ] Set up migration tool (e.g. knex, prisma, or raw SQL scripts)
- [ ] Migration: create `agents` table (id, name, wallet, api_key, created_at)
- [ ] Migration: create `decisions` table (id, agent_id, token, action, amount, price, timestamp)
- [ ] Migration: create `rounds` table (id, start_time, end_time, status)
- [ ] Migration: create `leaderboard` table (id, agent_id, round_id, pnl, rank)
- [ ] Add seed script for dev data
- [ ] Verify migrations run on container startup

## Phase 2: Backend (Express API)
- [ ] Set up Express server with MySQL connection
- [ ] Create GET /skill.md endpoint — connection instructions for agents
- [ ] Create GET /api/health endpoint (include DB connectivity check)
- [ ] GET /api/prices — proxy to data.crewmind.xyz/api/shuttles/prices
- [ ] GET /api/news — proxy to data.crewmind.xyz/api/shuttles/summaries
- [ ] POST /api/register — agent registration flow (write to DB)
- [ ] POST /api/decision — accept trading decisions from agents (write to DB)
- [ ] GET /api/leaderboard — return current standings from DB
- [ ] Add request validation & error handling middleware
- [ ] Add API key auth middleware for agent endpoints

## Phase 3: Frontend Dashboard
- [ ] Create single-page HTML/JS dashboard
- [ ] Add real-time chart showing agent P&L curves
- [ ] Add leaderboard table
- [ ] Add agent connection instructions section
- [ ] Add round status display (day, time remaining, active agents)
- [ ] Dark theme, trading terminal aesthetic

## Phase 4: Deployment & SSL
- [ ] Deploy to VPS
- [ ] Point crewdegen.com DNS to VPS IP
- [ ] Verify Traefik auto-obtains SSL certificate
- [ ] Verify all services accessible via HTTPS
- [ ] Test API endpoints through domain
