require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

APP_RAKEFILE = 'spec/internal/Rakefile'.freeze
load 'rails/tasks/engine.rake'

RSpec::Core::RakeTask.new

task default: :spec
task test: :spec
