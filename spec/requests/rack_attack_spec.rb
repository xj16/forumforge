# frozen_string_literal: true

require "rails_helper"

# Rack::Attack is disabled in the test env by default (so other specs aren't
# throttled). Here we enable it explicitly and clear its cache around each
# example to prove the throttles actually engage.
RSpec.describe "Rate limiting (Rack::Attack)", type: :request do
  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    example.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  let(:user) { create(:user) }
  let(:topic) { create(:topic) }

  it "throttles a flood of upvotes with a 429" do
    sign_in user

    statuses = Array.new(35) do
      post upvote_topic_path(topic)
      response.status
    end

    expect(statuses).to include(429)
  end

  it "does not throttle a normal number of upvotes" do
    sign_in user
    5.times { post upvote_topic_path(topic) }
    expect(response.status).not_to eq(429)
  end

  it "throttles rapid sign-in attempts" do
    statuses = Array.new(15) do
      post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong" } }
      response.status
    end
    expect(statuses).to include(429)
  end
end
