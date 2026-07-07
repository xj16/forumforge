# frozen_string_literal: true

# Transactional emails for community activity. Currently: @mention notices,
# delivered async from NotifyMentionsJob. Deliveries are safe in every
# environment (test uses the :test delivery method; development typically
# :letter_opener or logs), so nothing here reaches a real inbox in CI.
class ForumMailer < ApplicationMailer
  # Notify `user` that they were @mentioned in `post`.
  def mention(user, post)
    @user = user
    @post = post
    @topic = post.topic
    @actor = post.user

    mail(
      to: @user.email,
      subject: "#{@actor.username} mentioned you on ForumForge"
    )
  end
end
