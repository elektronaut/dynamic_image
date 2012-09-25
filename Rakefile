require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require "rake"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name     = "dynamic_image"
    gem.summary  = "DynamicImage is a rails plugin providing transparent uploading and processing of image files."
    gem.email    = "inge@elektronaut.no"
    gem.homepage = "http://github.com/elektronaut/dynamic_image"
    gem.authors  = ["Inge Jørgensen"]
    gem.files    = Dir["*", "{lib}/**/*", "{app}/**/*", "{config}/**/*"]
    gem.add_dependency("rmagick", "~> 2.12.2")
    gem.add_dependency("vector2d", "~> 1.0.0")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the dynamic_image plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the dynamic_image plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'DynamicImage'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
