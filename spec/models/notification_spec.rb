# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:recipient) { create(:user) }
  let(:actor) { create(:user) }
  let(:topic) { create(:topic, user: recipient) }

  describe ".notify" do
    it "creates a notification for a valid action" do
      expect {
        described_class.notify(recipient: recipient, actor: actor, notifiable: topic, action: "mention")
      }.to change(described_class, :count).by(1)
    end

    it "skips self-notifications" do
      expect {
        described_class.notify(recipient: actor, actor: actor, notifiable: topic, action: "reply")
      }.not_to change(described_class, :count)
    end

    it "does not duplicate an existing unread notification" do
      described_class.notify(recipient: recipient, actor: actor, notifiable: topic, action: "mention")
      expect {
        described_class.notify(recipient: recipient, actor: actor, notifiable: topic, action: "mention")
      }.not_to change(described_class, :count)
    end

    it "creates a fresh one after the previous was read" do
      first = described_class.notify(recipient: recipient, actor: actor, notifiable: topic, action: "mention")
      first.update!(read_at: Time.current)
      expect {
        described_class.notify(recipient: recipient, actor: actor, notifiable: topic, action: "mention")
      }.to change(described_class, :count).by(1)
    end

    it "returns nil when actor or recipient is nil" do
      expect(described_class.notify(recipient: nil, actor: actor, notifiable: topic, action: "mention")).to be_nil
    end
  end

  describe "validation" do
    it "rejects an unknown action" do
      n = described_class.new(recipient: recipient, actor: actor, notifiable: topic, action: "bogus")
      expect(n).not_to be_valid
    end
  end

  describe ".unread_count_for" do
    it "counts only unread notifications for the given user" do
      described_class.notify(recipient: recipient, actor: actor, notifiable: topic, action: "mention")
      read = described_class.notify(recipient: recipient, actor: create(:user), notifiable: topic, action: "reply")
      read.update!(read_at: Time.current)

      expect(described_class.unread_count_for(recipient)).to eq(1)
    end

    it "is zero for a nil user" do
      expect(described_class.unread_count_for(nil)).to eq(0)
    end
  end

  describe "#summary and #target_path" do
    it "describes a post reply and links to it" do
      post = create(:post, topic: topic, user: actor)
      n = described_class.notify(recipient: recipient, actor: actor, notifiable: post, action: "reply")
      expect(n.summary).to eq("replied to you")
      expect(n.target_path).to include("/topics/")
    end
  end
end
