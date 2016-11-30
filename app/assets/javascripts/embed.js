(function() {

  var getUrlParameter = function(name) {
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
    var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
    var results = regex.exec(location.search);
    return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
  };

  var ready = function(fn) {
    if (document.readyState != 'loading'){
      fn();
    } else {
      document.addEventListener('DOMContentLoaded', fn);
    }
  }

  ready(function() {
    if (getUrlParameter("search.focus") == "true") {
      document.querySelector(".search-form input[name=q]").focus();
    }

    var type = getUrlParameter("search.type");
    if(type) {
      var selectedRadio = document.querySelector("input[name='direct_search'][value=" + type + "]");
      if(selectedRadio) {
        selectedRadio.checked = true;
      }
    }
  });

})();
