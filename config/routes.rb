require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # Health check endpoint used by load balancers / Heroku / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq dashboard, only for signed-in admins.
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Categories group threads.
  resources :categories, only: %i[index show]

  # Threads (called "topics" to avoid clashing with Ruby's Thread).
  resources :topics do
    member do
      post :upvote
      delete :upvote, action: :remove_upvote, as: :remove_upvote
    end

    # Nested replies (comments) with threaded structure.
    resources :posts, only: %i[create update destroy] do
      member do
        post :upvote
        delete :upvote, action: :remove_upvote, as: :remove_upvote
      end
    end
  end

  # Public user profiles with reputation.
  resources :users, only: %i[show], param: :username

  # Leaderboard by reputation.
  get "leaderboard", to: "leaderboard#index"

  # Root: link-aggregation style hot feed.
  root "topics#index"
end
