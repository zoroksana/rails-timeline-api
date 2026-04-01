Rails.application.routes.draw do
  root "timeline#landing"
  get "timeline", to: "timeline#index"
  get "timeline/:id", to: "timeline#show", as: :timeline_post
  post "timeline", to: "timeline#create"
  post "timeline/:id/comments", to: "timeline#create_comment", as: :timeline_post_comments
  post "timeline/:id/like", to: "timeline#toggle_like", as: :timeline_post_like
  post "timeline/users", to: "timeline#create_user", as: :timeline_users
  post "timeline/select_user", to: "timeline#select_user", as: :timeline_select_user

  namespace :api do
    namespace :v1 do
      resources :posts do
        resources :comments, only: [:create, :index]
        member do
          post :like
          delete :like, action: :unlike
        end
      end

      resources :comments, only: [] do
        member do
          post :like
          delete :like, action: :unlike
        end
      end
    end
  end
end
