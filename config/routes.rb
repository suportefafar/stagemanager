Rails.application.routes.draw do
  root 'home#index'

  resources :rooms, param: :passcode, only: [:create] do
    member do
      get :manager
      get :presentation
      get :timer
      patch :update_timer
      patch :update_message
      patch :update_slide
    end
    resources :media_assets, only: [:create, :destroy]
    resources :presentations, only: [:create, :destroy]
  end
end
