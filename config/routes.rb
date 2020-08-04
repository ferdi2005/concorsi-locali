require 'sidekiq/web'
require 'sidekiq/cron/web'
Rails.application.routes.draw do
  root 'contest#index'
  resources :contest, only: [:show]
  resources :creators, only: [:show]
  get 'upload', to: 'contest#upload'
  post 'upload', to: 'contest#uploadpost'
  mount Sidekiq::Web => '/secret-sidekiq'

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
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
