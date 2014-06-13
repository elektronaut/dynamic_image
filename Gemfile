source "https://rubygems.org"

gemspec

# TODO: Remove when Shrouded is released
gem 'shrouded', git: 'https://github.com/elektronaut/shrouded.git', require: false
#gem 'shrouded', path: '~/Dev/gems/shrouded'

# TODO: Remove this line when the activemodel-globalid gem
# is updated with the railtie loading fix.
gem 'activemodel-globalid', git: 'https://github.com/rails/activemodel-globalid.git', require: false

group :development, :test do
  gem "pry"
  gem "pry-stack_explorer"
  gem "pry-rescue"
end

group :development do
  gem 'guard'
  gem 'guard-rspec', require: false
end

group :test do
  gem 'codeclimate-test-reporter', require: false
end
