# frozen_string_literal: true

require "rails_helper"

RSpec.describe VotedSet, type: :model do
  let(:user) { create(:user) }

  it "reports true for votables the user upvoted and false otherwise" do
    voted_topic   = create(:topic)
    unvoted_topic = create(:topic)
    create(:vote, user: user, votable: voted_topic)

    set = described_class.for(user, [voted_topic, unvoted_topic])

    expect(set.voted?(voted_topic)).to be(true)
    expect(set.voted?(unvoted_topic)).to be(false)
  end

  it "handles a mix of topics and posts" do
    topic = create(:topic)
    post = create(:post, topic: topic)
    create(:vote, user: user, votable: post)

    set = described_class.for(user, [topic, post])

    expect(set.voted?(post)).to be(true)
    expect(set.voted?(topic)).to be(false)
  end

  it "loads the whole page's vote state in a single query" do
    topics = create_list(:topic, 5)
    topics.first(3).each { |t| create(:vote, user: user, votable: t) }

    set = nil
    query_count = count_queries { set = described_class.for(user, topics) }

    expect(set.size).to eq(3)
    # One SELECT for the topics group — not one per row.
    expect(query_count).to eq(1)
  end

  it "returns an empty set (and runs no queries) when signed out" do
    topic = create(:topic)
    query_count = count_queries { @set = described_class.for(nil, [topic]) }
    expect(@set.voted?(topic)).to be(false)
    expect(query_count).to eq(0)
  end

  it "returns an empty set for an empty collection" do
    expect(described_class.for(user, []).size).to eq(0)
  end

  # Counts the ActiveRecord SELECT queries run inside the block (ignoring
  # SCHEMA / transaction noise).
  def count_queries(&block)
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name] == "SCHEMA"
      next if %w[BEGIN COMMIT ROLLBACK].include?(payload[:sql])

      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
