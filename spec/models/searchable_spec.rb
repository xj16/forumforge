# frozen_string_literal: true

require "rails_helper"

# Exercises the Postgres full-text search concern end to end against a real
# database (generated tsvector columns + GIN indexes are created by migration
# 20260201000001). Covers ranking, matching, blank handling, injection safety,
# and XSS-safe highlighting.
RSpec.describe Searchable, type: :model do
  describe "Topic.search" do
    it "finds topics by title and body, and misses non-matches" do
      hit = create(:topic, title: "Understanding Postgres tsvector", body: "full text search rocks")
      _miss = create(:topic, title: "An unrelated thread about cats", body: "meow")

      results = Topic.search("postgres search")
      expect(results).to include(hit)
      expect(results.count).to eq(1)
    end

    it "ranks a title match above a body-only match for the same term" do
      title_match = create(:topic, title: "Kubernetes in production", body: "ops stuff")
      body_match  = create(:topic, title: "Weekend project", body: "I deployed to kubernetes finally")

      results = Topic.search("kubernetes").to_a
      expect(results.first).to eq(title_match)
      expect(results).to include(body_match)
    end

    it "matches link topics by their URL host" do
      topic = create(:topic, :link, title: "A cool read", url: "https://hotwired.dev/handbook")
      expect(Topic.search("hotwired.dev")).to include(topic)
    end

    it "returns an empty relation for a blank query without hitting the DB hard" do
      create(:topic, title: "Something searchable here")
      expect(Topic.search("")).to be_empty
      expect(Topic.search("   ")).to be_empty
      expect(Topic.search(nil)).to be_empty
    end

    it "is safe against SQL injection in the query string" do
      create(:topic, title: "Safe topic")
      malicious = "'; DROP TABLE topics; --"
      expect { Topic.search(malicious).to_a }.not_to raise_error
      expect(Topic.count).to be >= 1
    end
  end

  describe "Post.search" do
    it "finds posts by body" do
      topic = create(:topic)
      hit = create(:post, topic: topic, body: "The migration ran cleanly on staging")
      _miss = create(:post, topic: topic, body: "totally different content")

      expect(Post.search("migration staging")).to include(hit)
      expect(Post.search("migration staging")).not_to include(_miss)
    end
  end

  describe "#search_highlight" do
    it "wraps matched terms in <mark> tags" do
      topic = create(:topic, title: "Learning about tsvector ranking")
      snippet = topic.search_highlight(:title, "tsvector")
      expect(snippet).to include("<mark>tsvector</mark>")
    end

    it "escapes HTML in the source text (no XSS via stored content)" do
      topic = create(:topic, title: "Danger", body: "hello <script>alert(1)</script> world")
      snippet = topic.search_highlight(:body, "hello")

      expect(snippet).to include("<mark>hello</mark>")
      # The stored <script> must be neutralised, not passed through raw.
      expect(snippet).not_to include("<script>")
      expect(snippet).to include("&lt;script&gt;")
    end

    it "returns a plain truncation for a blank query" do
      topic = create(:topic, body: "just some ordinary body text")
      expect(topic.search_highlight(:body, "")).to include("ordinary")
    end
  end
end
