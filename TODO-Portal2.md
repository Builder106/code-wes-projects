## TODO — Portal 2 Hosted Instance (CS Club Project)

Main goal: One licensed Portal 2 host runs with `-netconport`; everyone else participates via a browser UI (controls, logs, queue) and a low‑latency live stream. Follow TDD, generate an implementation plan first

---

### Guardrails
- [ ] Legal: Use a legitimate Steam license for any machine running Portal 2 (no repacks).
- [ ] Accessibility: Browser-only for participants; only the host needs Steam.
- [ ] Dual deploy: Support both self‑hosted and cloud VM setups.
- [ ] Safety: Allowlist console actions, validate inputs, rate-limit, and audit.
- [ ] TDD: Write tests (contracts, validation, E2E) before implementing features.

---

### Milestone 0 — Planning & TDD Setup
- [ ] Decide hosting path: self‑hosted GPU PC vs. cloud GPU VM (G4/G5/A10).
- [ ] Pick stack: Backend (Node/Fastify or Python/FastAPI), Frontend (React/Svelte), DB (Redis for queue/ratelimit; Postgres optional).
- [ ] Draft OpenAPI contract for control API (actions, schemas, errors, auth).
- [ ] Define UI wireframes: stream pane, controls, queue, logs, admin.
- [ ] Threat model: disallowed commands, griefing, crash loops, credential leaks.
- [ ] Repo scaffolding via Bolt.new (backend, frontend, infra). Do not hand‑roll.
- [ ] CI setup: lint, typecheck, test; precommit hooks.

Tests (write first)
- [ ] Contract tests for each endpoint (happy paths + all error codes).
- [ ] Validation tests for each action schema (range clamps, enums, coordinates).
- [ ] E2E skeleton with mocked netcon + mocked stream (Playwright/Cypress).
- [ ] Load test plan (k6): 50 users burst clicking; target SLOs defined.

---

### Milestone 1 — Host Machine/VM
Self‑hosted
- [ ] Provision a GPU PC (Windows or Linux) with updated GPU drivers.
- [ ] Install Steam + Portal 2; sign in with licensed account.
Cloud
- [ ] Provision GPU VM (e.g., AWS G5/RTX A10) with inbound security groups set.
- [ ] Install NVIDIA drivers; enable H.264 NVENC.
Common
- [ ] Verify Portal 2 launches with network console enabled.

Example (Windows Steam launch options)
```text
-console -netconport 2121
```

- [ ] Create auto‑start script/service to launch Portal 2 with flags and auto‑recover.
- [ ] Document Steam account usage and session constraints.

---

### Milestone 2 — Low‑Latency Streaming
Option A (self‑hosted): Sunshine → WebRTC client
- [ ] Install Sunshine; configure 1080p/60, NVENC low‑latency preset, 8–12 Mbps.
- [ ] Enable Sunshine WebRTC web client; obtain viewer URL.
Option B (cloud): NICE DCV (browser client) or Parsec (native)
- [ ] Install DCV server; enable browser access; tune encoder and input latency.
Common
- [ ] Measure glass‑to‑glass latency; target < 200 ms.
- [ ] Provide a test page embedding the stream; show FPS/RTT overlay.

---

### Milestone 3 — Network Exposure & TLS
- [ ] Domain/DNS (e.g., `portal2.club.example`).
- [ ] Reverse proxy (Caddy/NGINX) with HTTPS and HSTS.
- [ ] Tunnel (Cloudflare Tunnel or Tailscale Funnel) for NAT‑safe public access.
- [ ] Firewall: expose only proxy + streaming ports; keep netcon TCP private.
- [ ] Health check endpoint exposed read‑only.

---

### Milestone 4 — Backend (HTTP → netcon bridge)
Scaffold (Bolt.new)
- [ ] Generate project with tests, OpenAPI, and typed schemas.

Features (implement after tests)
- [ ] TCP client to `-netconport` with reconnect/backoff.
- [ ] Allowlisted actions → console command templates (no freeform by default).
- [ ] Schema validation (e.g., zod/pydantic) with strict ranges/clamps.
- [ ] FIFO command queue with per‑user cooldowns and quotas.
- [ ] Rate limiting (Redis token bucket) + 429 with `retryAfterMs`.
- [ ] Idempotency keys for POST to prevent duplicate effects.
- [ ] Live logs via SSE and WebSocket (append‑only signed messages).
- [ ] Admin endpoints: pause/resume queue, update allowlist, kick sessions.
- [ ] Observability: structured logs, metrics (p95 latency, queue depth), traces.
- [ ] Packaging: systemd or Docker; env‑config; secrets via file/manager.

