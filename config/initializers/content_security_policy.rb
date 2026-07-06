# frozen_string_literal: true

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# The policy (and its nonces) is only enabled in production. In development and
# test we leave it off so importmap's inline <script type="importmap"> and the
# Hotwire bootstrap scripts run unhindered — a robust nonce requires a session
# id, which is empty for fresh test requests and would otherwise emit an invalid
# `'nonce-'` source that blocks all inline scripts.
if Rails.env.production?
  Rails.application.configure do
    config.content_security_policy do |policy|
      policy.default_src :self, :https
      policy.font_src    :self, :https, :data
      policy.img_src     :self, :https, :data
      policy.object_src  :none
      policy.script_src  :self, :https
      policy.style_src   :self, :https
    end

    # Generate session-nonces for permitted inline <script>/<style> (importmap).
    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s.presence || SecureRandom.base64(16) }
    config.content_security_policy_nonce_directives = %w[script-src style-src]
  end
end
