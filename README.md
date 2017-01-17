# Fordham Law Search
[![Build Status](https://travis-ci.org/Fordham-lawlib-bento/fordham-law-search.svg?branch=master)](https://travis-ci.org/Fordham-lawlib-bento/fordham-law-search)


Developed by Friends of the Web http://friendsoftheweb.com

This app was generated with `rails new --skip-active-record --skip-spring --skip-turbolinks ...`
This app does not use a database/activerecord!

## Configuration and Code of Interest

Configuration of search targets and text and links
related to each is in [./config/initializers/bento_search.rb](./config/initializers/bento_search.rb)
This file includes a section for each search target, configuring a bunch of stuff,
sorry it gets a bit confusing:
  * which BentoSearch search engine adapter to use. Most adapters are located in the
    [bento_search](https://github.com/jrochkind/bento_search) gem, but
    there are some local ones, such as for screen-scraping Sierra Classic,
    in [./app/search_engines](./app/search_engines).  `conf.engine`
  * Other adapter-specific configuration, max per page, hard-coded search limits, etc.
    Authentication information for adapters that need it.
  * Titles and sub-titles for each section. `display.heading`, `display.hint`
  * URL and label to link out to full results, `display.link_out` and `display.link_out_text`.
  * "See also" links for each section, in `display.extra_links`

We use a customized partial template to display each search results, at
[./app/views/application/_result_item.html.erb](./app/views/application/_result_item.html.erb).
This specifies how a result will work, and is used for all search targets -- it does
 have some conditionals in it to display different sorts of results differently.

Additionally some search targets may have a BentoSearch [Item Decorator](https://github.com/jrochkind/bento_search/wiki/Customizing-Results-Display#item-decorators-customizing-links-or-output-even-on-an-engine-by-engine-basis)
configured, with custom overrides on a search-adapter-specific basis. Configured
in [./config/initializers/bento_search.rb](./config/initializers/bento_search.rb), `display.decorator`.
For instance, an EDS decorator to suppress any "other_link" with a label `Availability`.

While bento search targets are configured in [./config/initializers/bento_search.rb], they are also
mentioned in the top-of-file class variables for [./app/controllers/multi_search_controller.rb](./app/controllers/multi_search_controller.rb).
`main_engine_ids` are the two engines that show up in wide columns of their own, and
`secondary_engine_ids` are the engines that show up stacked in the additional narrower
column. To remove an engine, remove it from these lists, and it will no longer
be displayed. Subsequently removing it from config/initializers/bento_search.rb is just tidying up
to not leave dead code around.

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

### 1. Script tag

Anywhere on your page, place a script tag:

    <script src="//fordham-law-search.herokuapp.com/search-embed.js" async></script>

The search form will appear on the page where the script tag has been placed.

### 2. Specified insertion point with DOM id

Anywhere on your page, include an HTML element, perhaps an empty placeholder div,
with a unique 'id' of your choice:

    <div id="searchFormHere"></div>

Now include a javascript script tag wherever you'd like (such as `<head>`
section), specifying that id:

     <script src="//fordham-law-search.herokuapp.com/search-embed.js?hostDomId=searchFormHere" async></script>

The search form will be placed just before the element whose id is specified.

**note** url `fordham-law-search-demo.herokuapp.com` is the demo, final
URL yet to be determined.

### trigger focus and/or selection of search type

If the _host_ page that includes the embed is accessed with special URL query
params, it can trigger search form setup:

* `&search.focus=true` => focus on search text input
* '&search.type=$type' => pre-select a specific search radio button. valid `$type`
   values are:  catalog ; articles ; website ; databases ; reserves ; flash

## Tests

There aren't really any tests at present, if you were you'd run with `bundle exec rake`
or `bundle exec rspec`.

And I'd plan to use [VCR](https://github.com/vcr/vcr) in tests. TBD instructions on re-generating cassettes and setting auth
for regenerating tests.

## Note on Windows development

Windows and unixy OSs (like Heroku) can't share a `Gemfile.lock`. See:

https://devcenter.heroku.com/articles/bundler-windows-gemfile

Recommend avoid committing or pushing a Gemfile.lock on Windows if possible.

Eventually dependencies will need to be updated, which will require
update of the Gemfile.lock.  Not sure the best way to do this on Windows, a VM
might be wise, even just for Gemfile/Gemfile.lock updating.


## Deployment

For heroku deploy, the `Procfile` is used by heroku, and specifies deploying
with puma, using `./config/puma.rb` for more configuration.

These files can be used in other deployment scenarios too, depending on setup.
Procfile is used by the `foreman` tool. This simple app prob doesn't need
a procfile in non-heroku scenario, just start it with puma, or `rails server`.

