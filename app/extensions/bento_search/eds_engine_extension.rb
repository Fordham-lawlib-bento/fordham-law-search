module BentoSearch
  module EdsEngineExtension
    def construct_search_url(args)
      query = "AND,"
      if args[:search_field]
        query += "#{args[:search_field]}:"
      end
      # Can't have any commas in query, it turns out, although
      # this is not documented.
      query += args[:query].gsub(",", " ")

      url = "#{configuration.base_url}search?view=detailed&query=#{CGI.escape query}"

      url += "&searchmode=#{CGI.escape configuration.search_mode}"

      url += "&highlight=#{configuration.highlighting ? 'y' : 'n' }"

      if configuration.show_related_publications
        url += "&relatedcontent=emp"
      end

      if args[:per_page]
        url += "&resultsperpage=#{args[:per_page]}"
      end
      if args[:page]
        url += "&pagenumber=#{args[:page]}"
      end

      if args[:sort]
        if (defn = self.sort_definitions[args[:sort]]) &&
             (value = defn[:implementation] )
          url += "&sort=#{CGI.escape value}"
        end
      end

      if configuration.only_source_types.present?
        # facetfilter=1,SourceType:Research Starters,SourceType:Books
        url += "&facetfilter=" + CGI.escape("1," + configuration.only_source_types.collect {|t| "SourceType:#{t}"}.join(","))
      end


      return url
    end

    def search_implementation(args)
      results = BentoSearch::Results.new

      end_user_auth = authenticated_end_user? args

      begin
        with_session(end_user_auth) do |session_token|

          url = construct_search_url(args)

          response = get_with_auth(url, session_token)

          results = BentoSearch::Results.new

          if (hits_node = at_xpath_text(response, "./SearchResponseMessageGet/SearchResult/Statistics/TotalHits"))
            results.total_items = hits_node.to_i
          end

          response.xpath("./SearchResponseMessageGet/SearchResult/RelatedContent/RelatedPublications/RelatedPublication").each do |publication_xml|
            item = BentoSearch::ResultItem.new

            item_xml = publication_xml.at_xpath("./PublicationRecords/Record")

            item.title = item_xml.at_xpath("./RecordInfo/BibRecord/BibEntity/Titles/Title/TitleFull").text
            item.link = item_xml.at_xpath("./PLink").try(:text)

            item_xml.xpath("./FullTextHoldings/FullTextHolding").each do |link_xml|
              item.other_links << BentoSearch::Link.new(
                url: link_xml.at_xpath("./URL").text,
                label: "#{link_xml.at_xpath("./Name").text} (#{link_xml.at_xpath("./CoverageStatement").text})"
              )
            end

            results << item
          end

          response.xpath("./SearchResponseMessageGet/SearchResult/Data/Records/Record").each do |record_xml|
            item = BentoSearch::ResultItem.new

            item.title   = prepare_eds_payload( element_by_group(record_xml, "Ti"), true )

            # To get a unique id, we need to pull out db code and accession number
            # and combine em with colon, accession number is not unique by itself.
            db           = record_xml.at_xpath("./Header/DbId").try(:text)
            accession    = record_xml.at_xpath("./Header/An").try(:text)
            if db && accession
              item.unique_id    = "#{db}:#{accession}"
            end


            if item.title.nil? && ! end_user_auth
              item.title = I18n.translate("bento_search.eds.record_not_available")
            end

            item.abstract = prepare_eds_payload( element_by_group(record_xml, "Ab"), true )

            # Much better way to get authors out of EDS response now...
            author_full_names = record_xml.xpath("./RecordInfo/BibRecord/BibRelationships/HasContributorRelationships/HasContributor/PersonEntity/Name/NameFull")
            author_full_names.each do |name_full_xml|
              if name_full_xml && (text = name_full_xml.text).present?
                item.authors << BentoSearch::Author.new(:display => text)
              end
            end

            if item.authors.blank?
              # Believe it or not, the authors are encoded as an escaped
              # XML-ish payload, that we need to parse again and get the
              # actual authors out of. WTF. Thanks for handling fragments
              # nokogiri.
              author_mess = element_by_group(record_xml, "Au")
              # only SOMETIMES does it have XML tags, other times it's straight text.
              # ARGH.
              author_xml = Nokogiri::XML::fragment(author_mess)
              searchLinks = author_xml.xpath(".//searchLink")
              if searchLinks.size > 0
                author_xml.xpath(".//searchLink").each do |author_node|
                  item.authors << BentoSearch::Author.new(:display => author_node.text)
                end
              else
                item.authors << BentoSearch::Author.new(:display => author_xml.text)
              end
            end

            # PLink is main inward facing EBSCO link, put it as
            # main link.
            if direct_link = record_xml.at_xpath("./PLink")
              item.link = direct_link.text

              if record_xml.at_xpath("./FullText/Links/Link/Type[text() = 'pdflink']")
                item.link_is_fulltext = true
              end
            end


            # Other links may be found in CustomLinks, it seems like usually
            # there will be at least one, hopefully the first one is the OpenURL?
            #byebug if configuration.id == "articles"
            record_xml.xpath("./CustomLinks/CustomLink|./FullText/CustomLinks/CustomLink").each do |custom_link|
              # If it's in FullText section, give it a rel=alternate
              # to indicate it's fulltext
              rel = (custom_link.parent.parent.name.downcase == "fulltext") ? "alternate" : nil

              item.other_links << BentoSearch::Link.new(
                :url => custom_link.at_xpath("./Url").text,
                :rel => rel,
                :label => custom_link.at_xpath("./Text").try(:text).presence || custom_link.at_xpath("./Name").try(:text).presence || "Link"
                )
            end

            # More other links in 'URL' Item, in unpredictable format sometimes being
            # embedded XML. Really EBSCO?
            record_xml.xpath("./Items/Item[child::Group[text()='URL']]").each do |url_item|
              data_element = url_item.at_xpath("./Data")
              next unless data_element

              # SOMETIMES the url and label are in an embedded escaped XML element...
              if data_element.text.strip.start_with?("<link")
                # Ugh, once unescpaed it has bare '&' in URL queries sometimes, which
                # is not actually legal XML anymore, but Nokogiri::HTML parser will
                # let us get away with it, but then doesn't put the actual text
                # inside the 'link' item, but inside the <link> tag since it knows
                # an HTML link tag has no content. Really EDS.
                data_html = CGI.unescapeHTML(data_element.text)
                node = Nokogiri::XML::fragment(data_html.gsub(/&/, "&amp;"))
                node.xpath("./link").each do |link|
                  next unless link["linkterm"].presence || link["linkTerm"].presence

                  item.other_links << BentoSearch::Link.new(
                    :url => link["linkterm"] || link["linkTerm"],
                    :label => helper.strip_tags(link.text).presence || "Link"
                    )
                end
              else
                # it's just a straight URL in data element, with only label we've
                # got in <label> element.
                next unless data_element.text.strip.present?

                label_element = url_item.at_xpath("./Label")
                label = label_element.try(:text).try { |s| helper.strip_tags(s) }.presence || "Link"

                item.other_links << BentoSearch::Link.new(
                  :url => data_element.text,
                  :label => label
                )
              end
            end


            if (configuration.assume_first_custom_link_openurl &&
              (first = record_xml.xpath "./CustomLinks/CustomLink" ) &&
              (node = first.at_xpath "./Url" )
            )

              openurl = node.text

              index = openurl.index('?')
              item.openurl_kev_co = openurl.slice index..(openurl.length) if index
            end

            # Format.
            item.format_str = at_xpath_text record_xml, "./Header/PubType"
            # Can't find a list of possible PubTypes to see what's there to try
            # and map to our internal controlled vocab. oh wells.

            item.doi = at_xpath_text record_xml, "./RecordInfo/BibRecord/BibEntity/Identifiers/Identifier[child::Type[text()='doi']]/Value"

            item.start_page = at_xpath_text(record_xml, "./RecordInfo/BibRecord/BibEntity/PhysicalDescription/Pagination/StartPage")
            total_pages = at_xpath_text(record_xml, "./RecordInfo/BibRecord/BibEntity/PhysicalDescription/Pagination/PageCount")
            if total_pages.to_i != 0 && item.start_page.to_i != 0
              item.end_page = (item.start_page.to_i + total_pages.to_i - 1).to_s
            end


            # location/call number, probably only for catalog results. We only see one
            # in actual data, but XML structure allows multiple, so we'll store it as multiple.
            copy_informations = record_xml.xpath("./Holdings/Holding/HoldingSimple/CopyInformationList/CopyInformation")
            ### if copy_informations.present?
            ###  item.custom_data[:holdings] =
            ###    copy_informations.collect do |copy_information|
            ###      BentoSearch::EdsEngine::Holding.new(:location => at_xpath_text(copy_information, "Sublocation"),
            ###                  :call_number => at_xpath_text(copy_information, "ShelfLocator"))
            ###    end
            ### end



            # For some EDS results, we have actual citation information,
            # for some we don't.
            container_xml = record_xml.at_xpath("./RecordInfo/BibRecord/BibRelationships/IsPartOfRelationships/IsPartOf/BibEntity")
            if container_xml
              item.source_title = at_xpath_text(container_xml, "./Titles/Title[child::Type[text()='main']]/TitleFull")
              item.volume = at_xpath_text(container_xml, "./Numbering/Number[child::Type[text()='volume']]/Value")
              item.issue = at_xpath_text(container_xml, "./Numbering/Number[child::Type[text()='issue']]/Value")

              item.issn = at_xpath_text(container_xml, "./Identifiers/Identifier[child::Type[text()='issn-print']]/Value")

              if date_xml = container_xml.at_xpath("./Dates/Date")
                item.year = at_xpath_text(date_xml, "./Y")

                date = at_xpath_text(date_xml, "./D").to_i
                month = at_xpath_text(date_xml, "./M").to_i
                if item.year.to_i != 0 && date != 0 && month != 0
                  item.publication_date = Date.new(item.year.to_i, month, date)
                end
              end
            end

            # EDS annoyingly repeats a monographic title in the same place
            # we look for source/container title, take it away.
            if item.start_page.blank? && helper.strip_tags(item.title) == item.source_title
              item.source_title = nil
            end

            # Legacy EDS citation extracting. We don't really need this any more
            # because EDS api has improved, but leave it in in case anyone using
            # older versions needed it.

            # We have a single blob of human-readable citation, that's also
            # littered with XML-ish tags we need to deal with. We'll save
            # it in a custom location, and use a custom Decorator to display
            # it. Sorry it's way too hard for us to preserve <highlight>
            # tags in this mess, they will be lost. Probably don't
            # need highlighting in source anyhow.
            citation_mess = element_by_group(record_xml, "Src")
            # Argh, but sometimes it's in SrcInfo _without_ tags instead
            if citation_mess
              citation_txt = Nokogiri::XML::fragment(citation_mess).text
              # But strip off some "count of references" often on the end
              # which are confusing and useless.
              item.custom_data["citation_blob"] = citation_txt.gsub(/ref +\d+ +ref\.$/, '')
            else
              # try another location
              item.custom_data["citation_blob"] = element_by_group(record_xml, "SrcInfo")
            end

            item.extend BentoSearch::EdsEngine::CitationMessDecorator

            results << item
          end
        end

        return results
      rescue BentoSearch::EdsEngine::EdsCommException => e
        results.error ||= {}
        results.error[:exception] = e
        results.error[:http_status] = e.http_status
        results.error[:http_body] = e.http_body
        return results
      end
    end
  end
end

BentoSearch::EdsEngine.prepend(BentoSearch::EdsEngineExtension)
