Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :rooms, param: :passcode, only: [ :create ] do
    member do
      get :manager
      get :presentation
      get :timer
      patch :update_timer
      patch :update_message
      patch :update_slide
      patch :update_audio
    end
    resources :media_assets, only: [ :create, :update, :destroy ]
    resources :presentations, only: [ :create, :destroy ]
  end
end
