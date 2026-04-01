Rails.application.routes.draw do
  root "timeline#index"
  get "timeline", to: "timeline#index"
  get "timeline/:id", to: "timeline#show", as: :timeline_post
  post "timeline", to: "timeline#create"
  post "timeline/:id/comments", to: "timeline#create_comment", as: :timeline_post_comments
  post "timeline/users", to: "timeline#create_user", as: :timeline_users

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
