(function(window, document) {
  'use strict';

  function initializeGallery(gallery) {
    var items = Array.prototype.slice.call(gallery.querySelectorAll('[data-gallery-item]'));
    var controls = gallery.querySelector('[data-gallery-controls]');
    var previousButton = gallery.querySelector('[data-gallery-previous]');
    var nextButton = gallery.querySelector('[data-gallery-next]');
    var status = gallery.querySelector('[data-gallery-status]');
    var currentIndex = 0;
    var touchStartX = null;
    var touchStartY = null;

    if (!items.length) {
      return;
    }

    function showItem(index) {
      currentIndex = (index + items.length) % items.length;

      items.forEach(function(item, itemIndex) {
        var isActive = itemIndex === currentIndex;
        item.classList.toggle('is-active', isActive);
        item.setAttribute('aria-hidden', isActive ? 'false' : 'true');
      });

      if (status) {
        status.textContent = (currentIndex + 1) + ' / ' + items.length;
      }
    }

    function showPrevious() {
      showItem(currentIndex - 1);
    }

    function showNext() {
      showItem(currentIndex + 1);
    }

    gallery.classList.add('post-gallery--enhanced');
    gallery.setAttribute('role', 'region');
    gallery.setAttribute('aria-roledescription', 'carousel');
    gallery.setAttribute('tabindex', '0');

    if (controls) {
      controls.hidden = items.length < 2;
    }

    if (previousButton) {
      previousButton.addEventListener('click', showPrevious);
    }

    if (nextButton) {
      nextButton.addEventListener('click', showNext);
    }

    gallery.addEventListener('keydown', function(event) {
      if (event.target.closest && event.target.closest('.post-gallery__link')) {
        return;
      }

      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        showPrevious();
      } else if (event.key === 'ArrowRight') {
        event.preventDefault();
        showNext();
      } else if (event.key === 'Home') {
        event.preventDefault();
        showItem(0);
      } else if (event.key === 'End') {
        event.preventDefault();
        showItem(items.length - 1);
      }
    });

    gallery.addEventListener('touchstart', function(event) {
      if (event.changedTouches.length !== 1) {
        return;
      }

      touchStartX = event.changedTouches[0].clientX;
      touchStartY = event.changedTouches[0].clientY;
    }, { passive: true });

    gallery.addEventListener('touchend', function(event) {
      var deltaX;
      var deltaY;

      if (touchStartX === null || touchStartY === null || event.changedTouches.length !== 1) {
        return;
      }

      deltaX = event.changedTouches[0].clientX - touchStartX;
      deltaY = event.changedTouches[0].clientY - touchStartY;
      touchStartX = null;
      touchStartY = null;

      if (Math.abs(deltaX) < 50 || Math.abs(deltaX) <= Math.abs(deltaY)) {
        return;
      }

      if (deltaX > 0) {
        showPrevious();
      } else {
        showNext();
      }
    }, { passive: true });

    showItem(0);
  }

  function initializeGalleries() {
    Array.prototype.forEach.call(document.querySelectorAll('[data-gallery]'), initializeGallery);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeGalleries);
  } else {
    initializeGalleries();
  }
})(window, document);
