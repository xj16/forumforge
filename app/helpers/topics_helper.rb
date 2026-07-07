# frozen_string_literal: true

module TopicsHelper
  SORTS = %w[hot new top].freeze

  def sort_links(current)
    safe_join(
      SORTS.map do |sort|
        active = (current || "hot") == sort
        link_to sort.capitalize, topics_path(sort: sort, category: params[:category]),
                class: "sort-link#{' sort-link--active' if active}"
      end,
      " "
    )
  end

  # Whether `user` has upvoted `votable`.
  #
  # Prefers a preloaded VotedSet (`voted`), which answers from memory with zero
  # queries — this is what controller-rendered pages pass so the feed and thread
  # have no per-row vote N+1. When no set is available (e.g. a Turbo Stream
  # broadcast re-rendering a single row) it falls back to a scoped existence
  # check for just that one record.
  def voted_by?(votable, user, voted = nil)
    return false if user.nil?
    return voted.voted?(votable) if voted

    votable.votes.exists?(user_id: user.id)
  end
end
