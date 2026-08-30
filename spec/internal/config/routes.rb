# encoding: utf-8

Rails.application.routes.draw do
  image_resources :images
  image_resources :photos
  resources :posts
  root to: 'posts#index'
end
