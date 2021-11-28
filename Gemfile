# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.6.9'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.4'
# Use MySQL as the database for Active Record
gem 'mysql2', '~> 0.4.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# For older assets pipeline which we still use
gem 'sprockets', '~> 4'
# Use Uglifier as compressor for JavaScript assets, in older assets pipeline
gem 'uglifier', '>= 4.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-bundler', '~> 1.3', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', '~> 1.5', require: false
  gem 'capistrano-rbenv', '~> 2.1', require: false
  gem 'capistrano-maintenance', '~> 1.2', require: false

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webdrivers'
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
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'brakeman', require: false
  gem 'erb_lint', require: false
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
end

group :production, :staging do
  gem 'passenger', '~> 5.0'
  gem 'slack-notifier'
end

gem 'aasm', '~> 4.0'
gem 'activemerchant'
gem 'dynamic_form', git: 'https://github.com/joelmoss/dynamic_form.git'
gem 'exception_notification'
gem 'redcarpet'
gem 'redis'
gem 'therubyracer'
gem 'uuid'
gem 'will_paginate'
gem 'yubikey'
