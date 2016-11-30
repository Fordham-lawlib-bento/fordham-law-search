# Fordham Law Search
[![Build Status](https://travis-ci.org/Fordham-lawlib-bento/fordham-law-search.svg?branch=master)](https://travis-ci.org/Fordham-lawlib-bento/fordham-law-search)

Developed by Friends of the Web http://friendsoftheweb.com

This app was generated with `rails new --skip-active-record --skip-spring --skip-turbolinks ...`
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
production values, you can copy them to heroku with:

    bin/rake heroku:secrets RAILS_ENV=production

This will copy the production values from your secrets.yml on disk
to heroku config/env variables beginning with `_SECRET_`. We use the
`heroku_secrets` gem to then load these into Rails secrets on boot
on heroku.

## Embed Search Form

A utility to embed the search form on a remote page is included. It uses
javascript to do the embed, the javascript places an iframe on the host page.

There are two ways to trigger embedding:

1. Script tag

Anywhere on your page, place a script tag:

    <script src="//fordham-law-search-demo.herokuapp.com/search-embed.js" async></script>

The search form will appear on the page where the script tag has been placed.

2. Specified insertion point with DOM id

Anywhere on your page, include an HTML element, perhaps an empty placeholder div,
with a unique 'id' of your choice:

    <div id="searchFormHere"></div>

Now include a javascript script tag wherever you'd like (such as `<head>`
section), specifying that id:

     <script src="//fordham-law-search-demo.herokuapp.com/search-embed.js?hostDomId=searchFormHere" async></script>

The search form will be placed just before the element whose id is specified.

**note** url `fordham-law-search-demo.herokuapp.com` is the demo, final
URL yet to be determined.

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

