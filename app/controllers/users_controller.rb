# frozen_string_literal: true

class UsersController < ApplicationController
  # GET /users/:username
  def show
    @user = User.friendly.find(params[:username])
    @pagy_topics, @topics = pagy(@user.topics.newest, page_param: :tp)
    @recent_posts = @user.posts.includes(:topic).order(created_at: :desc).limit(10)
  end
end
