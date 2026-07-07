# frozen_string_literal: true

# Rate limiting / abuse protection via Rack::Attack.
#
# Throttles the write-heavy, spam-prone endpoints (voting, posting, topic
# creation) and brute-forceable sign-in, keyed per IP. A single generic 429
# response is returned when a client exceeds its budget.
#
# The store is an in-process memory store by default so the app (and the test
# suite) work without external state; point Rack::Attack at Redis in production
# by setting `config.cache.store` if you run multiple web processes.
class Rack::Attack
  # Dedicated cache so throttle counters never collide with Rails.cache (which
  # may be a :null_store in dev/test and would silently drop counts).
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Safelist ###############################################################

  # Never throttle the health check (load balancers / uptime monitors hit it
  # constantly). We deliberately do NOT blanket-safelist localhost: behind a
  # reverse proxy the real client IP is forwarded, and local traffic can still
  # be abusive, so the throttles below apply to it too.
  safelist("allow/health") { |req| req.path == "/up" }

  ### Throttles ##############################################################

  # Voting: bursty by nature, but a script could hammer it. 30 write-votes /
  # minute / IP is far above normal human use.
  throttle("votes/ip", limit: 30, period: 60.seconds) do |req|
    req.ip if req.post? && req.path.match?(%r{/upvote\z})
  end

  # Creating posts (replies) and topics: 15 / minute / IP.
  throttle("content/ip", limit: 15, period: 60.seconds) do |req|
    next unless req.post?

    creating_reply = req.path.match?(%r{\A/topics/[^/]+/posts\z})
    creating_topic = req.path == "/topics"
    req.ip if creating_reply || creating_topic
  end

  # Sign-in attempts: 10 / 20 seconds / IP throttles password guessing while
  # tolerating a fat-fingered human.
  throttle("logins/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.post? && req.path == "/users/sign_in"
  end

  ### Custom throttled response ##############################################

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
      ["Too many requests. Please slow down and try again shortly.\n"]
    ]
  end
end

# Disable throttling in the test environment by default so request/system specs
# aren't rate-limited; specs that exercise Rack::Attack re-enable it explicitly.
Rack::Attack.enabled = !Rails.env.test?
