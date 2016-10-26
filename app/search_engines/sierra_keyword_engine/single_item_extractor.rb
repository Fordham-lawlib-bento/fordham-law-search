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
        item.title = value_for_label(document, "Resource")
        item.abstract = value_for_label(document, "Description")
      else
        whole_title_str = value_for_label(document, "Title")
        title, author = whole_title_str.split("/", 2).collect(&:strip) if whole_title_str
        item.title = title
        item.authors << BentoSearch::Author.new(display: author) if author

        item.custom_data[:call_number] = value_for_label(document, "Call Number")
        item.custom_data[:location] = document.at_css(".locadata").try(:text)
      end

      return item
    end


    protected

    # Returns :resource or :generic at present
    def resource_type
      @resource_type ||= value_for_label(document, "Resource") ? :resource : :generic
    end


    def value_for_label(xml_container, label_name)
      xpath = "//tr[child::td[contains(@class, 'resourceInfoLabel') or contains(@class, 'bibInfoLabel') or contains(@class, 'resourceUrlLabel')][normalize-space(text())='#{label_name}']]" +
        "/td[contains(@class, 'resourceInfoData') or contains(@class, 'bibInfoData') or contains(@class, 'resourceUrlData')]"

      xml_container.at_xpath(xpath).try(:text).try(:strip)
    end
  end
end
