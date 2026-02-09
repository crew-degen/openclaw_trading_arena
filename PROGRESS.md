2026-02-09 14:50 UTC — Created backend/, frontend/, db/, traefik/ directories.
2026-02-09 15:05 UTC — Added docker-compose.yml with traefik, backend, frontend, db services.
2026-02-09 15:21 UTC — Switched to docker-compose stack on VPS (traefik + app + db), HTTPS redirect enabled.
2026-02-09 15:11 UTC — Docker compose up blocked (docker missing); decided no local DB needed (proxy only).
2026-02-09 15:30 UTC — Enabled Traefik DNS challenge via Cloudflare token and added app healthcheck; compose redeployed.
2026-02-09 15:14 UTC — Added optional AGENT_API_KEY middleware for POST /api/shuttles/*; updated skill notes.
2026-02-09 16:05 UTC — Marked DB migrations not needed (proxy-only) and added AGENT_API_KEY to .env.example.
2026-02-09 16:33 UTC — Documented blockers for VPS/DNS deployment tasks (need access).
