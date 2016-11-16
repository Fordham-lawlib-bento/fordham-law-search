// Supply a default success callback to the BentoSearc.ajax_load,
// so we can set total hits # in our header/footer properly.

$(document).ready(function() {
  BentoSearch.ajax_load.default_success_callback = function(div) {
    var total = div.find("meta[itemprop=total_items]").attr("content");

    if (! total) {
      return true;
    }

    var resultsBox = this.closest(".search-results-box");

    resultsBox.find("*[data-has-results-load-template]").each(function() {
      var link = $(this);
      var template = link.data("labelTemplate");
      if (template) {
        link.text(  template.replace("%i", parseInt(total).toLocaleString()));
      }
    });
  };
});
