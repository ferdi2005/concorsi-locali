require 'sidekiq/web'
require 'sidekiq/cron/web'
Rails.application.routes.draw do
  resources :years
  root 'contest#index'
  resources :contest, only: [:show]
  resources :creators, only: [:show]
  get 'upload', to: 'contest#upload'
  post 'upload', to: 'contest#uploadpost'
  
  if ENV['WEBSIDEKIQ'] == "TRUE"
    mount Sidekiq::Web => '/sidekiq'
  end

  scope '/numerics' do
    get 'totalphotos', to: 'numerics#totalphotos'
    get 'todayphotos', to: 'numerics#todayphotos'
    get 'totalcreators', to: 'numerics#totalcreators'
    get 'totalcreatorsapposta', to: 'numerics#totalcreatorsapposta'
    get 'todaycreatorsapposta', to: 'numerics#todaycreatorsapposta'
    get 'days', to: 'numerics#days'
    get 'photograph', to: 'numerics#photograph'
    get 'photoday', to: 'numerics#photoday'
    get 'usedonwiki', to: 'numerics#usedonwiki'
    get 'usedonwikipercentage', to: 'numerics#usedonwikipercentage'
    get 'iscrittiappostapercentage', to: 'numerics#iscrittiappostapercentage'
    get 'miglioriutenti', to: 'numerics#miglioriutenti'
    get 'iscrittiappostagraph', to: "numerics#iscrittiappostagraph"
    get 'photos_relativetogeneral', to: "numerics#photos_relativetogeneral"
    get 'participants_relativetogeneral', to: "numerics#participants_relativetogeneral"
    get 'special_photos', to: "numerics#special_photos"
    get 'new_monuments', to: "numerics#new_monuments"
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
