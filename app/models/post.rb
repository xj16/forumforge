# frozen_string_literal: true

# A reply within a topic. Posts form a threaded tree via the self-referential
# `parent` association, so users can reply to individual replies.
#
# New and updated posts are broadcast to everyone viewing the parent topic via
# Turbo Streams, giving live-updating threads without a page refresh.
class Post < ApplicationRecord
  include Searchable # full-text search over body via search_vector

  belongs_to :user
  belongs_to :topic, counter_cache: :posts_count, touch: true
  belongs_to :parent, class_name: "Post", optional: true, counter_cache: false

  has_many :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy
  has_many :votes, as: :votable, dependent: :destroy

  validates :body, presence: true, length: { in: 1..10_000 }
  validate :parent_belongs_to_same_topic

  scope :roots, -> { where(parent_id: nil) }
  scope :chronological, -> { order(created_at: :asc) }

  # Live-update the thread: append new top-level replies, replace edited ones.
  after_create_commit :broadcast_created
  after_update_commit -> { broadcast_replace_to topic, target: dom_id(self), partial: "posts/post", locals: { post: self } }
  after_destroy_commit -> { broadcast_remove_to topic, target: dom_id(self) }

  # Depth in the reply tree (0 for top-level replies). Capped for rendering.
  def depth
    d = 0
    node = self
    while node.parent_id && d < 8
      node = node.parent
      d += 1
    end
    d
  end

  private

  include ActionView::RecordIdentifier

  def broadcast_created
    target = parent_id ? "replies_#{parent_id}" : "posts"
    # Synchronous broadcast (not the _later_ variant): delivery does not depend
    # on a background worker being drained, which keeps live updates instant and
    # makes system specs deterministic.
    broadcast_append_to topic, target: target, partial: "posts/post", locals: { post: self }
    NotifyMentionsJob.perform_later(id)
    notify_reply_recipient
  end

  # Tell the author of the thing being replied to that they got a reply. A reply
  # to a comment notifies that comment's author; a top-level reply notifies the
  # topic's author. Notification.notify skips self-replies and duplicates.
  def notify_reply_recipient
    recipient = parent ? parent.user : topic.user
    Notification.notify(
      recipient: recipient,
      actor: user,
      notifiable: self,
      action: "reply"
    )
  rescue StandardError => e
    Rails.logger.warn("[Post] reply notification failed: #{e.message}")
  end

  def parent_belongs_to_same_topic
    return if parent.nil?
    return if parent.topic_id == topic_id

    errors.add(:parent, "must belong to the same topic")
  end
end
