# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }

    it "requires a unique username (case-insensitive)" do
      create(:user, username: "taken")
      dup = build(:user, username: "TAKEN")
      expect(dup).not_to be_valid
    end

    it "rejects usernames with invalid characters" do
      expect(build(:user, username: "bad name!")).not_to be_valid
      expect(build(:user, username: "good_name1")).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:topics).dependent(:destroy) }
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:votes).dependent(:destroy) }
  end

  describe "#set_default_role" do
    it "defaults to member" do
      user = create(:user)
      expect(user.role).to eq("member")
    end
  end

  describe "roles" do
    it "treats admins as moderators too" do
      admin = build(:user, :admin)
      expect(admin).to be_admin
      expect(admin).to be_moderator
    end

    it "does not treat members as moderators" do
      expect(build(:user)).not_to be_moderator
    end
  end

  describe "#recalculate_reputation!" do
    it "sums points from topics, posts, and upvotes" do
      user = create(:user)
      topic = create(:topic, user: user)          # +2 created
      post  = create(:post, user: user, topic: topic) # +1 created
      create(:vote, votable: topic, user: create(:user)) # +10 upvote
      create(:vote, votable: post,  user: create(:user)) # +5 upvote

      user.recalculate_reputation!

      # topic upvote (10) + post upvote (5) + topic created (2) + post created (1) = 18
      expect(user.reload.reputation).to eq(18)
    end
  end

  describe "friendly id" do
    it "uses the username as the URL param" do
      user = create(:user, username: "ada")
      expect(user.to_param).to eq("ada")
    end
  end
end
