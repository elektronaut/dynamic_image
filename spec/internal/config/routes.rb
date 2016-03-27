# encoding: utf-8

Rails.application.routes.draw do
  image_resources :images
  resources :posts
  root to: 'posts#index'
end
