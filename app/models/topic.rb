# frozen_string_literal: true

# A discussion thread. Supports two flavours:
#   * text posts  (body present, url blank)
#   * link posts  (url present) -> the link-aggregation use case
#
# Live updates are pushed to subscribers via Turbo Streams (see the
# `after_create_commit`/`broadcasts_to` hooks below and TopicsController).
class Topic < ApplicationRecord
  extend FriendlyId
  include ActionView::RecordIdentifier # provides dom_id for broadcast lambdas

  friendly_id :slug_candidates, use: %i[slugged history]

  belongs_to :user
  belongs_to :category, counter_cache: :topics_count
  has_many :posts, dependent: :destroy
  has_many :votes, as: :votable, dependent: :destroy

  validates :title, presence: true, length: { in: 5..160 }
  validates :body, length: { maximum: 20_000 }
  validate :body_or_url_present
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http(s) URL" },
                  allow_blank: true

  # Denormalised counters kept in sync by Vote and Post callbacks.
  # upvotes_count and posts_count are backed by real columns.

  scope :hot, -> { order(Arel.sql("(topics.upvotes_count + 1) / POWER(EXTRACT(EPOCH FROM (NOW() - topics.created_at)) / 3600 + 2, 1.5) DESC")) }
  scope :newest, -> { order(created_at: :desc) }
  scope :top, -> { order(upvotes_count: :desc, created_at: :desc) }

  # Live-update every topic index/show subscribed to the "topics" stream.
  after_create_commit -> { broadcast_prepend_to "topics", target: "topics", partial: "topics/topic" }
  after_update_commit -> { broadcast_replace_to "topics", target: dom_id(self), partial: "topics/topic" }
  after_destroy_commit -> { broadcast_remove_to "topics", target: dom_id(self) }

  # A link post points elsewhere; a text post is self-contained.
  def link?
    url.present?
  end

  # Host shown next to link posts, e.g. "github.com".
  def domain
    return nil unless link?

    URI.parse(url).host&.sub(/\Awww\./, "")
  rescue URI::InvalidURIError
    nil
  end

  private

  def slug_candidates
    [
      :title,
      %i[title id]
    ]
  end

  def body_or_url_present
    return if body.present? || url.present?

    errors.add(:base, "Provide either a body or a link URL")
  end
end
