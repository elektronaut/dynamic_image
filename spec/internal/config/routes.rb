# encoding: utf-8

Rails.application.routes.draw do
  resources :images, only: [:show] do
    member do
      get :uncropped
      get :original
    end
  end
end
