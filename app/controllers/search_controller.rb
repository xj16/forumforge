# frozen_string_literal: true

# Full-text search over topics and posts.
#
# GET /search?q=…  renders a full results page. The same action also answers
# the `search_results` turbo-frame request fired by the debounced header search
# box, so typing streams ranked, highlighted results into the frame without a
# full navigation. The query is bound as a parameter all the way down to
# Postgres (see Searchable), so there is no SQL-injection surface.
class SearchController < ApplicationController
  MAX_RESULTS = 20

  # GET /search
  def index
    @query = params[:q].to_s.strip

    if @query.present?
      @topics = Topic.search(@query)
                     .includes(:user, :category)
                     .limit(MAX_RESULTS)
                     .to_a
      @posts = Post.search(@query)
                   .includes(:user, :topic)
                   .limit(MAX_RESULTS)
                   .to_a
      @voted = VotedSet.for(current_user, @topics + @posts)
    else
      @topics = []
      @posts = []
      @voted = VotedSet.none
    end
  end
end
