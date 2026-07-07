# frozen_string_literal: true

# Scans a newly created post body for @username mentions and fans out
# notifications to the mentioned users: an in-app Notification (which pushes a
# live bell update via Turbo Streams) plus an email via ForumMailer.
#
# Runs on the low-priority Sidekiq queue so it never slows down posting.
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
      Notification.notify(
        recipient: user,
        actor: post.user,
        notifiable: post,
        action: "mention"
      )
      ForumMailer.mention(user, post).deliver_later
    end
  end
end
