# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search", type: :request do
  describe "GET /search" do
    it "renders the search page with matching topics" do
      create(:topic, title: "A thread about Hotwire and Turbo Streams")
      create(:topic, title: "Completely different subject")

      get search_path, params: { q: "hotwire turbo" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hotwire and Turbo Streams")
      expect(response.body).not_to include("Completely different subject")
    end

    it "highlights the matched terms" do
      create(:topic, title: "Postgres tsvector deep dive")
      get search_path, params: { q: "tsvector" }
      expect(response.body).to include("<mark>tsvector</mark>")
    end

    it "finds matching comments" do
      topic = create(:topic, title: "Host thread")
      create(:post, topic: topic, body: "a reply mentioning websockets specifically")

      get search_path, params: { q: "websockets" }
      expect(response.body).to include("websockets")
    end

    it "shows an empty state for no results" do
      get search_path, params: { q: "zzzznomatchzzzz" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No results")
    end

    it "handles a blank query gracefully" do
      get search_path, params: { q: "" }
      expect(response).to have_http_status(:ok)
    end

    it "answers a turbo-frame request with the results frame" do
      create(:topic, title: "Frameable searchable topic")
      get search_path, params: { q: "searchable" },
          headers: { "Turbo-Frame" => "search_results" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("search_results")
    end
  end
end
