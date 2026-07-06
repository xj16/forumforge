# frozen_string_literal: true

class CategoriesController < ApplicationController
  # GET /categories
  def index
    @categories = Category.ordered
  end

  # GET /categories/:id
  def show
    @category = Category.friendly.find(params[:id])
    @pagy, @topics = pagy(@category.topics.includes(:user).hot)
  end
end
