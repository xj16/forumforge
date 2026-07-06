# frozen_string_literal: true

require "database_cleaner/active_record"

# DatabaseCleaner owns all test isolation.
#
# We use the :deletion strategy (rather than :transaction) for two reasons:
#   1. `after_commit` / `after_create_commit` callbacks fire — this app depends
#      on them for counter caches, reputation jobs, and Turbo Stream broadcasts,
#      and a wrapping transaction would swallow those callbacks.
#   2. JS system specs run the app on a separate DB connection (the Selenium
#      browser), which cannot see data created inside another connection's
#      transaction. Deletion commits, so the browser sees the fixtures.
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:deletion)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end
