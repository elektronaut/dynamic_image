# encoding: utf-8

Rails.application.routes.draw do

  mount DynamicImage::Engine => "/dynamic_image"
end
