# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

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
  s.description = "DynamicImage is a Rails plugin that simplifies image " \
                  "uploading and processing"
  s.license     = "MIT"

  s.files = Dir[
    "{app,config,db,lib}/**/*",
    "MIT-LICENSE",
    "Rakefile",
    "README.md"
  ]

  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency "dis", "~> 1.1", ">= 1.1.11"
  s.add_dependency "rails", "> 5.0"
  s.add_dependency "ruby-vips", "~> 2.1.0"
  s.add_dependency "vector2d", "~> 2.2", ">= 2.2.1"

  s.add_development_dependency "rails-controller-testing"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "simplecov", "~> 0.17.1"
  s.add_development_dependency "sqlite3"
  s.metadata = {
    "rubygems_mfa_required" => "true"
  }
end
