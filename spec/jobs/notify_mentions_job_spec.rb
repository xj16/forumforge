# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyMentionsJob, type: :job do
  it "finds mentioned users without raising" do
    mentioned = create(:user, username: "grace")
    author = create(:user)
    topic = create(:topic)
    post = create(:post, topic: topic, user: author, body: "cc @grace please look")

    expect { described_class.perform_now(post.id) }.not_to raise_error
    expect(mentioned).to be_present
  end

  it "no-ops for a missing post" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
