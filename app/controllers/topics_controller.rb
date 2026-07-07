# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_topic, only: %i[show edit update destroy upvote remove_upvote]
  before_action :authorize_owner!, only: %i[edit update destroy]

  # GET /  and  GET /topics
  # Supports ?sort=hot|new|top and ?category=slug filters.
  def index
    scope = Topic.includes(:user, :category)
    scope = scope.where(category: Category.friendly.find(params[:category])) if params[:category].present?
    scope = apply_sort(scope)
    @pagy, @topics = pagy(scope)
    # One query loads the viewer's votes for every topic on the page, so the
    # vote partials never fire a per-row `exists?` (see VotedSet).
    @voted = VotedSet.for(current_user, @topics)
  end

  # GET /topics/:id
  def show
    @posts = @topic.posts.roots.includes(:user, replies: :user).chronological
    @post = Post.new
    # Preload the viewer's votes for the topic + every rendered comment (and
    # their replies) in a single query to avoid an N+1 across the thread.
    votables = [ @topic ] + @posts + @posts.flat_map(&:replies)
    @voted = VotedSet.for(current_user, votables)
  end

  # GET /topics/new
  def new
    @topic = current_user.topics.build(category_id: params[:category_id])
    @categories = Category.ordered
  end

  # POST /topics
  def create
    @topic = current_user.topics.build(topic_params)

    if @topic.save
      ReputationJob.perform_later(current_user.id)
      redirect_to @topic, notice: "Topic posted."
    else
      @categories = Category.ordered
      render :new, status: :unprocessable_entity
    end
  end

  # GET /topics/:id/edit
  def edit
    @categories = Category.ordered
  end

  # PATCH/PUT /topics/:id
  def update
    if @topic.update(topic_params)
      redirect_to @topic, notice: "Topic updated."
    else
      @categories = Category.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /topics/:id
  def destroy
    @topic.destroy
    redirect_to root_path, notice: "Topic deleted.", status: :see_other
  end

  # POST /topics/:id/upvote
  def upvote
    current_user.votes.create(votable: @topic)
    respond_to_vote
  end

  # DELETE /topics/:id/upvote
  def remove_upvote
    current_user.votes.where(votable: @topic).destroy_all
    respond_to_vote
  end

  private

  def set_topic
    @topic = Topic.friendly.find(params[:id])
  end

  def authorize_owner!
    return if @topic.user_id == current_user.id || current_user.moderator?

    redirect_to @topic, alert: "You can only manage your own topics."
  end

  def topic_params
    params.require(:topic).permit(:title, :body, :url, :category_id)
  end

  def apply_sort(scope)
    case params[:sort]
    when "new" then scope.newest
    when "top" then scope.top
    else scope.hot
    end
  end

  def respond_to_vote
    @topic.reload
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "vote_topic_#{@topic.id}",
          partial: "topics/vote",
          locals: { topic: @topic, user: current_user }
        )
      end
      format.html { redirect_to @topic }
    end
  end
end
