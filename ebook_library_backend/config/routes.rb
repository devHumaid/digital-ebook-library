Rails.application.routes.draw do
  namespace :api do
    resources :ebooks, only: [:index, :show, :create, :destroy] do
      member do
        get :download
      end
      collection do
        get :search
      end
    end
  end
end