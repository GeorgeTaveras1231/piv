source 'https://rubygems.org'

# Specify your gem's dependencies in piv.gemspec
gemspec

gem 'sqlite3', :platform => :ruby
gem 'childprocess'

platform :jruby do
  gem 'activerecord-jdbcsqlite3-adapter'
end

group :test do
  gem 'rspec'
  gem 'webmock'
  gem "codeclimate-test-reporter", :require => nil
end
