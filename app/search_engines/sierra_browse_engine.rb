# A screen-scraper for Sierra 'browse' style searches. it's pretty hacky.
#
# * Only fills out 'title' of returned results, that's all we got.
# * Does left-anchored 'browse' style search only, as it's scraping Sierra browse.
# * Does not set `total_items`, as this info is not available from Sierra browse scrape.
#
# # Required configuration
# * 'search_type', sierra "search_type" param, `p` for Prof/TA, or `r` for (reserves) Course
#
# # Optional configuration
#  * `max_results` can always only return whatever the page size is on Webpac, at
#     most. But set this to limit to even less.
#  * `base_url` defaults to http://lawpac.lawnet.fordham.edu
#  * `format_str` hard-coded string to use as format, ie "Professor/TA" or "Course"


class SierraBrowseEngine
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
      base_url: "http://lawpac.lawnet.fordham.edu"
    }
  end


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

    results = BentoSearch::Results.new

    document = Nokogiri::HTML(response.body)

    base_url = Addressable::URI.parse(scrape_url)

    if no_results?(document)
      results.total_items = 0
    elsif result = extract_single_result(document, base_url: base_url, query: args[:query])
      results << result
    else # browse screen
      i = 0

      document.css("td.browseEntryData a:not(:empty)").each do |link|
        i += 1

        break if configuration.max_results && i > configuration.max_results

        result =  BentoSearch::ResultItem.new(
          title: link.text,
          link: (base_url + link["href"]).to_s
        )
        results << result
      end
    end

    if configuration.format_str
      results.each { |r| r.format_str = configuration.format_str }
    end

    results
  end

  def no_results?(doc)
    !!(doc.text =~ /No matches found/)
  end

  # Sierra returns a weird bib page if there's only ONE result, we need to
  # do some RIDICULOUS shenanigans to get the single phrase hit out
  def extract_single_result(doc, base_url:, query:)
    # does it have the single-page search feedback thing on it?
    if doc.at_css("td.bibInfoData")
      # Need to find the right line of data, from the echo'd back search type,
      # seriously.
      label = doc.at_css("select[name=searchtype] option[selected=selected]").text.strip

      # We have to pull out the possible <tr> rows it's crazy


      bib_info_data_rows = doc.xpath("//tr[child::td[@class='bibInfoData']/a]")
      # We need to find the ones with a bibInfoLabel matching our label OR,
      # with no bibInfoLabel as long as they're BEFORE the next bibInfoLabel
      in_range = false
      value_rows = []
      bib_info_data_rows.each do |row|
        if label_td = row.at_css("td.bibInfoLabel")
          if !in_range && label_td.text.strip.downcase == label.strip.downcase
            in_range = true
          elsif in_range
            break
          end
        end

        value_rows << row if in_range
      end

      # Which of the value rows starts with the query, or the first one if none match
      hit_row = value_rows.find do |tr|
        tr.at_css("td.bibInfoData").try { |n| n.text.strip.downcase.start_with?(query.downcase) }
      end || value_rows.first

      if hit_row && hit_link = hit_row.at_css("td.bibInfoData a")
        return BentoSearch::ResultItem.new(
          title: hit_link.text.strip,
          link: (base_url + hit_link["href"]).to_s
        )
      end
    end
  end

  def construct_search_url(args)
    # http://lawpac.lawnet.fordham.edu/search/a?searchtype=p&searcharg=query

    "#{configuration.base_url}/search/a?searchtype=#{configuration.search_type}&searcharg=#{CGI.escape args[:query]}"
  end

  def self.required_configuration
    %w{search_type}
  end
end
