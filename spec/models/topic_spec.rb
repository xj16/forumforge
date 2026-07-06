# frozen_string_literal: true

require "rails_helper"

RSpec.describe Topic, type: :model do
  subject { build(:topic) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(5).is_at_most(160) }

    it "requires a body or a url" do
      topic = build(:topic, body: nil, url: nil)
      expect(topic).not_to be_valid
      expect(topic.errors[:base]).to include("Provide either a body or a link URL")
    end

    it "accepts a link post with only a url" do
      expect(build(:topic, :link)).to be_valid
    end

    it "rejects an invalid url" do
      expect(build(:topic, url: "not a url", body: nil)).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:category).counter_cache(:topics_count) }
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:votes) }
  end

  describe "#link? and #domain" do
    it "detects link posts and extracts the domain" do
      topic = build(:topic, url: "https://www.github.com/xj16/forumforge", body: nil)
      expect(topic).to be_link
      expect(topic.domain).to eq("github.com")
    end

    it "treats text posts as non-links" do
      expect(build(:topic, url: nil)).not_to be_link
    end
  end

  describe "slugs" do
    it "generates a slug from the title" do
      topic = create(:topic, title: "Hello Turbo Streams")
      expect(topic.slug).to start_with("hello-turbo-streams")
    end
  end

  describe "sorting scopes" do
    it "orders newest first" do
      old = create(:topic, created_at: 2.days.ago)
      fresh = create(:topic, created_at: 1.hour.ago)
      expect(Topic.newest.first).to eq(fresh)
      expect(Topic.newest.last).to eq(old)
    end
  end
end
