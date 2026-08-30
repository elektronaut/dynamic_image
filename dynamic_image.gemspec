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

  s.required_ruby_version = ">= 3.2.0"

  s.add_dependency "dis", "~> 2.1"
  s.add_dependency "rails", "> 7.0"
  s.add_dependency "ruby-vips", ">= 2.1", "< 2.4"
  s.add_dependency "vector2d", "~> 2.2", ">= 2.2.1"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/elektronaut/dynamic_image/issues",
    "changelog_uri" => "https://github.com/elektronaut/dynamic_image/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/dynamic_image",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/elektronaut/dynamic_image"
  }
end
