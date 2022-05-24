Rails.application.routes.draw do
  root 'users#index'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users

  resources :users, only: [:index, :show]

  resources :games, only: [:create, :show] do
    put 'help', on: :member
    put 'answer', on: :member
    put 'take_money', on: :member
  end

  resource :questions, only: [:new, :create]
end
