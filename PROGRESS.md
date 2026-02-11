2026-02-09 14:50 UTC — Created backend/, frontend/, db/, traefik/ directories.
2026-02-09 15:05 UTC — Added docker-compose.yml with traefik, backend, frontend, db services.
2026-02-09 15:21 UTC — Switched to docker-compose stack on VPS (traefik + app + db), HTTPS redirect enabled.
2026-02-09 15:11 UTC — Docker compose up blocked (docker missing); decided no local DB needed (proxy only).
2026-02-09 15:30 UTC — Enabled Traefik DNS challenge via Cloudflare token and added app healthcheck; compose redeployed.
2026-02-09 15:14 UTC — Added optional AGENT_API_KEY middleware for POST /api/shuttles/*; updated skill notes.
2026-02-09 16:05 UTC — Marked DB migrations not needed (proxy-only) and added AGENT_API_KEY to .env.example.
2026-02-09 16:33 UTC — Documented blockers for VPS/DNS deployment tasks (need access).
2026-02-09 17:14 UTC — UI update: market/news panels, auto-refresh metrics; fixed skill.md template and redeployed.
2026-02-09 17:20 UTC — RSI feed shows 0 from upstream; UI now treats 0 as n/a and notes feed source; redeployed.
2026-02-09 18:55 UTC — Cleared deployment blockers; compose/SSL/DNS/HTTPS verified.
2026-02-10 08:24 UTC — Added BTC fallback chart (visx) when no shuttles, price-history proxy, layout gaps/mobile tweaks.
2026-02-10 09:05 UTC — Hotfix: dynamic visx load (no JS block), main gap=15px; data/news restored, redeployed.
2026-02-10 10:10 UTC — Fixed BTC visx chart (ticks mapping, yellow line + badge, BTC Price label); redeployed.
2026-02-10 10:16 UTC — Patched visx runtime error (removed scale import, manual scales) and redeployed.
2026-02-10 10:27 UTC — Added chart-utils + tests (node:test), removed visx/text import; redeployed.
2026-02-10 10:34 UTC — Enabled dev React bundles + visx fallback polyline; redeployed.
2026-02-10 10:44 UTC — BTC badge now shows last price (BTC / $xx,xxx.xx); redeployed.
2026-02-10 10:52 UTC — Mobile: stacked market/news on <1000px; redeployed.
2026-02-10 11:41 UTC — Exposed MySQL 3306 on VPS for external access.
2026-02-10 11:51 UTC — Added Prisma schema + initial migration; applied to DB.
2026-02-10 12:12 UTC — Added decisions.rationale (TEXT) via Prisma migration.
2026-02-10 15:43 UTC — Replaced skill.md with new version from team; server now serves public/skill.md.
2026-02-09 18:53 UTC — Posted Colosseum forum progress update; status: claimed, 2d22h left, 39 replies.
2026-02-09 22:57 UTC — Posted forum heartbeat check-in; status claimed, replies=48, no active poll.
2026-02-10 03:27 UTC — Posted forum heartbeat update; status claimed, replies=51, no active poll.
2026-02-10 04:26 UTC — Expanded /api/health with version/uptime metadata; updated README; added package-lock and ignored node_modules.
2026-02-10 04:28 UTC — Noted blocker: missing Telegram chatId/alias for Crewdegen <> R&D updates.
2026-02-10 04:30 UTC — Sent Telegram progress update to Crewdegen <> R&D (chatId -4810105807); cleared blocker.
2026-02-10 04:57 UTC — Added git commit hash to /api/health (env/Git HEAD) and documented GIT_SHA.
2026-02-10 05:58 UTC — Posted Colosseum forum progress update (health+git SHA); checked heartbeat/status (no poll).
2026-02-10 07:26 UTC — UI now shows API version/commit from /api/health; updated dashboard stats.
2026-02-10 08:07 UTC — Color-coded API status indicator on dashboard using /api/health.
2026-02-10 08:09 UTC — Posted Colosseum forum update (UI API status); checked heartbeat/status (no poll).
2026-02-10 10:06 UTC — Posted Colosseum forum update (API status indicator); checked heartbeat/status (no poll).
2026-02-10 10:17 UTC — Added chart tests (fmt/normalizeHistory/drawChart) and test script.
2026-02-10 12:15 UTC — Updated Colosseum project description/demo link; posted forum update; checked heartbeat/status (no poll).
2026-02-10 14:44 UTC — Posted Colosseum forum update; checked heartbeat/status (no poll).
2026-02-10 16:30 UTC — Posted Colosseum forum update (deadline check-in); checked heartbeat/status (no poll).
2026-02-10 16:32 UTC — Switched Docker base to debian to fix Prisma (libssl); redeployed.
2026-02-10 19:30 UTC — Allowed shuttle creation during active rounds (registration+active).
2026-02-10 20:02 UTC — Posted Colosseum forum update (day 9); checked heartbeat/status (no poll).
2026-02-10 20:12 UTC — Added deposit tx proxies + updated skill.md with USDC amount + curl example; redeploy pending.
2026-02-10 20:13 UTC — Redeploy blocked: docker command not found on this host; need VPS/docker to apply deposit-proxy changes.
2026-02-10 20:15 UTC — Corrected deposit amount units to SOL in skill.md.
2026-02-10 20:16 UTC — Documented VPS-only redeploy note in README.
2026-02-10 20:46 UTC — Redeploy still blocked here (no docker). Need VPS/docker to apply deposit-proxy changes.
2026-02-10 22:17 UTC — Posted Colosseum forum update (day 9.5); checked heartbeat/status (no poll).
2026-02-11 00:47 UTC — Posted Colosseum forum update (day 9.7); checked heartbeat/status (no poll).
2026-02-11 02:17 UTC — Posted Colosseum forum update (final stretch); checked heartbeat/status (no poll).
2026-02-11 03:17 UTC — Posted Colosseum forum update (day 9.8); checked heartbeat/status (no poll).
2026-02-11 04:18 UTC — Added CrewMind proxy timeout (CREWMIND_TIMEOUT_MS) and exposed in /api/health.
2026-02-11 04:47 UTC — Added VPS redeploy helper script and documented usage.
2026-02-11 05:18 UTC — Added colosseum_check helper script; forum update blocked (no API key/relay).
2026-02-11 05:47 UTC — Added Colosseum forum post helper script; heartbeat checked (status/forum blocked without API key/relay).
2026-02-11 06:17 UTC — Added COLOSSEUM_API_KEY placeholder to env example and README.
2026-02-11 06:19 UTC — Removed COLOSSEUM_API_KEY example from README (no secrets in docs).
2026-02-11 06:47 UTC — Added Colosseum poll check helper script and documented usage.
2026-02-11 07:18 UTC — Updated colosseum_check to show skill.md head and avoid pipefail errors.
2026-02-11 07:47 UTC — Auto-loaded .env in Colosseum helper scripts and documented it.
2026-02-11 08:17 UTC — Added Colosseum leaderboard helper script and documented usage.
2026-02-11 08:47 UTC — Added Colosseum forum new-posts helper script and documented usage.
2026-02-11 09:17 UTC — Added Colosseum forum comments helper script and documented usage.
2026-02-11 11:09 UTC — Leaderboard now renders positions block (BTC/ETH/SOL) with 4-decimal fields + mobile styling.
2026-02-11 11:13 UTC — Added Colosseum forum comment-post helper script and documented usage.
2026-02-11 11:13 UTC — Leaderboard positions now read from snapshot.stats fallback (positions may be null).
2026-02-11 11:20 UTC — Moved Market Snapshot to top ticker strip; Connection Instructions now above full-width Leaderboard.
2026-02-11 11:23 UTC — Added Colosseum my-comments helper script and documented usage.
2026-02-11 11:30 UTC — Added Open Positions label and compacted Market Snapshot strip layout.
2026-02-11 11:39 UTC — Market Snapshot strip items now single-line, ultra-compact.
2026-02-11 11:43 UTC — Added forum pick helper script and updated forum-hustle cron prompt to use scripts.
2026-02-11 11:50 UTC — Added decision row with blinking DECISION badge + looping typing effect in leaderboard.
2026-02-11 11:57 UTC — Leaderboard row borders/padding tightened; PnL sign, net value ~$ , leverage x, health % formatting.
2026-02-11 12:07 UTC — Connection/How side-by-side, removed API base + RSI note, added round countdown timer.
2026-02-11 12:14 UTC — Timer split into label + DD:HH:MM:SS:CS display (100ms update).
2026-02-11 12:24 UTC — Market strip borderless + mobile scroll; leaderboard monospace values, Launched column, direction arrows, larger item spacing.
2026-02-11 12:37 UTC — Added Moltbook helper scripts (feed/post/upvote) and used them for a Moltbook post.
2026-02-11 12:40 UTC — Added Feed panel with latest 50 decisions; Latest News now 50% width.
2026-02-11 12:49 UTC — Removed vertical scroll from Feed block.
2026-02-11 12:59 UTC — Feed: colored BUY/SELL, asset icons, trade GIFs.
2026-02-11 13:05 UTC — Feed trade items now tinted by action; GIF images set with no-referrer.
2026-02-11 13:11 UTC — Added asset icons to Open Positions titles.
2026-02-11 13:18 UTC — Added Moltbook comment helper script and engaged with a Moltbook post.
2026-02-11 13:25 UTC — PnL chart now uses bright palette, leaderboard color dots, and axes labels (PnL + dates).
2026-02-11 13:32 UTC — Chart aligned by timestamps; Y labels with $, X labels HH:MM.
2026-02-11 13:43 UTC — Added Colosseum forum upvote helper; made drawChart robust to test data.
2026-02-11 14:00 UTC — Moltbook: commented + verified + upvoted a hot post (operator discipline).
2026-02-11 14:09 UTC — Added end-of-line PnL badges on chart series.
2026-02-11 14:20 UTC — Moltbook: commented + verified + upvoted email-to-podcast post.
2026-02-11 14:40 UTC — Moltbook: commented + verified + upvoted good‑Samaritan post.
2026-02-11 15:00 UTC — Moltbook: commented + verified + upvoted skill.md supply-chain post.
2026-02-11 15:20 UTC — Moltbook: commented + verified + upvoted token-velocity post.
2026-02-11 15:40 UTC — Moltbook: commented + verified + upvoted API error responses post.
2026-02-11 16:00 UTC — Moltbook: commented + verified + upvoted SNR post.
