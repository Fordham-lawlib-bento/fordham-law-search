require 'cgi'
require 'http_client_patch/include_client'
require 'httpclient'
require 'nokogiri'


# Developed for Fordham Law Sierra at http://lawpac.lawnet.fordham.edu/
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
#  * `base_url` defaults to https://lawpac.lawnet.fordham.edu
#  * `sort_code` defaults to RZ (relevance)
#  * `search_type` defaults to X (keyword anywhere)
#  * call number in custom_data[:call_number]
#  * location in custom_data[:location]
class SierraKeywordEngine
  include BentoSearch::SearchEngine

  extend HTTPClientPatch::IncludeClient
  include_http_client

  def self.default_configuration
    {
      base_url: "https://lawpac.lawnet.fordham.edu",
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


  # TODO test error handling
  def search_implementation(args)
    scrape_url = construct_search_url(args)
    response = http_client.get(scrape_url)

    document = Nokogiri::HTML(response.body)

    results = BentoSearch::Results.new
    results.total_items = extract_total_items(document)

    extractor = ItemExtractor.new(document, configuration)

    results.concat extractor.extract

    return results
  end


  def construct_search_url(args)
    # https://lawpac.lawnet.fordham.edu/search/?searchtype=X&searcharg=thomas+chalk&SORT=RZ
    query = args[:query]

    "#{configuration.base_url}/search/?searchtype=#{CGI.escape configuration.search_type}&SORT=#{CGI.escape configuration.sort_code}&searcharg=#{CGI.escape query}"
  end


  def extract_total_items(document)
    text = document.css(".browseSearchtoolMessage").text()
    if text =~ /(\d+) results found/
      $1.to_i
    else
      nil
    end
  end

end
