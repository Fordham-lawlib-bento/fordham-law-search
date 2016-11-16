require 'cgi'

module LinkOutHelper

  def complete_link_out_template(template, query)
    if template && template.is_a?(Proc)
      instance_exec &template
    elsif template
      template.gsub("%s", CGI.escape(query))
    end
  end

  def link_to_results(search_args:,
                      url_template: nil,
                      label_template: nil,
                      total_items: nil,
                      **link_to_options)
    return "" unless url_template.present?

    label_template = label_template.presence || "View and filter all %i results"
    compiled_label = label_template.gsub("%i", total_items.to_s)

    link_to_options.reverse_merge!(
      target: "_blank",
      data: {
        label_template: label_template,
        has_results_load_template: true,
      }
    )

    link_to compiled_label, complete_link_out_template(url_template, search_args[:query]), link_to_options
  end
end
