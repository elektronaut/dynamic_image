require 'RMagick'
require 'vector2d'
require 'dynamic_image'

ActionController::Routing::RouteSet::Mapper.send :include, DynamicImage::MapperExtensions
ActiveRecord::Base.send :include, DynamicImage::Record
ActionView::Base.send :include, DynamicImage::Helper
