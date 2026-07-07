source "https://rubygems.org"

# Any Ruby 3.2 or 3.3 works. CI and the Dockerfile pin a concrete patch.
ruby ">= 3.2.0", "< 3.4"

# Core framework
gem "rails", "~> 7.1.3"

# Database
gem "pg", "~> 1.5"

# App server
gem "puma", ">= 6.4"

# Asset pipeline & Hotwire
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# JSON / view helpers
gem "jbuilder"

# Authentication
gem "devise", "~> 4.9"

# Background jobs on Redis
gem "sidekiq", "~> 8.1"
gem "redis", "~> 5.0"

# Pagination & slugs
gem "pagy", "~> 8.0"
gem "friendly_id", "~> 5.5"

# Rate limiting / abuse protection (throttles votes, posts, sign-in — see
# config/initializers/rack_attack.rb).
gem "rack-attack", "~> 6.7"

# Windows/JRuby timezone data
gem "tzinfo-data", platforms: %i[windows jruby]

# Boot time
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
  gem "rubocop-rails-omakase", require: false
  # Audits Gemfile.lock against the Ruby Advisory DB (also run in CI).
  gem "bundler-audit", "~> 0.9", require: false
end

group :test do
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.18"
  gem "shoulda-matchers", "~> 6.1"
  gem "database_cleaner-active_record", "~> 2.1"
  # Test coverage reporting (writes coverage/ and a SimpleCov summary).
  gem "simplecov", "~> 0.22", require: false
end
