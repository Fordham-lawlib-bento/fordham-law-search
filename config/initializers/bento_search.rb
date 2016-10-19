# conf.for_display.link_out for each engine is a tempalte with `%s` standing for
# search term, which will be URL-escaped. URL to link out to see full interface.
#
# conf.for_display.link_out_text is an optional template for exact text on the link,
# with "%i" standing in for number of hits. If left unset a default will be used.

BentoSearch.register_engine("catalog") do |conf|
  conf.engine = "SierraKeywordEngine"
  conf.max_results = 8 # how many to show on multi results page

  conf.for_display do |display|
    display.heading = "Catalog"
    display.hint = "Library books, journals, music, videos, databases, archival collections, and online resources"
    display.link_out = "http://encore.lawnet.fordham.edu/iii/encore/search?formids=target&lang=eng&suite=def&reservedids=lang%2Csuite&target=%s"
    display.link_out_text "View and filter all %i catalog results"
  end
end

# Right now this is an unconstrained search of entire EDS profile.
BentoSearch.register_engine("articles") do |conf|
  conf.engine = "BentoSearch::EdsEngine"

  conf.user_id = Rails.application.secrets.eds_api_user_id
  conf.password = Rails.application.secrets.eds_api_password
  conf.profile = "wsapi"

  # If we have 'guest' access from EDS or not. Doesn't seem to make
  # any difference though?
  conf.auth = false

  conf.default_per_page = 8 # how many to show on bento page

  conf.for_display do |display|
    display.heading = "Articles"
    display.hint = "Articles, e-books, dissertations, music, images, and more from a mostly full-text database"
    display.link_out = "http://encore.lawnet.fordham.edu/iii/encore/eds/C__S%s__Orightresult__U"
  end
end

BentoSearch.register_engine("reserves") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 3

  conf.for_display do |display|
    display.heading = "Reserves/Exams"
  end
end

BentoSearch.register_engine("databases") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 5

  conf.for_display do |display|
    display.heading = "Databases"
  end
end

BentoSearch.register_engine("website") do |conf|
  conf.engine = "BentoSearch::GoogleSiteSearchEngine"

  conf.cx       = Rails.application.secrets.google_search_website_engine_id
  conf.api_key  = Rails.application.secrets.google_search_website_api_key

  conf.highlighting = true
  conf.default_per_page = 3 # how many to show on dashboard

  conf.for_display do |display|
    display.heading = "Library Website"
    display.hint = "Information about the libraries from the The Maloney Library website"
  end
end

# bepress institutional repository
BentoSearch.register_engine("flash") do |conf|
  conf.engine = "BentoSearch::GoogleSiteSearchEngine"

  conf.cx       = Rails.application.secrets.google_search_flash_engine_id
  conf.api_key  = Rails.application.secrets.google_search_flash_api_key

  conf.highlighting = true
  conf.default_per_page = 5 # how many to show on dashboard

  conf.for_display do |display|
    display.heading = "FLASH"
    display.hint = "Fordham Law Archive of Scholarship & History"
    display.link_out = "http://ir.lawnet.fordham.edu/do/search/?q=%s"
  end
end
