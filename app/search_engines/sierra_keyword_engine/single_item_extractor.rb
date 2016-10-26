class SierraKeywordEngine
  # Extract a BentoSearch::ResultItem from the sierra classic single bib
  # detail page, which is sometimes returned as your search results when
  # there's only one hit.
  #
  # Kind of a mess because of sierra classic's inconsistencies
  class SingleItemExtractor
    attr_reader :document, :configuration

    def initialize(nokogiri_document, configuration)
      @document = nokogiri_document
      @configuration = configuration
    end

    # Returns single BentoSearch::ResultItem
    def extract
      item = BentoSearch::ResultItem.new

      if resource_type == :resource
        if resource_value_node = node_for_label(document, "Resource")
          item.title = resource_value_node.text.strip
          item.link = resource_value_node.at_xpath("./a").try { |a| a['href'] }
        end

        item.abstract = text_for_label(document, "Description")
      else
        whole_title_str = text_for_label(document, "Title")
        title, author = whole_title_str.split("/", 2).collect(&:strip) if whole_title_str
        item.title = title
        item.authors << BentoSearch::Author.new(display: author) if author

        publication_info = SierraKeywordEngine.extract_publication_info( text_for_label(document, "Publisher") )
        item.publisher = publication_info.publisher
        item.year = publication_info.year

        item.custom_data[:call_number] = text_for_label(document, "Call Number")
        item.custom_data[:location] = document.at_css(".locadata").try(:text)
      end

      return item
    end


    protected

    # Returns :resource or :generic at present
    def resource_type
      @resource_type ||= text_for_label(document, "Resource") ? :resource : :generic
    end

    def text_for_label(xml_container, label_name)
      node_for_label(xml_container, label_name).try(:text).try(:strip)
    end

    def node_for_label(xml_container, label_name)
      xpath = "//tr[child::td[contains(@class, 'resourceInfoLabel') or contains(@class, 'bibInfoLabel') or contains(@class, 'resourceUrlLabel')][normalize-space(text())='#{label_name}']]" +
        "/td[contains(@class, 'resourceInfoData') or contains(@class, 'bibInfoData') or contains(@class, 'resourceUrlData')]"

      xml_container.at_xpath(xpath)
    end
  end
end
