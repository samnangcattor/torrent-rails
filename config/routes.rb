Rails.application.routes.draw do
  root "torrents#index"
  resources :torrents, only: [:index, :create]
end
