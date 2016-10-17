class SierraKeywordEngine
  class ItemExtractor
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
      document.css("td.briefCitRow")
    end

    # pass in node included in #item_nodes results, returns a ResultItem
    def extract_item(item_node)
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

        place, publisher, dates = [place, publisher, dates].collect { |s| s.strip.gsub(/\A *\[ */, '').gsub(/ *\] *\z/, '') if s }


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

    # Returns nil if no text.
    # Changes unicode non-breaking-spaces to ordinary spaces
    # strips leading/trailing whitespace
    def extract_text(node)
      return nil unless node

      node.text.gsub("\u00A0", " ").strip.presence
    end

  end
end
