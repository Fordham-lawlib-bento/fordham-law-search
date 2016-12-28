# Decorator for BentoSearch::Results targetted at EDS results, doing
# things we need to customize for EDS:
#
# * Delete all links labelled 'Availability', EDS is providing them
#   but we don't want them.

class EdsDecorator < BentoSearch::StandardDecorator

  def other_links
    _base.other_links.delete_if do |link|
      link.label == "Availability"
    end
  end

end
