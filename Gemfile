source 'https://rubygems.org'
ruby "2.3.1"

gem 'rails', '4.2.7'
gem 'mysql2'

gem 'puma'
gem 'devise'
gem 'haml'
gem 'kaminari'
gem 'aasm'

group :development, :test do
  gem 'byebug'
  gem 'faker'
  gem 'guard'
  gem 'foreman'
  gem 'dotenv-rails' # Loads .env vars without foreman for runing `rake`, etc
  gem 'pry-rails'
end

group :test do
  gem 'mocha'
  gem 'shoulda'
  gem 'simplecov', require: false
  gem 'rubocop', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end
