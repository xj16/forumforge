# frozen_string_literal: true

# A registered community member.
#
# Authentication is handled by Devise. Reputation is a denormalized integer
# kept up to date by the ReputationJob whenever a user's content is voted on.
class User < ApplicationRecord
  extend FriendlyId
  friendly_id :username, use: :slugged

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :topics, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy

  ROLES = %w[member moderator admin].freeze

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { in: 3..30 },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers and underscores" }
  validates :role, inclusion: { in: ROLES }

  before_validation :set_default_role, on: :create

  # Reputation is never negative in the UI, but we store the raw value.
  def reputation
    self[:reputation] || 0
  end

  def admin?
    role == "admin"
  end

  def moderator?
    role == "moderator" || admin?
  end

  # Recalculate reputation from scratch based on all of this user's content.
  # Called by ReputationJob so voting stays snappy for the requester.
  def recalculate_reputation!
    topic_points = topics.sum(:upvotes_count) * Reputation::TOPIC_UPVOTE
    post_points  = posts.sum(:upvotes_count) * Reputation::POST_UPVOTE
    creation_points = topics.count * Reputation::TOPIC_CREATED + posts.count * Reputation::POST_CREATED
    update_column(:reputation, topic_points + post_points + creation_points)
  end

  # Used by FriendlyId as the URL slug.
  def to_param
    username
  end

  private

  def set_default_role
    self.role ||= "member"
  end

  def should_generate_new_friendly_id?
    username_changed? || super
  end
end
