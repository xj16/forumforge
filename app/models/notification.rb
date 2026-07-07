# frozen_string_literal: true

# An in-app notification delivered to a user.
#
# Created off the request path (mentions run in NotifyMentionsJob; replies and
# upvotes create them inline) and pushed live to the recipient's browser via a
# per-user Turbo Stream so the header bell's unread count updates without a
# reload. See Notification.notify and #broadcast_bell.
class Notification < ApplicationRecord
  include ActionView::RecordIdentifier

  # Known action types. `action` is validated against this list so a typo can't
  # silently create an unrenderable notification.
  ACTIONS = %w[mention reply topic_upvote post_upvote].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  validates :action, inclusion: { in: ACTIONS }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_bell

  # Create a notification unless it would be pointless (self-notification) or a
  # duplicate of an existing unread one for the same actor/notifiable/action.
  # Returns the notification, or nil if it was skipped.
  def self.notify(recipient:, actor:, notifiable:, action:)
    return if recipient.nil? || actor.nil? || recipient.id == actor.id

    existing = unread.find_by(
      recipient: recipient, actor: actor,
      notifiable: notifiable, action: action
    )
    return existing if existing

    create(recipient: recipient, actor: actor, notifiable: notifiable, action: action)
  end

  # Count of unread notifications for a user (drives the bell badge).
  def self.unread_count_for(user)
    return 0 if user.nil?

    where(recipient_id: user.id, read_at: nil).count
  end

  def read?
    read_at.present?
  end

  # Human-readable verb phrase for the inbox / bell.
  def summary
    case action
    when "mention"      then "mentioned you"
    when "reply"        then "replied to you"
    when "topic_upvote" then "upvoted your topic"
    when "post_upvote"  then "upvoted your reply"
    else action.tr("_", " ")
    end
  end

  # Where clicking the notification should take the recipient.
  def target_path
    routes = Rails.application.routes.url_helpers
    case notifiable
    when Post then routes.topic_path(notifiable.topic, anchor: dom_id(notifiable))
    when Topic then routes.topic_path(notifiable)
    end
  end

  private

  # Push the recipient's fresh unread count to their subscribed browsers.
  def broadcast_bell
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{recipient_id}_notifications",
      target: "notification_bell",
      partial: "notifications/bell",
      locals: { count: self.class.unread_count_for(recipient) }
    )
  rescue StandardError => e
    Rails.logger.warn("[Notification] bell broadcast failed: #{e.message}")
  end
end
