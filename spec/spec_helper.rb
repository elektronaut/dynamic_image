# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "rails-controller-testing"

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("internal/config/environment", __dir__)
require "rspec/rails"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob("spec/support/**/*.rb").each do |f|
  require f
end

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [
    %r{/lib\d*/ruby/},
    %r{bin/},
    %r{spec/spec_helper\.rb},
    %r{lib/rspec/(core|expectations|matchers|mocks)}
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

  # Clean the Dis storage after each example
  config.after do
    storage_root = Rails.root.join("db/dis/test")
    FileUtils.rm_rf(storage_root)
  end
end
