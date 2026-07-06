# frozen_string_literal: true

class LeaderboardController < ApplicationController
  # GET /leaderboard
  def index
    @pagy, @users = pagy(User.order(reputation: :desc, username: :asc))
  end
end
