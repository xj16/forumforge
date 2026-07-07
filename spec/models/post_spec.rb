# frozen_string_literal: true

require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    subject { build(:post) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_least(1).is_at_most(10_000) }

    it "requires the parent to share the same topic" do
      topic_a = create(:topic)
      topic_b = create(:topic)
      parent = create(:post, topic: topic_a)
      child = build(:post, topic: topic_b, parent: parent)
      expect(child).not_to be_valid
      expect(child.errors[:parent]).to include("must belong to the same topic")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:topic).counter_cache(:posts_count) }
    it { is_expected.to belong_to(:parent).class_name("Post").optional }
    it { is_expected.to have_many(:replies).class_name("Post").dependent(:destroy) }
  end

  describe "#depth" do
    it "is 0 for a top-level post" do
      expect(create(:post).depth).to eq(0)
    end

    it "increases with nesting" do
      topic = create(:topic)
      root = create(:post, topic: topic)
      child = create(:post, topic: topic, parent: root)
      grandchild = create(:post, topic: topic, parent: child)
      expect(child.depth).to eq(1)
      expect(grandchild.depth).to eq(2)
    end
  end

  describe "counter cache" do
    it "increments the topic posts_count" do
      topic = create(:topic)
      expect { create(:post, topic: topic) }.to change { topic.reload.posts_count }.by(1)
    end
  end

  describe "mention notifications" do
    it "enqueues a NotifyMentionsJob after creation" do
      expect {
        create(:post, body: "hey @ada what do you think?")
      }.to have_enqueued_job(NotifyMentionsJob)
    end
  end

  describe "reply notifications" do
    it "notifies the topic author of a top-level reply" do
      topic = create(:topic)
      expect {
        create(:post, topic: topic, user: create(:user))
      }.to change {
        Notification.where(recipient: topic.user, action: "reply").count
      }.by(1)
    end

    it "notifies the parent comment's author of a nested reply" do
      topic = create(:topic)
      parent = create(:post, topic: topic, user: create(:user))
      expect {
        create(:post, topic: topic, parent: parent, user: create(:user))
      }.to change {
        Notification.where(recipient: parent.user, action: "reply").count
      }.by(1)
    end

    it "does not notify the author for their own reply" do
      topic = create(:topic)
      expect {
        create(:post, topic: topic, user: topic.user)
      }.not_to change(Notification, :count)
    end
  end
end
