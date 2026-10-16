(function( $, window, undefined ) {
  // Menu
  $("#menu").click(function() {
    $("body").addClass("push-menu-to-right");
    $("#sidebar").addClass("open");
    $(".overlay").addClass("show");
  });

  $("#mask").click(function() {
    $("body").removeClass("push-menu-to-right");
    $("#sidebar").removeClass("open");
    $(".overlay").removeClass("show");
  });

  // Search
  var bs = {
    close: $(".icon-remove-sign"),
    searchform: $(".search-form"),
    canvas: $("body"),
    dothis: $('.dosearch')
  };

  bs.dothis.on('click', function() {
    $('.search-wrapper').toggleClass('active');
    bs.searchform.toggleClass('active');
    bs.searchform.find('input').focus();
    bs.canvas.toggleClass('search-overlay');
    $('.search-field').simpleJekyllSearch();
  });

  function close_search() {
    $('.search-wrapper').toggleClass('active');
    bs.searchform.toggleClass('active');
    bs.canvas.removeClass('search-overlay');
  }

  bs.close.on('click', close_search);

  // Site theme toggle
  var themeToggle = document.querySelector('.home-theme-switcher');
  if (themeToggle) {
    var themeRoot = document.documentElement;
    var availableThemes = ['iris-light', 'apricot-mesh'];

    function applyHomeTheme(theme, persist) {
      if (availableThemes.indexOf(theme) === -1) {
        theme = 'iris-light';
      }

      themeRoot.setAttribute('data-home-theme', theme);

      var isDark = theme === 'iris-light';
      themeToggle.setAttribute('aria-pressed', isDark ? 'true' : 'false');
      themeToggle.setAttribute('title', isDark ? 'Switch to light theme' : 'Switch to dark theme');

      var themeColor = document.querySelector('meta[name="theme-color"]');
      if (themeColor) {
        themeColor.setAttribute('content', getComputedStyle(document.body).getPropertyValue('--home-background-color').trim());
      }

      if (persist) {
        try {
          window.localStorage.setItem('local-nonsatiation-home-theme', theme);
        } catch (error) {
          console.warn('Theme applies for this visit, but the preference could not be saved.', error);
        }
      }
      document.dispatchEvent(new CustomEvent('site-theme-change'));
    }

    applyHomeTheme(themeRoot.getAttribute('data-home-theme'), false);

    themeToggle.addEventListener('click', function() {
      applyHomeTheme(themeRoot.getAttribute('data-home-theme') === 'iris-light' ? 'apricot-mesh' : 'iris-light', true);
    });
  }

  // Closing menu with ESC
  document.addEventListener('keyup', function(e){
      if(e.keyCode == 27 && $('.search-overlay').length) {
          close_search();
      }
  });
  
  var homeGrid = document.getElementById('grid');
  if (homeGrid) {
      new AnimOnScroll(homeGrid, {
        minDuration : 0.4,
        maxDuration : 0.7,
        viewportFactor : 0.2
      });
  }

  // Init smooth scroll
  smoothScroll.init({
      selectorHeader: '.bar-header', // Selector for fixed headers (must be a valid CSS selector)
      speed: 500, // Integer. How fast to complete the scroll in milliseconds
      updateURL: false // Boolean. Whether or not to update the URL with the anchor hash on scroll
  });

})( Zepto, window );
