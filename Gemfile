# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.6.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '=5.0.0'
# Use MySQL as the database for Active Record
gem 'mysql2', '~> 0.4.0'
# Use SCSS for stylesheets
gem 'sass', '=3.5.6'

gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-bundler', '~> 1.3', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rbenv', '~> 2.1', require: false
end

group :test do
  gem 'rspec'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-html-matchers'
  gem 'rspec-rails'

  gem 'factory_bot', '~> 4.0'
  gem 'factory_bot_rails', '~> 4.0'

  gem 'rails-controller-testing'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'brakeman', require: false
  gem 'erb_lint', require: false
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
end

group :production do
  gem 'passenger', '~> 5.0'
  gem 'slack-notifier'
end

gem 'aasm', '~> 4.0'
gem 'activemerchant'
gem 'dynamic_form', git: 'https://github.com/joelmoss/dynamic_form.git'
gem 'exception_notification'
gem 'netaddr', '~> 1.0'
gem 'redcarpet'
gem 'redis'
gem 'therubyracer'
gem 'uuid'
gem 'will_paginate'
gem 'yubikey'
