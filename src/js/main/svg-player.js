(function () {
  var svgNamespace = 'http://www.w3.org/2000/svg';
  var animationSelector = 'animate, animateTransform, animateMotion, set';
  var playerCount = 0;
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

  function validateElement(element) {
    // An image cannot run scripts or access the page; keep that boundary when inlining it.
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
  }

  function prepareAnimations(svg) {
    svg.querySelectorAll(animationSelector).forEach(function (animation) {
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
  }

  function scopeReferences(elements, ids) {
    function mappedId(id) {
      if (!ids.has(id)) throw new Error('SVG reference target not found: ' + id);
      return ids.get(id);
    }

    elements.forEach(function (element) {
      Array.from(element.attributes).forEach(function (attribute) {
        var value = attribute.value;
        if (attribute.name === 'id') value = mappedId(value);
        else if (attribute.name === 'aria-labelledby' || attribute.name === 'aria-describedby') {
          value = value.trim().split(/\s+/).filter(Boolean).map(mappedId).join(' ');
        } else if (attribute.localName === 'href') {
          value = '#' + mappedId(value.slice(1));
        } else {
          value = value.replace(/url\(\s*(['"]?)#([\w.-]+)\1\s*\)/g, function (match, quote, id) {
            return 'url(#' + mappedId(id) + ')';
          });
        }
        attribute.value = value;
      });
    });
  }

  function prepareSvg(source, playerId) {
    var parsed = new DOMParser().parseFromString(source, 'image/svg+xml');
    var svg = parsed.documentElement;
    if (parsed.querySelector('parsererror') || svg.localName !== 'svg' || svg.namespaceURI !== svgNamespace) {
      throw new Error('Invalid SVG document');
    }
    if (!svg.querySelector(animationSelector)) return null;

    var elements = [svg].concat(Array.from(svg.querySelectorAll('*')));
    var ids = new Map();
    elements.forEach(function (element) {
      validateElement(element);
      if (element.hasAttribute('id')) {
        if (ids.has(element.id)) throw new Error('Duplicate SVG ID: ' + element.id);
        ids.set(element.id, playerId + '-' + element.id);
      }
    });
    prepareAnimations(svg);
    scopeReferences(elements, ids);
    // Keep the root's generated ID distinct from prefixed IDs inside the drawing.
    if (!svg.id) svg.id = playerId;
    return document.importNode(svg, true);
  }

  function nextPlayerId() {
    var id;
    do {
      id = 'svg-player-' + (++playerCount);
    } while (document.querySelector('[id="' + id + '"], [id^="' + id + '-"]'));
    return id;
  }

  async function loadSource(url) {
    var response = await fetch(url);
    if (!response.ok) throw new Error('SVG request failed: HTTP ' + response.status);
    return response.text();
  }

  async function enhanceImage(image, sources) {
    // Preserve linked images and responsive picture/source selection.
    if (image.closest('a, picture') || image.hasAttribute('srcset')) return;
    var sourceUrl = image.src;
    var player;
    try {
      var url = new URL(sourceUrl, document.baseURI);
      if (!/\.svg$/i.test(url.pathname) || url.hash) return;
      if (!sources.has(url.href)) sources.set(url.href, loadSource(url.href));
      var source = await sources.get(url.href);
      var svg = prepareSvg(source, nextPlayerId());
      if (!svg) return;
      player = createPlayer(image, svg);
      image.replaceWith(player);
      svg.pauseAnimations();
    } catch (error) {
      if (player && player.isConnected) player.replaceWith(image);
      console.warn('Could not add SVG playback controls:', sourceUrl, error);
    }
  }

  function createPlaybackButton(svg) {
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
    return button;
  }

  function createPlayer(image, svg) {
    svg.setAttribute('role', 'img');
    if (image.alt) {
      svg.removeAttribute('aria-labelledby');
      svg.setAttribute('aria-label', image.alt);
    }
    var player = document.createElement('span');
    player.className = 'svg-player';
    if (image.id) player.id = image.id;
    if (image.hasAttribute('title')) player.title = image.title;
    var width = image.getAttribute('width') || svg.getAttribute('width');
    if (width && /^\d+(?:\.\d+)?(?:px)?$/.test(width)) player.style.width = parseFloat(width) + 'px';
    player.append(svg, createPlaybackButton(svg));
    return player;
  }

  function initializeSvgPlayers() {
    var sources = new Map();
    var images = document.querySelectorAll('.remote-markdown[data-svg-controls="true"] img');
    Promise.all(Array.from(images, function (image) { return enhanceImage(image, sources); })).then(function () {
      sources.clear();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeSvgPlayers);
  } else {
    initializeSvgPlayers();
  }
})();
