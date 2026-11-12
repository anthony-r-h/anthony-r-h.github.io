// Run from the repository root with playwright-cli run-code --filename _tests/svg_player_test.js.
// All documents and requests are supplied here; no site build or network is required.
async page => {
  function assert(condition, message) {
    if (!condition) throw new Error(message);
  }

  const animated = '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120" aria-labelledby="title">' +
    '<title id="title">Animated circle</title><defs><clipPath id="clip"><rect width="120" height="120"/></clipPath></defs>' +
    '<circle id="drawing" cx="20" cy="30" r="10" clip-path="url(#clip)">' +
    '<animate attributeName="cx" values="20;100;20" dur="4s" repeatCount="indefinite"/></circle>' +
    '<use href="#drawing" y="60"/></svg>';
  const fixtures = {
    '/animated.svg': animated,
    '/static.svg': '<svg xmlns="http://www.w3.org/2000/svg"><circle r="10"/></svg>',
    '/script.svg': animated.replace('</svg>', '<script>window.svgScriptRan=true</script></svg>'),
    '/event.svg': animated.replace('cy="30"', 'cy="30" onclick="window.svgEventRan=true"'),
    '/style.svg': animated.replace('</svg>', '<style>body { display: none; }</style></svg>'),
    '/foreign.svg': animated.replace('</svg>', '<foreignObject><div xmlns="http://www.w3.org/1999/xhtml">HTML</div></foreignObject></svg>'),
    '/external.svg': animated.replace('href="#drawing"', 'href="https://example.invalid/external.svg#drawing"'),
    '/dangling.svg': animated.replace('url(#clip)', 'url(#page-clip)'),
    '/delayed.svg': animated.replace('dur="4s"', 'begin="2s" dur="4s"'),
    '/malformed.svg': '<svg><',
    '/duplicate.svg': animated.replace('id="clip"', 'id="title"')
  };
  const fallbacks = ['static', 'script', 'event', 'style', 'foreign', 'external', 'dangling', 'delayed', 'malformed', 'duplicate', 'missing'];
  const html = '<!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>' +
    '<span id="svg-player-1-drawing"></span><svg width="0" height="0"><defs><clipPath id="page-clip"/></defs></svg>' +
    '<div class="remote-markdown" data-svg-controls="true">' +
    '<img id="kept-anchor" title="Diagram title" alt="First diagram" src="/animated.svg" width="120" height="120">' +
    '<img alt="Second diagram" src="/animated.svg" width="120" height="120">' +
    '<img id="invalid-url" src="http://[" alt="Invalid URL">' +
    fallbacks.map(name => '<img id="' + name + '" src="/' + name + '.svg" alt="' + name + '">').join('') +
    '<a href="#kept-anchor"><img id="linked" src="/animated.svg" alt="Linked"></a>' +
    '<picture><img id="picture" src="/animated.svg" alt="Picture"></picture>' +
    '<img id="srcset" src="/animated.svg" srcset="/animated.svg 1x" alt="Responsive">' +
    '</div><div class="remote-markdown"><img id="not-enabled" src="/animated.svg" alt="No opt-in"></div>' +
    '<script src="/svg-player.js"></script></body></html>';
  const fetches = {};
  const warnings = [];
  function recordWarning(message) {
    if (message.type() === 'warning') warnings.push(message.text());
  }
  const pattern = 'http://svg-player.test/**';
  page.on('console', recordWarning);
  await page.route(pattern, async route => {
    const path = new URL(route.request().url()).pathname;
    if (route.request().resourceType() === 'fetch') fetches[path] = (fetches[path] || 0) + 1;
    if (path === '/') return route.fulfill({ body: html, contentType: 'text/html' });
    if (path === '/svg-player.js') return route.fulfill({ path: 'src/js/main/svg-player.js', contentType: 'application/javascript' });
    if (fixtures[path]) return route.fulfill({ body: fixtures[path], contentType: 'image/svg+xml' });
    return route.fulfill({ status: 404, body: 'Not found' });
  });

  try {
    await page.goto('http://svg-player.test/');
    await page.waitForFunction(() => document.querySelectorAll('.svg-player').length >= 2);
    // This fixture has only local, mocked requests; let every validation finish.
    await page.waitForLoadState('networkidle');
    assert(await page.locator('.svg-player').count() === 2, 'Unsupported SVG became a player');
    for (const name of fallbacks.concat(['linked', 'picture', 'srcset', 'not-enabled', 'invalid-url'])) {
      assert(await page.locator('img#' + name).count() === 1, 'Fallback image was lost: ' + name);
    }
    assert(fetches['/animated.svg'] === 1, 'Repeated images fetched the SVG more than once');
    assert(warnings.length === fallbacks.length, 'Missing diagnostics for rejected or failed SVGs');
    assert(!await page.evaluate(() => window.svgScriptRan || window.svgEventRan), 'SVG code executed in the page');
    assert(await page.locator('#kept-anchor.svg-player').count() === 1, 'Image anchor was lost');
    assert(await page.locator('#kept-anchor').getAttribute('title') === 'Diagram title', 'Image title was lost');

    const referencesValid = await page.evaluate(() => {
      const ids = Array.from(document.querySelectorAll('[id]')).map(node => node.id);
      if (ids.length !== new Set(ids).size) return false;
      return Array.from(document.querySelectorAll('.svg-player')).every(player => {
        const svg = player.querySelector('svg');
        const button = player.querySelector('button');
        if (document.getElementById(button.getAttribute('aria-controls')) !== svg) return false;
        const target = document.querySelector(svg.querySelector('use').getAttribute('href'));
        const clipId = svg.querySelector('[clip-path]').getAttribute('clip-path').slice(5, -1);
        return target.closest('svg') === svg && document.getElementById(clipId).closest('svg') === svg;
      });
    });
    assert(referencesValid, 'SVG IDs collided or references escaped their drawing');

    for (const label of ['First diagram', 'Second diagram']) {
      const svg = page.locator('.svg-player > svg[aria-label="' + label + '"]');
      const button = svg.locator('..').locator('button');
      const read = () => svg.evaluate(node => ({
        paused: node.animationsPaused(),
        time: node.getCurrentTime(),
        start: node.querySelector('animate').getStartTime(),
        x: node.querySelector('circle').cx.animVal.value
      }));
      assert(await svg.evaluate(node => node.animationsPaused() && node.querySelector('circle').cx.animVal.value === 20), 'SVG autoplayed');
      await button.press('Enter');
      await page.waitForTimeout(300);
      let playing = await read();
      assert(!playing.paused && playing.time > 0 && playing.x !== 20, 'Keyboard Play did not animate the drawing');
      for (let cycle = 0; cycle < 2; cycle++) {
        await button.click();
        const paused = await read();
        assert(paused.paused, 'Pause did not stop playback');
        assert(await button.getAttribute('aria-label') === 'Play animation', 'Paused label is incorrect');
        await page.waitForTimeout(200);
        const still = await read();
        assert(still.time === paused.time && still.x === paused.x, 'Drawing advanced while paused');
        await button.click();
        playing = await read();
        assert(!playing.paused && playing.time >= paused.time && playing.start === paused.start, 'Play restarted instead of resuming');
        assert(await button.getAttribute('aria-label') === 'Pause animation', 'Playing label is incorrect');
        await page.waitForTimeout(200);
        assert((await read()).x !== paused.x, 'Drawing did not continue after resuming');
      }
      await button.click();
    }
  } finally {
    page.off('console', recordWarning);
    await page.unroute(pattern);
  }
}
