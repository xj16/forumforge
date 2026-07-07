# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyMentionsJob, type: :job do
  it "creates a notification for a mentioned user" do
    mentioned = create(:user, username: "grace")
    author = create(:user)
    topic = create(:topic)
    post = create(:post, topic: topic, user: author, body: "cc @grace please look")

    expect {
      described_class.perform_now(post.id)
    }.to change { Notification.where(recipient: mentioned, action: "mention").count }.by(1)
  end

  it "enqueues a mention email to the mentioned user" do
    create(:user, username: "grace")
    author = create(:user)
    post = create(:post, user: author, body: "hey @grace look at this")

    expect {
      described_class.perform_now(post.id)
    }.to have_enqueued_mail(ForumMailer, :mention)
  end

  it "does not notify the author when they mention themselves" do
    author = create(:user, username: "selfmention")
    post = create(:post, user: author, body: "note to self @selfmention")

    expect {
      described_class.perform_now(post.id)
    }.not_to change(Notification, :count)
  end

  it "no-ops for a missing post" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end

  it "no-ops when there are no mentions" do
    post = create(:post, body: "plain text with no mentions")
    expect { described_class.perform_now(post.id) }.not_to change(Notification, :count)
  end
end