Tests
- [ ] Unit: netcon parser, reconnect logic, action mappers.
- [ ] Integration: queue ordering, ratelimit, idempotency, error propagation.
- [ ] Contract: OpenAPI conformance (request/response, errors).
- [ ] Soak: long‑running stability with periodic restarts.

---

### Milestone 5 — Frontend (Browser UI)
Scaffold
- [ ] SPA with routing, state, WebSocket client, and component library (accessible).

Features
- [ ] OAuth login (GitHub/Google) → JWT; roles: viewer, participant, admin.
- [ ] Stream embed component with latency + status overlay.
- [ ] Controls: buttons/sliders mapped to actions; disabled on cooldown.
- [ ] Command log panel (live updates, filter by user/action).
- [ ] Queue view: position, ETA; cancel own pending items.
- [ ] Admin view: pause queue, prioritize, modify allowlist (guarded).
- [ ] Mobile layout: touch‑safe controls; responsive stream.

Tests
- [ ] Unit: form validation, cooldown timers, WebSocket reducers.
- [ ] E2E: join → queue → execute → visual ack; mocked stream/netcon.
- [ ] Accessibility: keyboard nav, ARIA roles, contrast, focus traps.

---

### Milestone 6 — Security & Safety
- [ ] Command sandbox: explicit allowlist; block dangerous commands by default.
- [ ] Server‑side validation; clamp coordinates and numeric ranges.
- [ ] RBAC enforcement; per‑role quotas; audit trail with hashed args.
- [ ] CSRF/CORS configured for SPA origin; secure cookies if used.
- [ ] Abuse protection: burst limits, per‑IP ceilings, anomaly alerts.
- [ ] Secrets management (no credentials in code); rotate tokens.

---

### Milestone 7 — Testing & SLOs
- [ ] Define SLOs: API p95 < 200 ms (local), command exec < 2 s, stream latency < 250 ms.
- [ ] k6 load tests: 50 concurrent users clicking every 2–5 s.
- [ ] Security tests: attempt disallowed actions, malformed payloads → 4xx.
- [ ] Chaos: restart Portal 2 and backend; verify graceful recovery.
- [ ] Latency monitor: periodic synthetic command + in‑game overlay ack.

---

### Milestone 8 — Ops & Runbooks
- [ ] Deploy scripts (start/stop/restart), versioned config, rollback plan.
- [ ] Incident runbook: stream black screen, netcon disconnects, queue jam.
- [ ] Metrics dashboard + alerts for queue depth, error rate, reconnects.
- [ ] Backups of config/allowlist; restore test.
- [ ] Cost tracking (GPU hours, bandwidth), weekly budget review.

---

### Milestone 9 — Docs, Demo, and Onboarding
- [ ] Quickstart for participants (browser‑only): URL, controls, etiquette.
- [ ] Contributor guide (branching, testing, linting, PR checks).
- [ ] Architecture diagram and sequence of a command.
- [ ] FAQ (licensing, privacy, performance tips).
- [ ] Recorded demo and checklist for live event.

---

### Acceptance Criteria (MVP)
- [ ] Participants join via browser, see live stream, and authenticate.
- [ ] Users can trigger 3+ safe actions (e.g., spawn cube, toggle light, move platform).
- [ ] Actions are queued, rate‑limited, and logged with user attribution.
- [ ] System recovers from Portal 2 or backend restart without manual intervention.
- [ ] All tests green in CI; E2E suite passes against a mocked stream.

---

### Nice‑to‑Haves
- [ ] Turn‑taking mode (round‑robin queue).
- [ ] Replay safe macros; shareable command presets.
- [ ] “DOM to cubes” showcase parser behind a feature flag.
- [ ] Per‑user sandboxes (separate chambers) if capacity allows.

---

### Notes & References
- Portal 2 network console: launch with `-console -netconport <port>`.
- Streaming options: Sunshine (self‑hosted, WebRTC), NICE DCV (cloud, browser), Parsec (native).
- Follow TDD and scaffold with Bolt.new rather than coding from scratch.
