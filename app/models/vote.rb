# frozen_string_literal: true

# An upvote on a votable (Topic or Post). A user may upvote a given votable at
# most once, enforced by a composite unique index.
#
# After a vote is created or destroyed we:
#   1. keep the votable's `upvotes_count` column in sync, and
#   2. enqueue a ReputationJob to recompute the content author's reputation
#      off the request path (Sidekiq / Redis).
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :votable, polymorphic: true

  validates :user_id, uniqueness: { scope: %i[votable_type votable_id] }

  after_create_commit :increment_and_reward
  after_destroy_commit :decrement_and_penalize

  private

  def increment_and_reward
    votable.class.increment_counter(:upvotes_count, votable_id)
    ReputationJob.perform_later(votable.user_id)
  end

  def decrement_and_penalize
    votable.class.decrement_counter(:upvotes_count, votable_id)
    ReputationJob.perform_later(votable.user_id)
  end
end
