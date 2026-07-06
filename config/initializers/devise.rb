# frozen_string_literal: true

Devise.setup do |config|
  # The secret key used by Devise. Falls back to secret_key_base.
  config.secret_key = ENV["DEVISE_SECRET_KEY"] if ENV["DEVISE_SECRET_KEY"].present?

  # ==> Mailer Configuration
  config.mailer_sender = ENV.fetch("MAILER_SENDER", "no-reply@forumforge.example")

  # ==> ORM configuration
  require "devise/orm/active_record"

  # ==> Configuration for any authentication mechanism
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]

  # ==> Configuration for :database_authenticatable
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true

  # ==> Configuration for :rememberable
  config.expire_all_remember_me_on_sign_out = true

  # ==> Configuration for :validatable
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Configuration for :recoverable
  config.reset_password_within = 6.hours

  # ==> Navigation configuration
  config.sign_out_via = :delete

  # ==> Hotwire/Turbo configuration
  # Send a 303 See Other status code for Turbo compatibility on destroy/logout.
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
