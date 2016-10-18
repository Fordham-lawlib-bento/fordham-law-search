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


