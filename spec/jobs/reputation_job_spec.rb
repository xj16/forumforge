# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReputationJob, type: :job do
  it "recalculates the user's reputation" do
    user = create(:user)
    topic = create(:topic, user: user)
    create(:vote, votable: topic, user: create(:user))

    described_class.perform_now(user.id)

    # topic created (2) + topic upvote (10) = 12
    expect(user.reload.reputation).to eq(12)
  end

  it "no-ops for a missing user" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
