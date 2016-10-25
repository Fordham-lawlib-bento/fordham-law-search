require 'cgi'
require 'http_client_patch/include_client'
require 'httpclient'
require 'nokogiri'

require_dependency 'sierra_keyword_engine/item_extractor'


# Developed for Fordham Law Sierra WEBPAC at http://lawpac.lawnet.fordham.edu/
# as of Oct 2016. Unclear if this would work out of the box on Sierra
# OPACs, it might or might not.
#
# Does not currently included fielded search, sorting, or pagination.
# It just gets the first page of results sorted with a fixed sort code
# and a fixed search type code.
#
# WebPAC HTML isn't as nice for screen-scraping as one might like, but
# we force it out.
# * 'author' is just whatever's on the screen, looks like 245$c maybe.
# * format is uncontrolled format_str, and translated from sierra icons (!).
#
# # Optional configuration
#  * `max_results` can always only return whatever the page size is on Webpac, at
#     most. But set this to limit to even less.
#  * `base_url` defaults to http://lawpac.lawnet.fordham.edu
#  * `sort_code` defaults to RZ (relevance)
#  * `search_type` defaults to X (keyword anywhere)
#  * extra_webpac_query_params Extra query params to add on to webpac query, as a ruby
#    hash. Eg `{m: 'f'}` to apply a format pre-limit.
#  * query_suffix: eg ` (inDatabases)` for Tom's custom database limit.
#
# # custom_data
#  * call number in custom_data[:call_number]
#  * location in custom_data[:location]

class SierraKeywordEngine
  include BentoSearch::SearchEngine

  extend HTTPClientPatch::IncludeClient

  class_attribute :http_timeout
  self.http_timeout = 8

  include_http_client do |client|
    client.connect_timeout = client.send_timeout = client.receive_timeout = self.http_timeout
  end

  def self.default_configuration
    {
      # Using https oddly messes up non-ascii on the way in and way out,
      # seems to get confused between UTF-8 and WINDOWS-1252. Don't have
      # this problem with http version. Weird proxy issues on Webpac end?
      base_url: "http://lawpac.lawnet.fordham.edu",
      sort_code: "RZ",
      search_type: "X",
      format_filename_map: {
        't_book.gif' => 'Book',
        't_jourser.gif' => 'Journal/Serial',
        't_micro.gif' => 'Microform',
        't_ebook.gif' => 'E-Book',
        't_online.gif' => 'Online Resource',
        't_vidvd.gif' => 'Video/DVD',
        't_audio.gif' => 'Audio',
        't_cd.gif' => 'CD-ROM/Disk',
      }
    }
  end


  # TODO why is it so slow, profile
  def search_implementation(args)
    scrape_url = construct_search_url(args)
    response = http_client.get(scrape_url)

    unless response.ok?
      error = BentoSearch::Results.new
      error.error = {
        status: response.status,
        response: response.body
      }
      fill_in_search_metadata_for(error, args)

      return error
    end

    document = Nokogiri::HTML(response.body)

    results = BentoSearch::Results.new
    results.total_items = extract_total_items(document)

    unless results.total_items == 0
      extractor = ItemExtractor.new(document, configuration)
      results.concat extractor.extract
    end

    return results
  end

  def construct_search_url(args)
    # https://lawpac.lawnet.fordham.edu/search/?searchtype=X&searcharg=thomas+chalk&SORT=RZ

    # Needs to have parens surrounding, and can't include any internal parens or
    # will mess up Sierra webpac
    embedded_query = "(#{args[:query].tr('()', '  ')})"

    if configuration.query_suffix.present?
      embedded_query += configuration.query_suffix
    end

    url = "#{configuration.base_url}/search/X?#{CGI.escape embedded_query}&SORT=#{CGI.escape configuration.sort_code}"

    if configuration.extra_webpac_query_params.present?
      url += "&#{configuration.extra_webpac_query_params.to_param}"
    end

    return url
  end


  def extract_total_items(document)
    text = document.css(".browseSearchtoolMessage").text().scrub
    if text =~ /(\d+) results found/
      $1.to_i
    elsif document.at_css("td.searchform2 h2").try(:text).try(:strip) == "NO ENTRIES FOUND"
      0
    else
      nil
    end
  end

end
