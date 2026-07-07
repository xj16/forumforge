# ForumForge

> A real-time, self-hostable community forum — Rails 7 + Hotwire, no JS build step.

ForumForge is a fully-featured, open-source discussion platform: part
Reddit-style **link aggregator**, part threaded discussion forum. It combines
classic forum mechanics (categories, threads, nested replies, reputation) with
a modern, no-build **Hotwire** front end, so threads, vote counts, search
results, and notifications update **live** — no page reloads, no client-side
framework.

[![CI](https://github.com/xj16/forumforge/actions/workflows/ci.yml/badge.svg)](https://github.com/xj16/forumforge/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.3-CC342D.svg)](.ruby-version)
[![Rails](https://img.shields.io/badge/Rails-7.1-D30001.svg)](Gemfile)
[![Coverage: SimpleCov](https://img.shields.io/badge/coverage-SimpleCov-brightgreen.svg)](#running-the-tests)

**One-command run:** `docker compose up --build` → <http://localhost:3000>.
Add `--profile demo` to seed data and watch a thread update itself live.

---

## Why

Most "forum in a box" projects are either heavyweight PHP apps or thin SPA
demos that fall apart the moment you need real-time updates or background work.
ForumForge is a **realistic, production-shaped** Rails application you can read
end to end in an afternoon:

- It shows how to build **live-updating UI** with Turbo Streams broadcast
  straight from Active Record model callbacks — the "HTML over the wire"
  approach — without writing a single line of custom WebSocket code.
- It uses **Sidekiq on Redis** to move reputation recalculation and mention
  notifications **off the request path**, the way a real app would.
- It demonstrates a clean, well-tested domain model with **polymorphic voting**,
  **counter caches**, **friendly slugs**, and **Devise** authentication.
- It ships with **RSpec** unit/request specs and **Capybara + Selenium** system
  specs (headless Chrome) wired into GitHub Actions CI, plus a **Dockerfile**
  and **Heroku** one-click deploy config.

---

## Features

- **Threaded discussions** — topics with arbitrarily nested replies (a
  self-referential `Post` tree), rendered recursively.
- **Link aggregation** — a topic can be a text post *or* a link post; link
  posts show the source domain, Hacker-News style.
- **Live-updating threads** — new replies, edits, deletions, and vote counts are
  pushed to every viewer via **Turbo Streams** broadcast from model callbacks
  over Action Cable (Redis).
- **Full-text search** — ranked search over topics and comments, powered by
  PostgreSQL `tsvector` **generated columns** + **GIN indexes** (no extra gem).
  The header box streams **debounced, highlighted results** into a Turbo Frame
  as you type; a `/search` page mirrors it. Injection- and XSS-safe by design.
- **Notifications** — a real in-app inbox with a live **unread bell**. Replies,
  `@username` mentions, and upvotes create `Notification` records that stream to
  the recipient's browser over a per-user Turbo Stream; mentions also send an
  email via `ForumMailer`.
- **Voting + reputation** — polymorphic upvotes on both topics and posts. A
  user's reputation is recomputed asynchronously by a **Sidekiq** job whenever
  their content is voted on, and the reputation badge updates live. The viewer's
  vote state is preloaded per page (one query — no N+1).
- **Leaderboard** — members ranked by reputation.
- **Categories** — topics grouped into categories with per-category feeds.
- **Sorting** — `hot` (time-decayed score), `new`, and `top` feeds.
- **Authentication** — sign up / sign in / password reset via **Devise**, with
  usernames and role-based permissions (`member`, `moderator`, `admin`).
- **Rate limiting** — `rack-attack` throttles voting, posting, and sign-in per
  IP to blunt spam and brute-force attempts.
- **Admin dashboard** — the Sidekiq web UI, mounted at `/sidekiq` and locked to
  admins.
- **No JavaScript build step** — Hotwire via `importmap-rails` and CSS via
  `propshaft`. Nothing to `npm install`.

---

## Tech stack

| Layer            | Choice                                             |
| ---------------- | -------------------------------------------------- |
| Language         | **Ruby** 3.3                                       |
| Framework        | **Ruby on Rails** 7.1                              |
| Database         | **PostgreSQL**                                     |
| Background jobs  | **Sidekiq** on **Redis**                           |
| Real-time        | Turbo Streams over Action Cable (**Redis**)        |
| Search           | PostgreSQL **full-text search** (`tsvector` generated columns + GIN) |
| Front end        | **Hotwire** (Turbo + Stimulus), importmap, Propshaft |
| Auth             | **Devise**                                         |
| Security         | **rack-attack** rate limiting, CSP (prod), bundler-audit |
| Slugs / paging   | FriendlyId, Pagy                                   |
| Tests            | **RSpec**, FactoryBot, **Capybara + Selenium** (headless Chrome), shoulda-matchers, **SimpleCov** |
| CI               | **GitHub Actions** (lint, specs, system, security) |
| Deploy           | **Docker** (+ `docker-compose`) & **Heroku** (`app.json`, `Procfile`) |

---

## Data model

```
User 1───* Topic *───1 Category
 │           │
 │           *
 │         Post ──┐  (self-referential: parent_id → replies)
 │           │    │
 *           *    │
Vote (polymorphic: votable = Topic | Post)

Notification (recipient, actor, polymorphic notifiable = Topic | Post, action, read_at)
```

- `Topic` — a thread; text post (`body`) or link post (`url`). Has a
  `search_vector` generated `tsvector` column (title `A`, body/url `B`).
- `Post` — a reply; `parent_id` makes replies a tree. Also searchable.
- `Vote` — a polymorphic upvote, unique per `(user, votable)`.
- `Notification` — an inbox item for a `recipient`, created on mention/reply/
  upvote and pushed live to a per-user Turbo Stream.
- Counters (`upvotes_count`, `posts_count`, `topics_count`) are denormalized
  and kept in sync by callbacks / `counter_cache`.
- Reputation points (see `app/models/reputation.rb`): topic upvote `+10`,
  post upvote `+5`, topic created `+2`, post created `+1`.

---

## How it works: live updates

When a reply is created, the `Post` model broadcasts a Turbo Stream:

```ruby
# app/models/post.rb
after_create_commit :broadcast_created

def broadcast_created
  target = parent_id ? "replies_#{parent_id}" : "posts"
  broadcast_append_to topic,                # stream name = the topic
    target: target,                         # DOM id to append into
    partial: "posts/post", locals: { post: self }
  NotifyMentionsJob.perform_later(id)       # async @mention fan-out
  notify_reply_recipient                    # in-app notification
end
```

Any browser on that topic page subscribes with one line in the view:

```erb
<%= turbo_stream_from @topic %>
```

Action Cable (backed by Redis) delivers the rendered HTML fragment to every
subscriber. The same pattern drives live vote counts, the reputation badge, and
the notification bell (each on its own per-user or per-topic stream).

## How it works: full-text search

Search needs **no gem and no triggers**. A migration adds a `STORED`,
generated `tsvector` column to `topics` and `posts` and a GIN index on each:

```sql
ALTER TABLE topics ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(body,  '')), 'B')
  ) STORED;
CREATE INDEX ON topics USING gin (search_vector);
```

Postgres keeps the vector in sync on every write. `Searchable#search` binds the
query with `websearch_to_tsquery` (injection-safe) and ranks with `ts_rank`;
`search_highlight` uses `ts_headline` and escapes the source *before* inserting
`<mark>` tags (XSS-safe). The header box debounces input in a Stimulus
controller and streams ranked results into a Turbo Frame — live search with
progressive enhancement (it still works with JS off).

---

## Getting started (local)

### Prerequisites

- Ruby 3.3 (`.ruby-version` is provided; use `rbenv`/`asdf`/`rvm`)
- PostgreSQL 14+
- Redis 6+
- Google Chrome (only needed to run the Selenium system specs)

### Setup

```bash
git clone https://github.com/xj16/forumforge.git
cd forumforge

# Install gems
bundle install

# Configure environment (Postgres/Redis connection)
cp .env.example .env
# edit .env if your Postgres/Redis differ from the defaults

# Create the database, load the schema, and seed demo data
bin/rails db:prepare
bin/rails db:seed
```

### Run

ForumForge needs a web process and a Sidekiq worker. The included
`Procfile.dev` runs both:

```bash
bin/dev          # starts Puma + Sidekiq via foreman
```

…or run them in separate terminals:

```bash
bin/rails server                      # http://localhost:3000
bundle exec sidekiq -C config/sidekiq.yml
```

Open <http://localhost:3000>. The seed data creates several users — log in as
any of `ada`, `linus`, `grace`, `dennis`, `margaret`, or `admin` with the
password **`password123`**. `grace` is a **moderator**; `admin` is an **admin**
and can reach the Sidekiq dashboard at `/sidekiq`.

### Watch it update live

With a topic open in your browser, run the demo bot in another terminal:

```bash
bin/rails demo:bot                 # posts replies + votes on the hot topic
TOPIC=<slug> bin/rails demo:bot    # target a specific topic
```

Comments and vote counts animate in without a page reload — the real-time path
end to end, no second browser needed.

---

## Running the tests

```bash
# Fast suite: models, requests, jobs
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"

# Full suite including Capybara + Selenium system specs (needs Chrome)
bundle exec rspec
```

The `spec/system/live_thread_spec.rb` example is tagged `js: true` and runs in
**headless Chrome via Selenium** to verify that a reply appears without a full
page reload. Rack-test system specs cover the non-JS flows.

Beyond the model layer, specs cover the harder subsystems: **full-text search**
(ranking, matching, injection/XSS safety), **notifications** (mention/reply/
upvote fan-out, dedup, authorization), **rate limiting** (Rack::Attack
throttles engaging), and a **query-count spec** that proves the feed has no
vote-state N+1 regardless of row count.

**Coverage** is measured with **SimpleCov** (set `COVERAGE=true`):

```bash
COVERAGE=true bundle exec rspec   # writes coverage/index.html
```

CI (GitHub Actions, `.github/workflows/ci.yml`) runs four jobs on every push
and PR: **RuboCop lint**, the **RSpec** suite (with coverage) against Postgres +
Redis service containers, the **Selenium system specs** with a real headless
Chrome, and a **bundler-audit** dependency-CVE scan.

---

## Deployment

### Heroku (one click)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/xj16/forumforge)

The `app.json` provisions **Heroku Postgres** and **Heroku Redis**, runs
migrations on release, seeds on first deploy, and boots a `web` + `worker`
dyno (Sidekiq). The `Procfile` defines all three process types.

### Docker Compose (one command)

The fastest way to run the whole stack — web, Sidekiq worker, Postgres, and
Redis — locally:

```bash
docker compose up --build
# → http://localhost:3000
```

Add the **demo profile** to seed realistic data and start a bot that posts
replies and casts votes on a schedule, so an open thread visibly updates in
real time:

```bash
docker compose --profile demo up --build
# open a topic and watch comments + vote counts animate in live
```

### Docker (single image)

```bash
docker build -t forumforge .
docker run -d -p 80:80 \
  -e DATABASE_URL=postgres://... \
  -e REDIS_URL=redis://... \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  forumforge
```

The multi-stage `Dockerfile` builds a slim production image, precompiles
assets, and runs as a non-root user.

---

## Project layout

```
app/
  controllers/        # topics, posts, search, notifications, categories, users, …
  models/             # User, Category, Topic, Post, Vote, Notification, Reputation
    concerns/         # Searchable (Postgres full-text search)
  models/voted_set.rb # per-page preloaded vote state (kills the vote N+1)
  jobs/               # ReputationJob, NotifyMentionsJob (Sidekiq)
  mailers/            # ForumMailer (@mention emails)
  views/              # ERB + Turbo Stream partials (search, notifications, …)
  javascript/         # Stimulus controllers (reply toggle, flash, debounced search)
  assets/stylesheets/ # single hand-written CSS file (Propshaft, no build)
config/               # routes, environments, Sidekiq, Devise, importmap, rack_attack
db/migrate/           # schema migrations (search vectors, notifications) + slugs
lib/tasks/demo.rake   # demo:bot — live-activity generator
spec/                 # RSpec: models, requests, jobs, system (Capybara+Selenium)
.github/              # CI workflow + Dependabot
Dockerfile, docker-compose.yml, app.json, Procfile   # deployment
```

---

## License

[MIT](LICENSE) © 2026 xj16
