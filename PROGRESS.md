# Build Progress (checkpointed)

Legend: [ ] pending  [x] done

## Checkpoint 0 - Planning
- [x] Inspected existing monolith backend + blood_bank_db_corrected.sql
- [x] Architecture decided: api-gateway + auth-service + core-service + notification-service(MongoDB) + frontend
      (grouped microservices, not one-microservice-per-table, to stay maintainable; justified in docs/PRESENTATION.md)

## Checkpoint 1 - auth-service (JWT issuing, users/donors login+register, token validate)
- [x] scaffold + package.json
- [x] config/env,db
- [x] services/controllers/routes (login, register, me, change-password, token validate endpoint)
- [x] tested standalone (login, token now carries role/username/fullName claims)

## Checkpoint 2 - core-service (all business MySQL APIs, reused/adapted from monolith)
- [x] scaffold + package.json
- [x] gateway-header-or-JWT authenticate middleware
- [x] all 11 resource modules ported (users, donors, hospitals, blood-stock, blood-requests,
      blood-issues, donations, donation-requests, donation-camps, camp-registrations,
      eligibility-tests, reports)
- [x] notification client wired on 6 key events (blood issued, donation recorded, donation
      request status change + complete, blood request status change, camp registration,
      eligibility screening) -- FIXED a real bug: notifyClient wasn't sending the
      x-internal-secret header, so events were silently rejected (401) by notification-service
      and fetch never threw. Added response.ok check + the header. Verified fixed.
- [x] tested standalone AND through the gateway

## Checkpoint 3 - notification-service (MongoDB events/activity/notifications)
- [x] scaffold + package.json, mongoose model
- [x] POST /api/events (internal, guarded by shared secret), GET /api/events + /api/events/summary (staff/admin only)
- [x] dual repository: real Mongo (used whenever reachable, e.g. Docker) + a clearly-logged
      dev-only in-memory fallback (sandbox has no MongoDB binary reachable -- network egress
      is restricted to package registries, not db download hosts) so the service is still
      fully testable here. NEVER used when NODE_ENV=production.
- [x] tested standalone and via the gateway (events recorded, listed, RBAC-gated)

## Checkpoint 4 - api-gateway
- [x] scaffold + package.json
- [x] JWT verify (stateless, via shared secret) + header injection, proxy routes to the 3 services
- [x] rate limit, helmet, cors, aggregate /api/health
- [x] header-forgery protection (strips any client-supplied x-user-*/x-gateway-secret
      headers before verifying) -- tested: forging x-user-role: Admin on a Staff token is
      rejected (403, real role preserved)
- [x] tested end-to-end through gateway: login (user+donor), RBAC 403/401, protected routes,
      token validation endpoint, invalid-token rejection, notification event pipeline
- [x] FIXED 2 real bugs found by testing:
      1) isPublic() compared req.path (mount-relative, e.g. '/login') instead of the full
         original URL -- public auth routes were incorrectly demanding a token.
      2) Express strips the matched mount prefix from req.url before the proxy middleware
         sees it (e.g. '/api/auth/login' -> '/login'), so every proxied call was reaching
         the downstream service with the wrong path. Fixed with pathRewrite: (path, req) =>
         req.baseUrl + path, which generically restores the right prefix for every mount
         shape used (single path, array of prefixes, and exact routes).

## Checkpoint 5 - Docker
- [x] Dockerfile per backend service (auth/core/notification/gateway) + .dockerignore
- [ ] frontend Dockerfile (pending until frontend exists)
- [x] docker-compose.yml -- deliberate design: MySQL is NOT containerized (per the
      "local development must continue using my existing MySQL database" requirement).
      All 4 backend services connect OUT to the host's existing MySQL via
      host.docker.internal (extra_hosts: host-gateway, works on Docker Desktop +
      Linux). MongoDB IS containerized (mongo:7) since there's no pre-existing
      instance to preserve. mysql-init/01-blood_bank_db_corrected.sql is kept only
      as a manual-import convenience for a from-scratch setup -- UNMODIFIED copy
      of the user's final SQL, never auto-run against an existing database.
- [x] docker-compose.yml validated as syntactically correct YAML (no Docker engine
      available in this sandbox to actually run `docker compose up` -- noted
      honestly in README; all services/ports/env vars match what was tested live
      via scripts/dev-up.sh in this sandbox)
