# encoding: utf-8

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../internal/config/environment", __FILE__)
require 'pry-rescue/rspec'
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [
    /\/lib\d*\/ruby\//,
    /bin\//,
    /spec\/spec_helper\.rb/,
    /lib\/rspec\/(core|expectations|matchers|mocks)/
  ]

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.use_transactional_fixtures = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Clean the Shrouded storage after each example
  config.after(:each) do
    storage_root = Rails.root.join('db', 'shrouded', 'test')
    FileUtils.rm_rf(storage_root) if File.exists?(storage_root)
  end
end