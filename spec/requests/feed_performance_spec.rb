# frozen_string_literal: true

require "rails_helper"

# Locks in the N+1 fix: rendering the feed (and a thread) for a signed-in user
# must load the viewer's vote state in a bounded number of queries, not one per
# rendered row. We count queries that touch the `votes` table specifically, so
# the assertion targets the vote N+1 directly and is not coupled to unrelated
# query counts (pagination, preloads, etc.).
RSpec.describe "Feed performance", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  # Counts SELECTs against the `votes` table run inside the block.
  def count_vote_queries
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name] == "SCHEMA"

      sql = payload[:sql].to_s
      count += 1 if sql.match?(/\bFROM\s+"?votes"?/i)
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  it "loads feed vote-state in a constant number of vote queries regardless of size" do
    create_list(:topic, 3).each { |t| create(:vote, user: user, votable: t) }
    small = count_vote_queries { get root_path }
    expect(response).to have_http_status(:ok)

    create_list(:topic, 12).each { |t| create(:vote, user: user, votable: t) }
    large = count_vote_queries { get root_path }
    expect(response).to have_http_status(:ok)

    # A per-row `exists?` would make this scale with the number of topics; the
    # preloaded VotedSet keeps it at a single query for the whole page.
    expect(small).to be <= 1
    expect(large).to be <= 1
  end

  it "loads a thread's vote-state without a per-comment vote query" do
    topic = create(:topic)
    5.times { create(:post, topic: topic, user: create(:user)) }
    topic.posts.each { |p| create(:vote, user: user, votable: p) }
    create(:vote, user: user, votable: topic)

    small = count_vote_queries { get topic_path(topic) }
    expect(response).to have_http_status(:ok)

    10.times { create(:post, topic: topic, user: create(:user)) }
    topic.posts.each { |p| Vote.find_or_create_by(user: user, votable: p) }

    large = count_vote_queries { get topic_path(topic) }
    expect(response).to have_http_status(:ok)

    # The whole thread's vote state is one preloaded query (topic + posts),
    # so tripling the comment count must not multiply vote queries.
    expect(small).to be <= 2
    expect(large).to be <= 2
  end
end
