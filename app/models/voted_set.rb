# frozen_string_literal: true

# A precomputed set of "(votable_type, votable_id)" pairs the viewer has
# upvoted. Built with ONE query for a whole page of votables, this kills the
# per-row `votable.votes.exists?(user_id:)` N+1 that otherwise fired once per
# topic in the feed and once per comment in a thread.
#
# Usage:
#   @voted = VotedSet.for(current_user, @topics)      # 1 query (or 0 if signed out)
#   @voted.voted?(topic)                              # in-memory Set lookup
#
# Passed down to the vote partials, which consult it instead of hitting the DB.
class VotedSet
  # A shared empty set for signed-out requests / blank collections.
  def self.none
    new(Set.new)
  end

  # Build the set for `user` over `votables` (any mix of Topics and Posts).
  def self.for(user, votables)
    return none if user.nil?

    votables = Array(votables).compact
    return none if votables.empty?

    grouped = votables.group_by { |v| v.class.base_class.name }
    pairs = Set.new

    grouped.each do |type, records|
      ids = records.map(&:id)
      user.votes
          .where(votable_type: type, votable_id: ids)
          .pluck(:votable_id)
          .each { |id| pairs << [type, id] }
    end

    new(pairs)
  end

  def initialize(pairs)
    @pairs = pairs
  end

  # True if the viewer has upvoted `votable`. Pure in-memory lookup.
  def voted?(votable)
    return false if votable.nil?

    @pairs.include?([votable.class.base_class.name, votable.id])
  end

  # Number of tracked upvotes (handy in specs).
  def size
    @pairs.size
  end
end
