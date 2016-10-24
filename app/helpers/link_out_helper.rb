require 'cgi'

module LinkOutHelper

  def complete_link_out_template(template, query)
    template.gsub("%s", CGI.escape(query))
  end

  def link_out_to_results_url(bento_results)
    url_template = bento_results.display_configuration.link_out

    if url_template && url_template.is_a?(Proc)
      instance_exec &url_template
    elsif url_template
      complete_link_out_template(url_template, CGI.escape(bento_results.search_args[:query]))
    end
  end

  def link_out_to_results(bento_results, label:)
    link_to_if(link_out_to_results_url(bento_results), label, link_out_to_results_url(bento_results), target: "_blank" )
  end

  def link_out_to_results_text(bento_results)
    text_template = bento_results.display_configuration.link_out_text || "View and filter all %i results"

    text_template.gsub("%i", bento_results.total_items.to_s)
  end
end
