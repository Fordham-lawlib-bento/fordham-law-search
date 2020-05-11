source 'https://rubygems.org'

# Heroku uses this to determine ruby version; otherwise, it's just
# a guard that will prevent app from running unless current ruby version matches.
ruby '2.6.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'
gem 'bootsnap'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sassc-rails'
# Use Autoprefixer
gem 'autoprefixer-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Gems added for fordham law search app specifically:
# temporarily point bento_search to master
gem 'bento_search', '~> 1.7'
gem 'slim-rails', '~> 3.1'
gem 'concurrent-ruby', '~>1.0'
gem 'kaminari' # pagination
gem 'addressable', '~> 2.5' # completing partial URLs

# heroku suggested
group :production do
  gem "rack-timeout"
end

group :development, :test do
  gem 'vcr', "~> 3.0"
  gem 'webmock'
  gem 'rspec-rails', '~> 3.5'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Used to load secrets.yml to heroku
gem 'heroku_secrets', git: 'https://github.com/alexpeattie/heroku_secrets.git'
