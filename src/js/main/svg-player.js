(function () {
  var svgNamespace = 'http://www.w3.org/2000/svg';
  var animationSelector = 'animate, animateTransform, animateMotion, set';
  var playerCount = 0;
  var sources = new Map();
  var allowedElements = new Set(('svg g defs title desc metadata path rect circle ellipse line polygon polyline ' +
    'text tspan clipPath mask linearGradient radialGradient stop pattern use animate animateTransform animateMotion mpath set').split(' '));
  var drawingAttributes = new Set(('x y x1 x2 y1 y2 cx cy r rx ry d points width height transform opacity ' +
    'fill fill-opacity fill-rule stroke stroke-width stroke-opacity stroke-dasharray stroke-dashoffset ' +
    'stroke-linecap stroke-linejoin stroke-miterlimit visibility display font-family font-size font-style ' +
    'font-weight text-anchor dominant-baseline dx dy rotate offset stop-color stop-opacity').split(' '));
  var allowedAttributes = new Set(Array.from(drawingAttributes).concat(('id class role aria-label aria-labelledby aria-describedby ' +
    'xmlns xmlns:xlink xml:space viewBox preserveAspectRatio href xlink:href clip-path clip-rule mask ' +
    'clipPathUnits maskUnits maskContentUnits gradientUnits gradientTransform spreadMethod fx fy fr ' +
    'patternUnits patternContentUnits patternTransform attributeName attributeType begin dur end min max ' +
    'restart repeatCount repeatDur calcMode values keyTimes keySplines from to by additive accumulate ' +
    'type path keyPoints origin').split(' ')));

  function prepareSvg(svg, prefix) {
    var elements = [svg].concat(Array.from(svg.querySelectorAll('*')));
    var ids = new Map();
    // An image cannot run scripts or access the page; keep that boundary when inlining it.
    elements.forEach(function (element) {
      if (element.namespaceURI !== svgNamespace || !allowedElements.has(element.localName)) {
        throw new Error('Unsupported SVG element: ' + element.localName);
      }
      Array.from(element.attributes).forEach(function (attribute) {
        if (!allowedAttributes.has(attribute.name)) throw new Error('Unsupported SVG attribute: ' + attribute.name);
        var value = attribute.value;
        if (attribute.localName === 'href' && !/^#[\w.-]+$/.test(value)) {
          throw new Error('Only local SVG references are supported');
        }
        if (/url\s*\(/i.test(value) && !/^url\(\s*(['"]?)#[\w.-]+\1\s*\)$/.test(value)) {
          throw new Error('Only local SVG paint references are supported');
        }
      });
      if (element.hasAttribute('id')) {
        if (ids.has(element.id)) throw new Error('Duplicate SVG ID: ' + element.id);
        ids.set(element.id, prefix + element.id);
      }
    });

    var animations = Array.from(svg.querySelectorAll(animationSelector));
    animations.forEach(function (animation) {
      if (animation.hasAttribute('attributeName') && !drawingAttributes.has(animation.getAttribute('attributeName'))) {
        throw new Error('Unsupported animated attribute');
      }
      // These diagrams start together. Leave event-driven or staggered timelines as images.
      if (animation.hasAttribute('begin') && !/^0(?:\.0+)?(?:s|ms)?$/.test(animation.getAttribute('begin'))) {
        throw new Error('Only SVG animations beginning at zero are supported');
      }
      if (animation.hasAttribute('end')) throw new Error('Custom animation end events are not supported');
      animation.setAttribute('begin', 'indefinite');
    });

    elements.forEach(function (element) {
      Array.from(element.attributes).forEach(function (attribute) {
        var value = attribute.value;
        if (attribute.name === 'id') value = ids.get(value);
        else if (attribute.name === 'aria-labelledby' || attribute.name === 'aria-describedby') {
          value = value.split(/\s+/).map(function (id) { return ids.get(id) || id; }).join(' ');
        } else if (attribute.localName === 'href') {
          value = '#' + (ids.get(value.slice(1)) || value.slice(1));
        } else {
          value = value.replace(/url\(\s*(['"]?)#([\w.-]+)\1\s*\)/g, function (match, quote, id) {
            return 'url(#' + (ids.get(id) || id) + ')';
          });
        }
        attribute.value = value;
      });
    });
  }

  async function loadSource(url) {
    var response = await fetch(url);
    if (!response.ok) throw new Error('SVG request failed: HTTP ' + response.status);
    return response.text();
  }

  async function enhanceImage(image) {
    // Preserve linked images and responsive picture/source selection.
    if (image.closest('a, picture') || image.hasAttribute('srcset')) return;
    var url = new URL(image.src, document.baseURI);
    if (!/\.svg$/i.test(url.pathname) || url.hash) return;
    try {
      if (!sources.has(url.href)) sources.set(url.href, loadSource(url.href));
      var source = await sources.get(url.href);
      var parsed = new DOMParser().parseFromString(source, 'image/svg+xml');
      var svg = parsed.documentElement;
      if (parsed.querySelector('parsererror') || svg.localName !== 'svg' || svg.namespaceURI !== svgNamespace) {
        throw new Error('Invalid SVG document');
      }
      if (!svg.querySelector(animationSelector)) return;
      var prefix = 'svg-player-' + (++playerCount) + '-';
      prepareSvg(svg, prefix);
      svg = document.importNode(svg, true);
      if (!svg.id) svg.id = prefix + 'drawing';
      svg.setAttribute('role', 'img');
      if (image.alt) {
        svg.removeAttribute('aria-labelledby');
        svg.setAttribute('aria-label', image.alt);
      }
      var player = document.createElement('span');
      player.className = 'svg-player';
      var width = image.getAttribute('width') || svg.getAttribute('width');
      if (width && /^\d+(?:\.\d+)?(?:px)?$/.test(width)) player.style.width = parseFloat(width) + 'px';
      var button = document.createElement('button');
      button.type = 'button';
      button.className = 'svg-player__control';
      button.setAttribute('aria-controls', svg.id);
      button.setAttribute('aria-label', 'Play animation');
      button.textContent = 'Play';
      var started = false;
      button.addEventListener('click', function () {
        var playing = svg.animationsPaused();
        if (playing) {
          if (!started) {
            svg.setCurrentTime(0);
            svg.querySelectorAll(animationSelector).forEach(function (animation) { animation.beginElement(); });
            started = true;
          }
          svg.unpauseAnimations();
        } else {
          svg.pauseAnimations();
        }
        button.textContent = playing ? 'Pause' : 'Play';
        button.setAttribute('aria-label', playing ? 'Pause animation' : 'Play animation');
        button.dataset.playing = String(playing);
      });
      player.append(svg, button);
      image.replaceWith(player);
      svg.pauseAnimations();
    } catch (error) {
      if (player && player.isConnected) player.replaceWith(image);
      console.warn('Could not add SVG playback controls:', url.href, error);
    }
  }

  function initializeSvgPlayers() {
    document.querySelectorAll('.remote-markdown[data-svg-controls="true"] img').forEach(enhanceImage);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeSvgPlayers);
  } else {
    initializeSvgPlayers();
  }
})();