- [x] .env.example at root (pointer to the 4 services/*/.env.example files)

## Checkpoint 6 - Frontend (React + Vite)
- [x] scaffold (Vite + React + react-router-dom), custom design system (index.css),
      api client with Bearer token injection, AuthContext (login/logout/refresh,
      localStorage-persisted session), usePaginated hook shared by every list page
- [x] role dashboards: Admin/Manager/Staff get a system-wide stats dashboard
      (/reports/dashboard); User gets their own blood-request summary; Donor gets
      their own donations + upcoming camps -- all real data, no mock data
- [x] Admin Users page: responsive GRID/CARD layout, search, role filter,
      view/edit/delete (self-delete blocked in the UI), all existing user fields
      shown (id, name, username, role, email, address). Avatar note: the `users`
      table has NO gender column in the finalized schema (only `donors` does),
      so per "do not invent columns" users get a neutral initials avatar
      (deterministic color per id) and the Donors page -- which has real gender
      data -- gets a true gender-based default avatar. Documented in README too.
- [x] every other module wired to the real API with working create/update/delete/
      status-transition actions respecting each role's permissions: Donors,
      Hospitals, Blood Stock (manual correction), Blood Requests (create/approve/
      reject/cancel), Blood Issues (issue against Approved requests), Donations,
      Donation Requests (request/accept/reject/complete/cancel), Donation Camps
      (create + register), Camp Registrations, Eligibility Screening (explicit
      "preliminary screening only -- not medical approval" banner on both the
      form and the results table), Reports (6 report widgets), Activity Log
      (reads the MongoDB-backed notification-service events)
- [x] no photo upload anywhere -- all avatars are generated inline SVG data URIs
- [x] `npm run build` succeeds cleanly (0 errors) -- 55 modules, single JS+CSS bundle
- [x] served with `vite preview` and confirmed responding (HTTP 200); API base URL
      is env-configurable (VITE_API_BASE_URL) for both local dev and Docker
- [x] frontend Dockerfile (multi-stage: node build -> nginx static serve, SPA
      fallback routing in nginx.conf)
- NOTE (honest limitation): this sandbox has no real browser, so interactivity
  (clicking through forms, modals, etc.) was verified by code review + a clean
  production build (which catches import/syntax/JSX errors), not by driving an
  actual browser. The API layer every page calls was separately verified
  end-to-end via scripts/dev-up.sh + curl in Checkpoints 1-4.

## Checkpoint 7 - Testing
- [x] scripts/smoke-test.js -- automated end-to-end test run through the REAL
      api-gateway (not individual services), 38 checks: gateway aggregate health,
      JWT auth for both account types, invalid/missing-token rejection, the
      explicit token-validate endpoint, RBAC (403s per role), header-forgery
      protection, and a representative CRUD/workflow slice of all 12 business
      modules including the DB-trigger-enforced workflows (blood issue requires
      Approved status, donation request Pending->Accepted->Donated), plus the
      MongoDB-backed activity log being populated and RBAC-gated.
- [x] runnable two ways: `node scripts/smoke-test.js` or `npm run smoke-test`
      (root package.json)
- [x] BUILD -> RUN -> TEST -> FIX -> RETEST actually happened: first run found a
      REAL bug (core-service's config/env.js was missing bcryptRounds, so
      creating any new user/donor threw "Illegal arguments: string, undefined"
      from bcryptjs -- a 500 on POST /users). Fixed (added bcryptRounds to
      core-service env config + .env.example), restarted core-service, reloaded
      the database, reran the full suite: 38/38 passed, 0 failures.
- [x] confirmed sample data integrity: fresh SQL load always diffs identical to
      the original dataset (reused the same snapshot/diff approach proven
      earlier in this project)

## Process-management notes for future continuation (sandbox-specific)
- MySQL and the 4 Node services do NOT reliably survive between tool calls in
  this sandbox (the container appears to reset background processes
  periodically) -- always re-check with `pgrep -af "src/server.js"` /
  `mysqladmin ping` before assuming anything is still up, and re-run
  scripts/dev-up.sh if not.
- NEVER use `pkill -f "<pattern>"` or `pgrep -f "<pattern>"` where <pattern>
  also appears as literal text in the invoking command itself -- it matches
  its own process and kills/reports itself. Always invoke kill-by-pattern
  logic from a separate script FILE (not an inline string), and prefer
  matching on the service's absolute script path (e.g.
  "/home/claude/bloodbank-system/services/core-service/src/server.js") so the
  match is specific and no two processes collide.
- Always background with `exec setsid node ... > log 2>&1 < /dev/null &`
  (note: `< /dev/null` on stdin is required, otherwise the tool call itself
  can hang waiting on that file descriptor).
- scripts/dev-up.sh and scripts/dev-down.sh already encode all of the above
  correctly -- prefer them over ad hoc commands.

## Checkpoint 8 - Docs
- [x] README.md (architecture diagram + service-split rationale, database
      preservation statement, local dev setup steps without Docker, Docker
      Compose setup + the host.docker.internal MySQL note, auth/JWT/RBAC
      design including the stated stateless-JWT trade-off, testing
      instructions, frontend notes incl. the gender-avatar deviation, and an
      explicit "honest limitations" section)
- [x] docs/PRESENTATION.md (viva notes: architecture walkthrough, why 4
      services not 1 or 12, JWT trade-off defense, security details,
      database-trigger reliance, "did you actually run this" answer, and a
      likely-questions/short-answers section)

## FINAL STATUS: all 8 checkpoints complete.
Full regression re-run after docs were written: scripts/smoke-test.js ->
38 passed, 0 failed (see terminal output captured during this session).
Nothing known-broken remains. Remaining work is entirely optional polish
(see README "Honest limitations"): actually running `docker compose up` in a
real Docker environment, and interactive browser testing of the frontend.

## Known limitations / honesty notes
- Sandbox has no Docker engine, so docker-compose itself cannot be executed here.
  Services are tested by running them directly with Node on separate ports (same
  code Docker would run) and are proxied through the real api-gateway. Dockerfiles
  and compose config are written to the same env vars/ports validated in this testing.
