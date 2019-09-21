Rails.application.routes.draw do
  root 'contest#index'
  resources :contest, only: [:show]
  resources :creators, only: [:show]
  get 'upload', to: 'contest#upload'
  post 'upload', to: 'contest#uploadpost'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
