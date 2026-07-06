# frozen_string_literal: true

# Recomputes a user's reputation off the request path. Enqueued by Vote and by
# Topic/Post creation. Runs on the `default` Sidekiq queue backed by Redis.
class ReputationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil?

    user.recalculate_reputation!
    # Live-update any leaderboard / profile badge showing this user's score.
    broadcast_reputation(user)
  end

  private

  def broadcast_reputation(user)
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}",
      target: "reputation_#{user.id}",
      partial: "users/reputation_badge",
      locals: { user: user }
    )
  rescue StandardError => e
    Rails.logger.warn("[ReputationJob] broadcast failed: #{e.message}")
  end
end
