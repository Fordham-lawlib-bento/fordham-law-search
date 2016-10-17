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


  def search_implementation(args)
    scrape_url = construct_search_url(args)
    response = http_client.get(scrape_url)

    document = Nokogiri::HTML(response.body)

    results = BentoSearch::Results.new
    results.total_items = extract_total_items(document)

    results.concat(
      document.css("td.briefCitRow").collect do |item_node|
        BentoSearch::ResultItem.new.tap do |result_item|
          result_item.title = item_node.at_css(".briefcitTitle a").try(:text)

          # getting author out is super annoying, first direct text child
          # that's not all newlines.
          authorish = extract_text(item_node.at_css("td.briefcitDetail").xpath("text()").to_a.delete_if {|n| n.text =~ /\A\n+\z/ }.first)
          if authorish
            result_item.authors = [
              BentoSearch::Author.new(display: authorish)
            ]
          end

          # The publication info is... here? Really?
          innerBriefcitDetail = extract_text(item_node.at_css("td.briefcitDetail span.briefcitDetail").xpath("text()"))


          # Publisher info
          pub_info = innerBriefcitDetail.split("\n").first.gsub(/\A\[/, '').gsub(/\]\z/, '')

          first_colon = pub_info.index(":")
          last_comma = pub_info.rindex(/,/)
          divisions = [-1, first_colon, last_comma, pub_info.length].compact

          parts = divisions.each_cons(2).collect { |s,e| pub_info.slice(s + 1..e - 1) }

          dates = parts.pop if parts.last =~ /\d\d\d\d/
          publisher, place = parts[0..2].reverse

          place, publisher, dates = [place, publisher, dates].collect { |s| s.gsub(/\A *\[ */, '').gsub(/ *\] *\z/, '') if s }
          if publisher.try(:downcase) != "s.n."
            result_item.publisher = publisher.presence
          end
          if /(\d\d\d\d)/ =~ dates
            result_item.year = $1
          end


          # Location, yeah, it's extracted crazy fragile
          if innerBriefcitDetail =~ /Location:\s*(.*)(\n|\z)/
            result_item.custom_data[:location] = $1
          end

          # format
          img_url = item_node.at_css(".mattype img").try {|n| n['src']}
          if img_url
            result_item.format_str = configuration.format_filename_map[File.basename(img_url)]
          end

          # call number, yes we extract with this terrible path
          call_number = extract_text(item_node.at_css("td.briefcitDetail span.briefcitDetail span.briefcitDetail"))
          if call_number
            result_item.custom_data[:call_number] = call_number
          end

          # 856 links, sierra uses an illegal class name starting with a number, argh
          result_item.other_links.concat(
            item_node.css("a[class*='856display']").collect do |node|
              BentoSearch::Link.new(
                label: node.text,
                url: node['href']
              )
            end
          )


        end
      end
    )

    return results
  end


  def construct_search_url(args)
    # https://lawpac.lawnet.fordham.edu/search/?searchtype=X&searcharg=thomas+chalk&SORT=RZ
    query = args[:query]

    "#{configuration.base_url}/search/?searchtype=#{CGI.escape configuration.search_type}&SORT=#{CGI.escape configuration.sort_code}&searcharg=#{CGI.escape query}"
  end

  # Returns nil if no text.
  # Changes unicode non-breaking-spaces to ordinary spaces
  # strips leading/trailing whitespace
  def extract_text(node)
    return nil unless node

    node.text.gsub("\u00A0", " ").strip.presence
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
