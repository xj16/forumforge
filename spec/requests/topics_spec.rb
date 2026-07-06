# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Topics", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  describe "GET /" do
    it "renders the hot feed" do
      create(:topic, title: "A visible topic for the feed")
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("A visible topic for the feed")
    end
  end

  describe "GET /topics/:id" do
    it "shows a topic and its replies" do
      topic = create(:topic)
      create(:post, topic: topic, body: "A reply that should appear")
      get topic_path(topic)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("A reply that should appear")
    end
  end

  describe "POST /topics" do
    context "when signed in" do
      before { sign_in user }

      it "creates a text topic" do
        expect {
          post topics_path, params: {
            topic: { title: "My brand new topic", body: "With a body", category_id: category.id }
          }
        }.to change(Topic, :count).by(1)
        expect(response).to have_http_status(:found)
      end

      it "creates a link topic" do
        expect {
          post topics_path, params: {
            topic: { title: "Cool link I found", url: "https://example.com", category_id: category.id }
          }
        }.to change(Topic, :count).by(1)
      end

      it "rejects an invalid topic" do
        expect {
          post topics_path, params: { topic: { title: "x", category_id: category.id } }
        }.not_to change(Topic, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when signed out" do
      it "redirects to sign in" do
        post topics_path, params: { topic: { title: "Nope", body: "no", category_id: category.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "authorization" do
    it "prevents editing someone else's topic" do
      topic = create(:topic)
      sign_in user
      get edit_topic_path(topic)
      expect(response).to redirect_to(topic_path(topic))
    end
  end

  describe "upvoting" do
    before { sign_in user }

    it "records an upvote" do
      topic = create(:topic)
      expect {
        post upvote_topic_path(topic)
      }.to change { topic.reload.upvotes_count }.by(1)
    end

    it "removes an upvote" do
      topic = create(:topic)
      create(:vote, user: user, votable: topic)
      expect {
        delete upvote_topic_path(topic)
      }.to change { topic.reload.upvotes_count }.by(-1)
    end
  end
end
