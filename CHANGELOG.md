# Changelog

All notable changes to ForumForge are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Full-text search** over topics and comments, backed by PostgreSQL
  `tsvector` **generated columns** (title weighted `A`, body/url weighted `B`)
  with **GIN indexes** — no extra gem, no triggers. A `SearchController`
  serves both a full `/search` page and the header search box's debounced,
  Turbo-Frame-streamed live results, with `ts_headline` match highlighting.
  Query strings are bound as parameters end to end (injection-safe) and the
  highlight snippet is HTML-escaped before markup is applied (XSS-safe).
- **In-app notifications**: a `Notification` model (recipient / actor /
  polymorphic notifiable / action / `read_at`) created on **mentions**,
  **replies**, and **upvotes**. A header **bell** shows the unread count and
  updates live over a per-user Turbo Stream; a `/notifications` inbox supports
  per-item and "mark all read". This delivers on the README's long-standing
  `@mention` promise, which was previously only logged.
- **Transactional `@mention` email** via a new `ForumMailer#mention`, delivered
  asynchronously from `NotifyMentionsJob` (previously a commented-out stub).
- **Rate limiting** with `rack-attack`: per-IP throttles on voting, post/topic
  creation, and sign-in attempts, with a generic `429` response.
- **Test coverage** reporting via SimpleCov (branch coverage), uploaded as a CI
  artifact; new specs for search, notifications, the vote-state query count,
  and rate limiting.
- **`bundler-audit`** dependency-CVE scan and a **Dependabot** config
  (bundler + GitHub Actions) for supply-chain hygiene.
- **`docker-compose.yml`** for a one-command run (`docker compose up`), plus a
  **`demo` profile** and a **`rake demo:bot`** task that continuously posts
  replies and casts votes so a watched thread animates in real time.
- Keyframe-based entrance animation for live-appended rows so the real-time
  nature is immediately visible (respects `prefers-reduced-motion`).

### Changed

- **Killed the vote-state N+1.** The feed and thread views previously ran one
  `votable.votes.exists?` query per row. A new `VotedSet` preloads the viewer's
  votes for the whole page in a single query and the vote partials consult it
  in memory. A request spec asserts the feed's query count is independent of
  the number of rows.
- Enriched the seed data (a moderator, more topics, search-friendly content,
  seeded mentions/notifications) so a fresh install demos well.

### Security

- Added per-IP rate limiting on abuse-prone write endpoints and sign-in.
- Confirmed the Content Security Policy is enabled in production (with
  session-scoped nonces for importmap's inline scripts).
- Full-text search and highlight are injection- and XSS-safe by construction
  (parameter binding + escape-then-mark).

### Notes

- `Gemfile.lock` is intentionally still not committed; CI and Docker resolve
  gems on install. `bundler-audit` (CI, non-blocking) and Dependabot cover the
  supply-chain angle in the meantime.

---

## [0.1.0] — 2026-01

Initial public release: Rails 7.1 + Hotwire community forum with threaded
discussions, link aggregation, live-updating Turbo Stream threads, polymorphic
voting with async reputation (Sidekiq/Redis), categories, sorting, Devise auth
with roles, a leaderboard, RSpec + Capybara/Selenium tests, GitHub Actions CI,
and Docker/Heroku deploy config.

[Unreleased]: https://github.com/xj16/forumforge/compare/main...HEAD
