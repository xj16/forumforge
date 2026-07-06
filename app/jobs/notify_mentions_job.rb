# frozen_string_literal: true

# Scans a newly created post body for @username mentions and (in a real
# deployment) would notify the mentioned users by email. Kept lightweight and
# side-effect-free here so it is safe to run in CI, but demonstrates the async
# fan-out pattern on the `low` priority Sidekiq queue.
class NotifyMentionsJob < ApplicationJob
  queue_as :low

  MENTION_PATTERN = /@([a-zA-Z0-9_]{3,30})/

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return if post.nil?

    usernames = post.body.scan(MENTION_PATTERN).flatten.uniq
    return if usernames.empty?

    mentioned = User.where(username: usernames).where.not(id: post.user_id)
    mentioned.find_each do |user|
      Rails.logger.info("[NotifyMentionsJob] #{user.username} mentioned in post ##{post.id}")
      # ForumMailer.mention(user, post).deliver_later  # wired up in production
    end
  end
end
