# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vote, type: :model do
  describe "uniqueness" do
    it "prevents a user from voting twice on the same votable" do
      user = create(:user)
      topic = create(:topic)
      create(:vote, user: user, votable: topic)
      dup = build(:vote, user: user, votable: topic)
      expect(dup).not_to be_valid
    end

    it "allows the same user to vote on different votables" do
      user = create(:user)
      t1 = create(:topic)
      t2 = create(:topic)
      create(:vote, user: user, votable: t1)
      expect(build(:vote, user: user, votable: t2)).to be_valid
    end
  end

  describe "counter caching" do
    it "increments the votable's upvotes_count on create" do
      topic = create(:topic)
      expect { create(:vote, votable: topic) }.to change { topic.reload.upvotes_count }.by(1)
    end

    it "decrements the votable's upvotes_count on destroy" do
      topic = create(:topic)
      vote = create(:vote, votable: topic)
      expect { vote.destroy }.to change { topic.reload.upvotes_count }.by(-1)
    end
  end

  describe "reputation side effects" do
    it "enqueues a ReputationJob for the content author" do
      topic = create(:topic)
      expect {
        create(:vote, votable: topic)
      }.to have_enqueued_job(ReputationJob).with(topic.user_id)
    end
  end
end
