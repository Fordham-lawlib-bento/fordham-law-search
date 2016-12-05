# conf.for_display.link_out for each engine is a tempalte with `%s` standing for
# search term, which will be URL-escaped. URL to link out to see full interface.
#
# conf.for_display.link_out_text is an optional template for exact text on the link,
# with "%i" standing in for number of hits. If left unset a default will be used.
#
# Engines will be background ajax loaded if they have BOTH of:
# * `conf.allow_routable_results = true``
# * `conf.display.ajax = :auto`


BentoSearch.defaults.item_partial = 'result_item'

# EDS is slow...
BentoSearch::EdsEngine.http_timeout = 8

BentoSearch.register_engine("catalog") do |conf|
  conf.allow_routable_results = true

  conf.engine = "BentoSearch::EdsEngine"

  conf.user_id = Rails.application.secrets.eds_api_user_id
  conf.password = Rails.application.secrets.eds_api_password
  conf.profile = "apicat"

  conf.default_per_page = 6 # how many to show on bento page

  conf.for_display do |display|
    display.heading = "Catalog"
    #display.hint = "Library books, journals, music, videos, databases, archival collections, and online resources"
    #display.link_out = "http://encore.lawnet.fordham.edu/iii/encore/search?formids=target&lang=eng&suite=def&reservedids=lang%2Csuite&target=%s"
    #display.link_out ="http://search.ebscohost.com/login.aspx?authtype=IP,cookie,guest&custid=s8944740&groupid=main&profile=eds&direct=true&cli0=FC&clv0=Y&bquery=%s"
    display.link_out ="http://search.ebscohost.com/login.aspx?authtype=IP,cookie,guest&custid=s8944740&groupid=main&profile=edscatonly&direct=true&bquery=%s"
    display.link_out_text "View and filter all %i catalog results"

    display.ajax = :auto

    display.extra_links = [
      {
        label: "Worldcat",
        link_out: "https://www.worldcat.org/search?qt=worldcat_org_all&q=%s"
      },
      {
        label: "Fordham Law Classic Catalog",
        link_out: "http://lawpac.lawnet.fordham.edu/search/X?%28%s%29&SORT=R"
      },
      {
        label: "Fordham University Libraries Catalog",
        post: true,
        action: "https://catalog.library.fordham.edu/uhtbin/cgisirsi/x/0/0/5",
        hidden_fields: [
          ['srchfield1', "GENERAL^SUBJECT^GENERAL^^words or phrase"],
          ['searchdata1', '%s'],
          ['sort_by', 'relevance']
        ]
      }
    ]

  end
end

# Right now this is an unconstrained search of entire EDS profile.
BentoSearch.register_engine("articles") do |conf|
  conf.allow_routable_results = true

  conf.engine = "BentoSearch::EdsEngine"

  conf.user_id = Rails.application.secrets.eds_api_user_id
  conf.password = Rails.application.secrets.eds_api_password
  conf.profile = "apinocat"

  # If we have 'guest' access from EDS or not. Doesn't seem to make
  # any difference though?
  conf.auth = true

  conf.default_per_page = 6 # how many to show on bento page

  conf.for_display do |display|
    display.heading = "Articles"
    #display.hint = "Articles, e-books, dissertations, music, images, and more from a mostly full-text database"
    #display.link_out = "http://encore.lawnet.fordham.edu/iii/encore/eds/C__S%s__Orightresult__U"
    display.link_out ="http://search.ebscohost.com/login.aspx?authtype=IP,cookie,guest&custid=s8944740&groupid=main&profile=edsnocat&direct=true&bquery=%s"

    display.ajax = :auto

    display.extra_links = [
      {
        label: "Google Scholar",
        link_out: "https://scholar.google.com/scholar?q=%s"
      }
    ]
  end
end

BentoSearch.register_engine("reserves") do |conf|
  conf.allow_routable_results = true

  conf.engine = "SierraKeywordEngine"

  conf.extra_webpac_query_params = {
    m: 'f'
  }

  conf.for_display do |display|
    display.ajax = :auto
    display.heading = "Course Reserves/Exams"
    display.link_out = "http://lawpac.lawnet.fordham.edu/search/X?%28%s%20%28inReserves%29%29&SORT=R&Da=&Db="
  end
end

BentoSearch.register_engine("databases") do |conf|
  conf.allow_routable_results = true

  conf.engine = "SierraKeywordEngine"
  conf.query_suffix = " (inDatabases)"
  conf.max_results = 3

  conf.for_display do |display|
    display.ajax = :auto
    display.heading = "Databases"
    display.link_out = "http://lawpac.lawnet.fordham.edu/search/X?%28%s%20%28inDatabases%29%29&SORT=R&Da=&Db="
  end
end

BentoSearch.register_engine("website") do |conf|
  conf.allow_routable_results = true

  conf.engine = "BentoSearch::GoogleSiteSearchEngine"

  conf.cx       = Rails.application.secrets.google_search_website_engine_id
  conf.api_key  = Rails.application.secrets.google_search_website_api_key

  conf.highlighting = true
  conf.default_per_page = 3 # how many to show on dashboard

  conf.for_display do |display|
    display.heading = "Library Website"
    #display.hint = "Information about the libraries from the The Maloney Library website"

    display.link_out = proc {
      single_search_path("website", q: query )
    }
    display.link_out_text = "View all website results"
    display.display_source_info = false
  end
end

# bepress institutional repository
BentoSearch.register_engine("flash") do |conf|
  conf.allow_routable_results = true

  conf.engine = "BentoSearch::GoogleSiteSearchEngine"

  conf.cx       = Rails.application.secrets.google_search_flash_engine_id
  conf.api_key  = Rails.application.secrets.google_search_flash_api_key

  conf.highlighting = true
  conf.default_per_page = 3 # how many to show on dashboard

  conf.for_display do |display|
    display.heading = "FLASH"
    display.hint = "Fordham Law Archive of Scholarship & History"
    display.link_out = "http://ir.lawnet.fordham.edu/do/search/?q=%s"
    display.link_out_text = "Visit FLASH to view, filter and explore results"
    display.display_source_info = false
  end
end
