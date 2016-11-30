// JS code run on the embedded iframe 'guest' page

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
  };

  var outerHeight = function(el) {
    var height = el.offsetHeight;
    var style = getComputedStyle(el);

    height += parseInt(style.marginTop) + parseInt(style.marginBottom);
    return height;
  };

  var sendHeight = function() {
    if(parent.postMessage)
    {
      parent.postMessage({ embedFormHeight: outerHeight(document.body)}, '*');
    }
  };

  window.addEventListener('resize', function(event) {
    sendHeight();
  });


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

    sendHeight();
  });

})();
