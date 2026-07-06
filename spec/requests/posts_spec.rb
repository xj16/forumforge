# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }
  let(:topic) { create(:topic) }

  describe "POST /topics/:topic_id/posts" do
    before { sign_in user }

    it "creates a reply" do
      expect {
        post topic_posts_path(topic), params: { post: { body: "A great reply here" } }
      }.to change(Post, :count).by(1)
    end

    it "creates a nested reply" do
      parent = create(:post, topic: topic)
      expect {
        post topic_posts_path(topic), params: { post: { body: "Nested", parent_id: parent.id } }
      }.to change(Post, :count).by(1)
      expect(Post.last.parent).to eq(parent)
    end

    it "rejects a blank reply" do
      expect {
        post topic_posts_path(topic), params: { post: { body: "" } }
      }.not_to change(Post, :count)
    end
  end

  describe "DELETE /topics/:topic_id/posts/:id" do
    it "lets an author delete their reply" do
      sign_in user
      reply = create(:post, topic: topic, user: user)
      expect {
        delete topic_post_path(topic, reply)
      }.to change(Post, :count).by(-1)
    end

    it "prevents deleting someone else's reply" do
      sign_in user
      reply = create(:post, topic: topic)
      expect {
        delete topic_post_path(topic, reply)
      }.not_to change(Post, :count)
    end
  end
end
