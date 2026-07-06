# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"
require "selenium-webdriver"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]

  # DatabaseCleaner (see spec/support/database_cleaner.rb) owns test isolation
  # with the :deletion strategy. Unlike a wrapping transaction, deletion lets
  # `after_commit` / `after_create_commit` callbacks fire (which this app relies
  # on for counter caches, reputation jobs, and Turbo broadcasts) and works
  # across the separate DB connection used by the Selenium browser in JS specs.
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Devise helpers for controller/request specs.
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  # FactoryBot short syntax: `create`, `build`, etc.
  config.include FactoryBot::Syntax::Methods

  # Configure Capybara + Selenium (headless Chrome) for system specs.
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
    end
    # Run enqueued jobs inline so Turbo Stream broadcasts are actually delivered
    # to the browser during JS specs.
    ActiveJob::Base.queue_adapter = :inline
  end

  config.after(:each, type: :system, js: true) do
    ActiveJob::Base.queue_adapter = :test
  end
end

# shoulda-matchers configuration.
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
