require 'cgi'
require 'http_client_patch/include_client'
require 'httpclient'
require 'nokogiri'

require_dependency 'sierra_keyword_engine/multi_item_extractor'
require_dependency 'sierra_keyword_engine/single_item_extractor'


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
#  * call number in custom_data[:call_number]
#  * location in custom_data[:location]
#  * extra_webpac_query_params Extra query params to add on to webpac query, as a ruby
#    hash. Eg `{m: 'f'}` to apply a format pre-limit.
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

    if results.total_items == 0
      # nothing
    elsif single_result_page?(document)
      results.total_items = extract_single_total_items(document)
      item = SingleItemExtractor.new(document, configuration).extract
      if item
        # best we can do for link is the search URL we scraped...
        item.link ||= scrape_url
        results << item
      end
    else
      results.total_items = extract_multi_total_items(document)

      extractor = MultiItemExtractor.new(document, configuration)
      results.concat extractor.extract
    end

    return results
  end


  def auto_rescue_exceptions
    super + [SocketError]
  end

  def construct_search_url(args)
    # https://lawpac.lawnet.fordham.edu/search/?searchtype=X&searcharg=thomas+chalk&SORT=RZ

    # Needs to have parens surrounding, and can't include any internal parens or
    # will mess up Sierra webpac
    embedded_query = "(#{args[:query].tr('()', '  ')})"

    url = "#{configuration.base_url}/search/X?#{CGI.escape embedded_query}&SORT=#{CGI.escape configuration.sort_code}"

    if configuration.extra_webpac_query_params.present?
      url += "&#{configuration.extra_webpac_query_params.to_param}"
    end

    return url
  end


  def extract_multi_total_items(document)
    text = document.css(".browseSearchtoolMessage").text().scrub
    if text =~ /(\d+) results found/
      $1.to_i
    elsif document.at_css("td.searchform2 h2").try(:text).try(:strip) == "NO ENTRIES FOUND"
      0
    else
      nil
    end
  end

  def extract_single_total_items(document)
    if document.css(".bibSearchtoolMessage").try(:text) =~ /(\d+) result found/
      return $1.to_i
    end
  end

  def single_result_page?(document)
    !! document.at_css(".bibinnertable") || document.at_css("#bibDisplayBody")
  end

end
