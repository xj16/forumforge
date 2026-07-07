require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# Asset pipeline handled by Propshaft (loaded via Bundler.require below).

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ForumForge
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # Use Sidekiq for background jobs.
    config.active_job.queue_adapter = :sidekiq

    # Rate limiting / abuse protection (see config/initializers/rack_attack.rb).
    config.middleware.use Rack::Attack

    # Generators: use RSpec and FactoryBot.
    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        request_specs: true
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    # Time zone.
    config.time_zone = "UTC"
  end
end
