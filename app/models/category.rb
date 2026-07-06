# frozen_string_literal: true

# A top-level grouping for topics (e.g. "General", "Programming", "Meta").
class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :topics, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { in: 2..50 }
  validates :description, length: { maximum: 280 }, allow_blank: true

  # Categories ordered by their configured position, then name.
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end
end
