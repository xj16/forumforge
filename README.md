# ForumForge

> A modern community forum built with Ruby on Rails 7 + Hotwire.

ForumForge is a fully-featured, open-source discussion platform: part
Reddit-style **link aggregator**, part threaded discussion forum. It combines
classic forum mechanics (categories, threads, nested replies, reputation) with
a modern, no-build **Hotwire** front end, so threads and vote counts update
**live** for everyone in the thread — no page reloads, no client-side framework.

![CI](https://github.com/xj16/forumforge/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

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
- **Voting + reputation** — polymorphic upvotes on both topics and posts. A
  user's reputation is recomputed asynchronously by a **Sidekiq** job whenever
  their content is voted on, and the reputation badge updates live.
- **Leaderboard** — members ranked by reputation.
- **Categories** — topics grouped into categories with per-category feeds.
- **Sorting** — `hot` (time-decayed score), `new`, and `top` feeds.
- **Authentication** — sign up / sign in / password reset via **Devise**, with
  usernames and role-based permissions (`member`, `moderator`, `admin`).
- **Mentions** — `@username` mentions in replies fan out through a background
  job (`NotifyMentionsJob`) on a low-priority Sidekiq queue.
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
| Front end        | **Hotwire** (Turbo + Stimulus), importmap, Propshaft |
| Auth             | **Devise**                                         |
| Slugs / paging   | FriendlyId, Pagy                                   |
| Tests            | **RSpec**, FactoryBot, **Capybara + Selenium** (headless Chrome), shoulda-matchers |
| CI               | **GitHub Actions**                                 |
| Deploy           | **Docker** & **Heroku** (`app.json`, `Procfile`)   |

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
```

- `Topic` — a thread; text post (`body`) or link post (`url`).
- `Post` — a reply; `parent_id` makes replies a tree.
- `Vote` — a polymorphic upvote, unique per `(user, votable)`.
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
  broadcast_append_later_to topic,          # stream name = the topic
    target: "posts",                        # DOM id to append into
    partial: "posts/post", locals: { post: self }
  NotifyMentionsJob.perform_later(id)       # async @mention fan-out
end
```

Any browser on that topic page subscribes with one line in the view:

```erb
<%= turbo_stream_from @topic %>
```

The broadcast is enqueued (`_later_`) so it runs in Sidekiq, and Action Cable
(backed by Redis) delivers the rendered HTML fragment to every subscriber. The
same pattern drives live vote counts and the reputation badge.

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
password **`password123`**. The `admin` user can reach the Sidekiq dashboard at
`/sidekiq`.

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

CI (GitHub Actions, `.github/workflows/ci.yml`) runs three jobs on every push
and PR: **RuboCop lint**, the **RSpec** suite against Postgres + Redis service
containers, and the **Selenium system specs** with a real headless Chrome.

---

## Deployment

### Heroku (one click)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/xj16/forumforge)

The `app.json` provisions **Heroku Postgres** and **Heroku Redis**, runs
migrations on release, seeds on first deploy, and boots a `web` + `worker`
dyno (Sidekiq). The `Procfile` defines all three process types.

### Docker

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
  controllers/        # topics, posts, categories, users, leaderboard, Devise
  models/             # User, Category, Topic, Post, Vote, Reputation
  jobs/               # ReputationJob, NotifyMentionsJob (Sidekiq)
  views/              # ERB + Turbo Stream partials
  javascript/         # Stimulus controllers (reply toggle, flash auto-dismiss)
  assets/stylesheets/ # single hand-written CSS file (Propshaft, no build)
config/               # routes, environments, Sidekiq, Devise, importmap
db/migrate/           # schema migrations + friendly_id slugs
spec/                 # RSpec: models, requests, jobs, system (Capybara+Selenium)
.github/workflows/    # CI
Dockerfile, app.json, Procfile   # deployment
```

---

## License

[MIT](LICENSE) © 2026 xj16
