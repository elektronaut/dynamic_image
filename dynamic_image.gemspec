# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dynamic_image/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dynamic_image"
  s.version     = DynamicImage::VERSION
  s.authors     = ["Inge Jørgensen"]
  s.email       = ["inge@elektronaut.no"]
  s.homepage    = "https://github.com/elektronaut/dynamic_image"
  s.summary     = "Rails plugin that simplifies image uploading and processing"
  s.description = "DynamicImage is a Rails plugin that simplifies image uploading and processing"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency "rails", "~> 4.1.0"
  s.add_dependency "vector2d", "~> 2.0", ">= 2.0.2"
  s.add_dependency "mini_magick", "~> 3.8.1"
  s.add_dependency "shrouded", "~> 0.9.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails", "~> 3.0.0"
end
