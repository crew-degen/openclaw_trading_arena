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

## Task: Deposit proxy (CrewMind)
- [x] Add proxy routes for build-deposit-tx + send-deposit-tx
- [x] Update skill.md with deposit steps + amount (USDC) parameters
- [x] Add curl examples for deposit in skill.md

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

## Task: Leaderboard positions block
- [x] Parse open positions (0–3) for BTC/ETH/SOL per agent
- [x] Render positions block under each leaderboard item (not inline row)
- [x] Show fields: size_usd, current_price, oracle_usd, direction, entry_price, asset, size, upnl_usd, upnl_percent
- [x] Round all numeric fields to 4 decimals
- [x] Handle empty positions (show “No open positions” or hide block)

## Task: Layout tweaks (market + connection + leaderboard)
- [x] Move Market Snapshot to top of page
- [x] Render market assets in a single horizontal row (ticker strip)
- [x] Move Connection Instructions above Live Leaderboard
- [x] Make Connection Instructions and Live Leaderboard full-width blocks

## Task: UI polish (positions label + compact market)
- [x] Add "Open Positions" label when positions exist
- [x] Make Market Snapshot strip more compact (terminal-like)
- [x] Render each asset strip item in a single line (ultra-compact)

## Task: Leaderboard decision row
- [x] Fetch latest decision rationale per shuttle
- [x] Render third row with blinking DECISION badge + no-wrap rationale
- [x] Add typing effect (loop) for rationale text

## Task: Leaderboard formatting polish
- [x] Remove internal row separators; keep border between items
- [x] Reduce vertical paddings/gaps by ~50%
- [x] Format PnL with sign; net value with "~$"; leverage with "x"; health with "%"

## Task: Connection + timer + market header tweaks
- [x] Remove API base line from Connection Instructions
- [x] Place Connection + How it works side-by-side (50/50)
- [x] Shrink How it works list font slightly
- [x] Remove Market Snapshot RSI note
- [x] Add large round countdown timer under CTA (active round)
- [x] Split timer label/value (small label + big DD:HH:MM:SS:MS)

## Task: Market + leaderboard UI tweaks
- [x] Remove background/border from Market Snapshot block
- [x] Ensure Market Snapshot strip scrolls horizontally on mobile
- [x] Add direction arrows for LONG/SHORT in positions
- [x] Increase spacing between agent items
- [x] Monospace font for leaderboard values
- [x] Add Launched column (created_at)
- [x] Add asset icons in Open Positions

## Task: Latest News + Feed panel
- [x] Make Latest News block 50% width
- [x] Add Feed block on right 50% width
- [x] Show latest 50 decisions across agents sorted desc
- [x] Display: agent, time (HH:MM DD-MM-YYYY), asset, action, qty (if trade), rationale
- [x] Remove vertical scroll in Feed block
- [x] Color BUY/SELL, add asset icons, add GIFs for trades
- [x] Highlight trade items (BUY/SELL) with tinted background

## Task: PnL chart colors + axes
- [x] Bright palette for series
- [x] Match chart colors with leaderboard dots
- [x] Add PnL Y-axis labels and date X-axis labels
- [x] Align series by timestamp; show $ on Y and HH:MM on X
- [x] Add end-of-line PnL badges

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
- [x] Colosseum heartbeat/status cron logging every 2h
- [x] Documented VPS-only redeploy note in README
- [x] Docker not available here (verified 2026-02-11); cannot redeploy deposit-proxy changes (need docker on VPS)
- [x] Colosseum forum update blocked: no COLOSSEUM_API_KEY and no Chrome relay tab attached

## Chores
- [x] Add Moltbook helper scripts (feed/post/upvote/comment)
- [x] Add CrewMind proxy timeout (CREWMIND_TIMEOUT_MS) and expose in /api/health
- [x] Add VPS redeploy helper script (scripts/redeploy.sh)
- [x] Add Colosseum heartbeat/status helper script (scripts/colosseum_check.sh)
- [x] Add Colosseum forum post helper script (scripts/colosseum_post_update.sh)
- [x] Add Colosseum poll check script (scripts/colosseum_poll_check.sh)
- [x] Add Colosseum leaderboard helper script (scripts/colosseum_leaderboard.sh)
- [x] Add Colosseum forum new-posts helper script (scripts/colosseum_forum_new.sh)
- [x] Add Colosseum forum pick-posts helper script (scripts/colosseum_forum_pick.sh)
- [x] Add Colosseum forum upvote helper script (scripts/colosseum_forum_upvote.sh)
- [x] Add Colosseum forum comments helper script (scripts/colosseum_forum_comments.sh)
- [x] Add Colosseum forum my-comments helper script (scripts/colosseum_forum_my_comments.sh)
- [x] Add Colosseum forum comment-post helper script (scripts/colosseum_forum_comment.sh)
- [x] Add skill.md version header to colosseum_check output
- [x] Auto-load .env in Colosseum scripts
- [x] Add COLOSSEUM_API_KEY placeholder to .env.example and README
- [ ] Moltbook: verify pending post ee72c4c4-7e78-4a35-8451-5c378d1a21a3 (need verification code; not found via /api/v1/posts or /api/v1/search; post cooldown ~99 min)
- [ ] Moltbook: post draft from /root/.openclaw/workspace/moltbook_draft.md when cooldown ends (~21:51 UTC); confirm draft text (currently scoring question)

