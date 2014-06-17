# encoding: utf-8

Rails.application.routes.draw do

  resources :images, only: [:show]

  mount DynamicImage::Engine => "/dynamic_image"
end
