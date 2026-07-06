# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic
  before_action :set_post, only: %i[update destroy upvote remove_upvote]
  before_action :authorize_owner!, only: %i[update destroy]

  # POST /topics/:topic_id/posts
  def create
    @post = @topic.posts.build(post_params)
    @post.user = current_user

    if @post.save
      ReputationJob.perform_later(current_user.id)
      respond_to do |format|
        # The Turbo Stream broadcast from the model already appends the post for
        # every subscriber; here we just reset the form for the submitter.
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_post",
            partial: "posts/form",
            locals: { topic: @topic, post: Post.new }
          )
        end
        format.html { redirect_to @topic, notice: "Reply posted." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_post",
            partial: "posts/form",
            locals: { topic: @topic, post: @post }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to @topic, alert: @post.errors.full_messages.to_sentence }
      end
    end
  end

  # PATCH/PUT /topics/:topic_id/posts/:id
  def update
    if @post.update(post_params.slice(:body))
      redirect_to @topic, notice: "Reply updated."
    else
      redirect_to @topic, alert: @post.errors.full_messages.to_sentence
    end
  end

  # DELETE /topics/:topic_id/posts/:id
  def destroy
    @post.destroy
    redirect_to @topic, notice: "Reply deleted.", status: :see_other
  end

  # POST /topics/:topic_id/posts/:id/upvote
  def upvote
    current_user.votes.create(votable: @post)
    respond_to_vote
  end

  # DELETE /topics/:topic_id/posts/:id/upvote
  def remove_upvote
    current_user.votes.where(votable: @post).destroy_all
    respond_to_vote
  end

  private

  def set_topic
    @topic = Topic.friendly.find(params[:topic_id])
  end

  def set_post
    @post = @topic.posts.find(params[:id])
  end

  def authorize_owner!
    return if @post.user_id == current_user.id || current_user.moderator?

    redirect_to @topic, alert: "You can only manage your own replies."
  end

  def post_params
    params.require(:post).permit(:body, :parent_id)
  end

  def respond_to_vote
    @post.reload
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "vote_post_#{@post.id}",
          partial: "posts/vote",
          locals: { post: @post, user: current_user }
        )
      end
      format.html { redirect_to @topic }
    end
  end
end
