---
layout: post
title: "Solving the Geometry of Manufacture-Constrained Stitch Placement"
subtitle: "" 
optimized_image: /files/Autostitch/emblem.svg
category: Research
tags:
    - Plan
    - Tools
    - Autostitch plugin
math: true
toc: true -1
planning_tag: In Progress
planning_status: "Beta testing BricsCAD plugin."
---

{% remote_markdown "https://raw.githubusercontent.com/anthony-r-h/Autostitch-cad/refs/heads/main/docs/PITCH_authored.md" gif_to_video: true autoplay: true loop: true muted: true video_width: 600 lazy_images: false image_width: 600 image_height: 750 %}

# Autostitch Plugin

[Autostitch is on GitHub](https://github.com/anthony-r-h/Autostitch-cad). It's free and open source under the MIT License. Use it, change it, build it into other tools. Currently it's only available for BricsCAD. AutoCAD uses the same LISP foundation, and I'll port it at some point. Download and extract the repository, run `APPLOAD` and load `AUTOSTITCH.lsp`, then run `AUTOSTITCH` to open the palette.

## SVG animation comparison

Temporary test: open this post at the top, wait a few seconds, then scroll down to these four samples. Scroll past each one and back again. Note which letters animate and which freeze. Each animation should repeat every 10 seconds.

The image samples load an SVG as a separate image, like the diagrams above. The inline samples load the same file and place its drawing elements directly into this page. All four load without waiting for you to scroll to them.

<style>
  .autostitch-svg-test {
    max-width: 600px;
    margin: 2rem auto;
  }
  .autostitch-svg-test img,
  .autostitch-svg-test svg {
    display: block;
    width: 100%;
    max-width: 600px;
    height: auto;
    margin: 0;
  }
  .autostitch-svg-test__drawing {
    aspect-ratio: 600 / 750;
  }
</style>

### A. Half - image

<div class="autostitch-svg-test">
  <img src="{{ '/files/Autostitch/half.animated.svg' | relative_url }}" width="600" height="750" loading="eager" alt="Half geometry animation, embedded as an image">
</div>

### B. Half - inline

<div class="autostitch-svg-test">
  <div class="autostitch-svg-test__drawing" id="autostitch-inline-half" data-svg-src="{{ '/files/Autostitch/half.animated.svg' | relative_url }}">
    <p>Loading inline animation...</p>
  </div>
  <noscript>JavaScript is needed to insert this inline sample.</noscript>
</div>

### C. Vertex - image

<div class="autostitch-svg-test">
  <img src="{{ '/files/Autostitch/vertex.animated.svg' | relative_url }}" width="600" height="750" loading="eager" alt="Vertex geometry animation, embedded as an image">
</div>

### D. Vertex - inline

<div class="autostitch-svg-test">
  <div class="autostitch-svg-test__drawing" id="autostitch-inline-vertex" data-svg-src="{{ '/files/Autostitch/vertex.animated.svg' | relative_url }}">
    <p>Loading inline animation...</p>
  </div>
  <noscript>JavaScript is needed to insert this inline sample.</noscript>
</div>

For comparison, open either file on its own: [half SVG]({{ '/files/Autostitch/half.animated.svg' | relative_url }}) or [vertex SVG]({{ '/files/Autostitch/vertex.animated.svg' | relative_url }}).

<script>
  (function () {
    async function loadInlineSvg(container) {
      try {
        var response = await fetch(container.getAttribute('data-svg-src'));
        if (!response.ok) throw new Error('SVG request failed: HTTP ' + response.status);
        var source = await response.text();
        var parsed = new DOMParser().parseFromString(source, 'image/svg+xml');
        var svg = parsed.documentElement;
        if (parsed.querySelector('parsererror') || svg.localName !== 'svg') {
          throw new Error('Invalid SVG document');
        }

        // These two files share title, description, and metadata IDs.
        svg.querySelectorAll('[id]').forEach(function (element) {
          element.id = container.id + '-' + element.id;
        });
        svg.setAttribute('aria-labelledby', svg.getAttribute('aria-labelledby').split(/\s+/).map(function (id) {
          return container.id + '-' + id;
        }).join(' '));
        container.replaceChildren(document.importNode(svg, true));
      } catch (error) {
        container.textContent = 'Inline animation could not load: ' + error.message;
        console.error('Autostitch SVG comparison:', error);
      }
    }

    document.querySelectorAll('.autostitch-svg-test [data-svg-src]').forEach(loadInlineSvg);
  })();
</script>
