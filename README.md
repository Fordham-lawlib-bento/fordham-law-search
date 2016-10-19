# Fordham Law Search
[![Build Status](https://travis-ci.org/Fordham-lawlib-bento/fordham-law-search.svg?branch=master)](https://travis-ci.org/Fordham-lawlib-bento/fordham-law-search)

Developed by Friends of the Web http://friendsoftheweb.com

This app was generated with rails new ... --skip-activerecord --skip-spring --skip-turbolinks
We don't need a database for this first version of the app.

## Configuration

Configuration of search targets and text and links
related to each is in ./configuration/bento_search.rb

### 'Secret' Configuration

Confidential configuration (passwords, api keys) is stored in `./config/secrets.yml`.

This file is NOT in the repository, because it's secret. There is an example
without confidential info at [./config/secrets.example.yml](./config/secrets.example.yml).

You need to get the correct secrets.yml through some other secure channel.
TBD how we deal with it on deployment.

If deploying to heroku, and you have a secrets.yml on disk with correct
production values, you can copy them to heroku with (TBD).


## Tests

Some automated tests are provided using rspec. Run with `bundle exec rake`
or `bundle exec rspec`.

TBD: Tests use VCR, instructions on re-generating cassettes and setting auth
for regenerating tests.

## Deployment

TBD, we're working on a final plan.

For heroku deploy, the `Procfile` is used by heroku, and specifies deploying
with puma, using `./config/puma.rb` for more configuration.

These files can be used in other deployment scenarios too, depending on setup.
Procfile is used by the `foreman` tool. This simple app prob doesn't need
a procfile in non-heroku scenario, just start it with puma.
