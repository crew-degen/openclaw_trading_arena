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
