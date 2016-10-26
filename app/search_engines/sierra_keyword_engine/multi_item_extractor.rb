class SierraKeywordEngine
  # Extracts multiple items from a sierra classic keyword-style multiple results
  # page.
  class MultiItemExtractor
    attr_reader :document, :configuration

    def initialize(nokogiri_document, configuration)
      @document = nokogiri_document
      @configuration = configuration
    end

    # returns an array of BentoSearch::ResultItem
    def extract
     item_nodes.collect { |item_node| extract_item(item_node) }
    end

    # Returns a nokogiri nodeset of nodes representing individual result items
    def item_nodes
      # different sorts of results have items in td.briefCitRow or tr.briefCitRow
      node_set = document.css(".briefCitRow")

      if configuration.max_results
        node_set = node_set.slice(0, configuration.max_results.to_i)
      end

      return node_set
    end

    # pass in node included in #item_nodes results, returns a ResultItem
    def extract_item(item_node)
      BentoSearch::ResultItem.new.tap do |result_item|
        link = item_node.at_css(".briefcitTitle a")

        result_item.title = extract_text(link)
        result_item.link = URI.join(configuration.base_url, link["href"]).to_s if link["href"]

        result_item.authors.concat extract_authors(item_node)

        result_item.format_str = extract_format_str(item_node)

        result_item.abstract = extract_abstract(item_node)

        result_item.custom_data[:call_number] = extract_call_number(item_node)

        # 856 links, sierra uses an illegal class name starting with a number, argh
        result_item.other_links.concat extract_856_links(item_node)

        # publisher, date, location
        insert_weird_stuff(result_item, item_node)
      end
    end

    def extract_authors(item_node)
      # getting author out is super annoying, first direct text child
      # that's not all newlines.
      briefCitDetail = item_node.at_css("td.briefcitDetail")
      authorish = briefCitDetail &&
        extract_text(item_node.at_css("td.briefcitDetail").xpath("text()").to_a.delete_if {|n| n.text.scrub =~ /\A\n+\z/ }.first)
      if authorish
        [ BentoSearch::Author.new(display: authorish) ]
      else
        []
      end
    end

    def extract_abstract(item_node)
      # this is a weird one, there's no classes involved, bah,
      # hope we don't get any false positives
      # Mostly this is here for ERM "database" records.
      item_node.at_xpath("td/table/tr[2]/td[@colspan=2]").try(:text)
    end

    def extract_format_str(item_node)
      img_url = item_node.at_css(".mattype img").try {|n| n['src']}
      if img_url
        configuration.format_filename_map[File.basename(img_url)]
      end
    end

    def extract_call_number(item_node)
      # call number, yes we extract with this terrible path
      extract_text(item_node.at_css("td.briefcitDetail span.briefcitDetail span.briefcitDetail"))
    end

    def extract_856_links(item_node)
      item_node.css("a[class*='856display']").collect do |node|
        BentoSearch::Link.new(
          label: node.text,
          url: node['href']
        )
      end
    end

    # Get publisher, date, and location out of item_node, set them in result_item.
    # this is some crazy scraping.
    def insert_weird_stuff(result_item, item_node)
      # The publication info is... here? Really?
      innerBriefcitDetailNode = item_node.at_css("td.briefcitDetail span.briefcitDetail")
      return unless innerBriefcitDetailNode
      innerBriefcitDetail = extract_text(innerBriefcitDetailNode.xpath("text()"))

      # Publisher info
      pub_info = innerBriefcitDetail.split("\n").first.gsub(/\A\[/, '').gsub(/\]\z/, '')
      publication_info = SierraKeywordEngine.extract_publication_info(pub_info)
      result_item.publisher = publication_info.publisher
      result_item.year = publication_info.year

      # Location, yeah, it's extracted crazy fragile
      if innerBriefcitDetail =~ /Location:\s*(.*)(\n|\z)/
        result_item.custom_data[:location] = $1
      end
    end

    # Returns nil if no text.
    # Changes unicode non-breaking-spaces to ordinary spaces
    # Scrubs bad UTF8, which for some reason happen if we scrape from https fordham webpac
    # strips leading/trailing whitespace
    def extract_text(node)
      return nil unless node

      node.text.gsub("\u00A0", " ").scrub.strip.presence
    end

  end
end
