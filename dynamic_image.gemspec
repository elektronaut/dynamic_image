# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dynamic_image}
  s.version = ""

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Inge J\303\270rgensen"]
  s.date = %q{2010-05-19}
  s.email = %q{inge@elektronaut.no}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "app/controllers/images_controller.rb",
     "app/models/image.rb",
     "config/routes.rb",
     "dynamic_image.gemspec",
     "init.rb",
     "install.rb",
     "lib/binary_storage.rb",
     "lib/binary_storage/active_record_extensions.rb",
     "lib/binary_storage/blob.rb",
     "lib/dynamic_image.rb",
     "lib/dynamic_image/active_record_extensions.rb",
     "lib/dynamic_image/engine.rb",
     "lib/dynamic_image/filterset.rb",
     "lib/dynamic_image/helper.rb",
     "lib/generators/dynamic_image/USAGE",
     "lib/generators/dynamic_image/dynamic_image_generator.rb",
     "lib/generators/dynamic_image/templates/migrations/create_images.rb",
     "uninstall.rb"
  ]
  s.homepage = %q{http://github.com/elektronaut/dynamic_image}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{DynamicImage is a rails plugin providing transparent uploading and processing of image files.}
  s.test_files = [
    "test/dynamic_image_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rmagick>, ["~> 2.12.2"])
      s.add_runtime_dependency(%q<vector2d>, ["~> 1.0.0"])
    else
      s.add_dependency(%q<rmagick>, ["~> 2.12.2"])
      s.add_dependency(%q<vector2d>, ["~> 1.0.0"])
    end
  else
    s.add_dependency(%q<rmagick>, ["~> 2.12.2"])
    s.add_dependency(%q<vector2d>, ["~> 1.0.0"])
  end
end

