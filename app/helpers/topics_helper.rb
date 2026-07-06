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

  def voted_by?(votable, user)
    return false if user.nil?

    votable.votes.exists?(user_id: user.id)
  end
end
