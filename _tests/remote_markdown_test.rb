require_relative '../scripts/ruby-glob-compat'
require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../_plugins/tags/remote_markdown'

SOURCE_URL = 'https://raw.githubusercontent.com/owner/repo/main/docs/README.md'.freeze
PROJECT_ROOT = File.expand_path('..', __dir__)

def assert(condition, message)
  raise message unless condition
end

def render_remote(site, markdown, option = '', source_url: SOURCE_URL)
  site.instance_variable_set(:@remote_markdown_cache, { source_url => [markdown, URI(source_url)] })
  template = Liquid::Template.parse("{% remote_markdown \"#{source_url}\" #{option} %}")
  template.render!({}, registers: { site: site })
end

Dir.mktmpdir('remote-markdown-test') do |directory|
  FileUtils.mkdir_p(File.join(directory, '_includes'))
  FileUtils.cp(File.join(PROJECT_ROOT, '_includes/video.html'), File.join(directory, '_includes'))
  site = Jekyll::Site.new(Jekyll.configuration(
    'source' => directory, 'destination' => File.join(directory, '_site'),
    'skip_config_files' => true, 'plugins_dir' => [], 'baseurl' => '/blog', 'quiet' => true
  ))

  checks = {
    'explicit branch and tag references preserve repository-root paths' => lambda do
      %w[heads tags].each do |kind|
        source_url = "https://raw.githubusercontent.com/owner/repo/refs/#{kind}/release/docs/README.md"
        markdown = "![Root](/images/root.svg)\n\n![Relative](images/relative.svg)\n\n[Guide](/guide.md)\n\n[Relative guide](../guide.md)"
        html = render_remote(site, markdown, source_url: source_url)
        assert(html.include?("src=\"https://raw.githubusercontent.com/owner/repo/refs/#{kind}/release/images/root.svg\""), 'Explicit reference was lost in root image URL')
        assert(html.include?("src=\"https://raw.githubusercontent.com/owner/repo/refs/#{kind}/release/docs/images/relative.svg\""), 'Relative image URL changed')
        assert(html.scan("href=\"https://github.com/owner/repo/blob/refs/#{kind}/release/guide.md\"").length == 2, 'GitHub links have an incorrect reference or path')
      end
    end,
    'linked and responsive GIFs preserve their image behavior' => lambda do
      markdown = <<~MARKDOWN
        [![Linked](images/linked.gif)](guide.md)

        <a href="guide.md"><img src="images/html.gif"></a>

        <picture><source srcset="images/small.gif 1x, images/large.gif 2x"><img src="images/fallback.gif"></picture>

        <img src="images/default.gif" srcset="images/large.gif 2x">
      MARKDOWN
      html = render_remote(site, markdown, 'gif_to_video: true')
      assert(!html.include?('<video'), 'Converted a linked or responsive GIF into an interactive video')
      assert(html.scan(/<img\b/).length == 4, 'Original GIF embeds were lost')
      assert(html.include?('https://raw.githubusercontent.com/owner/repo/main/docs/images/large.gif 2x'), 'Responsive image paths were not rewritten')
    end,
    'omitted and false options preserve GIFs' => lambda do
      ['', 'gif_to_video: false', 'autoplay: true loop: true muted: true'].each do |option|
        html = render_remote(site, '![Demo](images/demo.gif)', option)
        assert(html.include?('src="https://raw.githubusercontent.com/owner/repo/main/docs/images/demo.gif"'), 'GIF URL changed')
        assert(!html.include?('<video'), 'Unexpected video without opt-in')
      end
    end,
    'standalone GIF uses the shared player with controls and an accessible label' => lambda do
      html = render_remote(site, '![Demo & details](../images/demo.GIF?raw=1&v=2#t=1)', 'gif_to_video: true')
      assert(html.include?('<figure class="video-embed">'), 'Missing shared figure wrapper')
      assert(html.match?(/<video\s[^>]*\bcontrols\b/m), 'Missing playback controls')
      assert(html.include?('aria-label="Demo &amp; details"'), 'Alt text was not escaped and preserved')
      assert(html.include?('src="https://raw.githubusercontent.com/owner/repo/main/images/demo.mp4?raw=1&amp;v=2#t=1"'), 'Incorrect MP4 URL')
      assert(html.include?('poster="https://raw.githubusercontent.com/owner/repo/main/images/demo.GIF?raw=1&amp;v=2#t=1"'), 'Original image missing as poster')
      %w[autoplay muted loop playsinline].each do |attribute|
        assert(html.match?(/<video[^>]*\b#{attribute}\b/m), "Missing #{attribute}")
      end
      assert(!html.match?(/<p>\s*<figure/), 'Figure nested inside paragraph')
    end,
    'reference images, HTML images, inline images and footnotes convert' => lambda do
      markdown = <<~MARKDOWN
        ![Reference][demo]

        [demo]: /images/reference.gif

        <img src="images/html.gif" alt="HTML demo">

        Before ![Inline](https://example.com/inline.gif) after.

        Footnote[^demo].

        [^demo]: ![Footnote](images/footnote.gif)
      MARKDOWN
      html = render_remote(site, markdown, 'gif_to_video: true')
      assert(html.scan(/<video\s/).length == 4, 'Not all image types converted')
      assert(html.include?('src="https://raw.githubusercontent.com/owner/repo/main/images/reference.mp4"'), 'Repository-root path incorrect')
      assert(html.include?('src="https://example.com/inline.mp4"'), 'Absolute URL incorrect')
      assert(html.include?('Before <span class="video-embed">'), 'Inline wrapper is not valid paragraph content')
      assert(html.include?('</span> after.'), 'Surrounding text changed')
    end,
    'links, other images, code and remote Liquid remain unchanged' => lambda do
      markdown = <<~MARKDOWN
        [Download](images/demo.gif)

        ![Photo](images/photo.png)

        ![Query](images/photo.png?name=demo.gif)

        `![Code](images/code.gif)`

        ```markdown
        ![Fenced](images/fenced.gif)
        ```

        {% include video.html src="remote.mp4" %}
        {{ 123 | plus: 456 }}
      MARKDOWN
      html = render_remote(site, markdown, 'gif_to_video: true')
      assert(!html.include?('<video'), 'Converted non-GIF image or executed remote Liquid')
      assert(html.include?('href="https://github.com/owner/repo/blob/main/docs/images/demo.gif"'), 'Download link changed')
      assert(html.include?('photo.png'), 'Non-GIF image changed')
      assert(html.include?('images/code.gif') && html.include?('images/fenced.gif'), 'Code changed')
      assert(html.include?('include video.html') && !html.include?('579'), 'Remote Liquid executed')
    end,
    'playback options independently honor true and false in any order' => lambda do
      [true, false].repeated_permutation(3) do |autoplay, loop, muted|
        options = "muted: #{muted} loop: #{loop} gif_to_video: true autoplay: #{autoplay}"
        html = render_remote(site, '![Demo](images/demo.gif)', options)
        video = html[/<video\b[^>]*>/m]
        { 'autoplay' => autoplay, 'loop' => loop, 'muted' => muted }.each do |attribute, expected|
          assert(video.match?(/\b#{attribute}\b/) == expected, "Incorrect #{attribute} for #{options}")
        end
        assert(video.match?(/\bcontrols\b/), 'Playback options removed controls')
      end
    end,
    'existing includes default autoplay to muted and honor explicit muted false' => lambda do
      template = Liquid::Template.parse(<<~LIQUID)
        {% include video.html src='/default.mp4' autoplay=true %}
        {% include video.html src='/unmuted.mp4' autoplay=true muted=false %}
      LIQUID
      videos = template.render!({}, registers: { site: site }).scan(/<video\b[^>]*>/m)
      assert(videos.first.match?(/\bmuted\b/), 'Existing autoplay include lost default muting')
      assert(!videos.last.match?(/\bmuted\b/), 'Explicit muted=false was ignored')
    end,
    'video width applies to converted players and is optional' => lambda do
      markdown = "![Demo](images/demo.gif)\n\n<img src=\"images/other.gif\">\n\n![Photo](images/photo.png)"
      html = render_remote(site, markdown, 'video_width: 600 gif_to_video: true autoplay: false')
      videos = html.scan(/<video\b[^>]*>/m)
      assert(videos.length == 2, 'Expected Markdown and HTML images to convert')
      assert(videos.all? { |video| video.include?('style="width: 600px; max-width: 100%;"') }, 'Player width or responsive limit missing')
      assert(!html[/<img\b[^>]*>/].include?('style='), 'Non-GIF image was resized')
      default_html = render_remote(site, markdown, 'gif_to_video: true')
      assert(!default_html.match?(/<video[^>]*style=/m), 'Omitted width changed the default layout')
    end,
    'image loading and dimensions are opt-in and reset for each render' => lambda do
      markdown = "![Opening](images/opening.svg)\n\n![Later](images/later.svg)"
      ['', 'lazy_images: false'].each do |options|
        html = render_remote(site, markdown, options)
        assert(!html.match?(/<img[^>]*(?:loading|width|height)=/), 'Default image behavior changed')
      end
      2.times do
        html = render_remote(site, markdown, 'lazy_images: true image_width: 600 image_height: 750')
        images = html.scan(/<img\b[^>]*>/)
        assert(images.first.include?('loading="eager"'), 'Opening image was deferred')
        assert(images.last.include?('loading="lazy"'), 'Later image was not deferred')
        assert(images.all? { |image| image.include?('width="600"') && image.include?('height="750"') }, 'Image dimensions missing')
      end
    end,
    'image options preserve source attributes and skip converted videos and code' => lambda do
      markdown = <<~MARKDOWN
        ![Video](images/demo.gif)

        ![Opening][opening]

        [opening]: images/opening.svg

        <img src="images/custom.svg" width="300" height="200" loading="eager">

        <img src="images/width-only.svg" width="200">

        `![Code](images/code.svg)`

        Footnote[^demo].

        [^demo]: ![Footnote](images/footnote.svg)
      MARKDOWN
      html = render_remote(site, markdown, 'gif_to_video: true lazy_images: true image_width: 600 image_height: 750')
      images = html.scan(/<img\b[^>]*>/)
      assert(images.length == 4, 'Expected reference, HTML and footnote images only')
      assert(images.first.include?('loading="eager"'), 'Converted video consumed the eager image slot')
      assert(images[1].include?('width="300" height="200" loading="eager"'), 'Explicit source attributes changed')
      assert(!images[2].include?('height='), 'Default height overrode the source proportions')
      assert(images.last.include?('loading="lazy"') && images.last.include?('height="750"'), 'Footnote image was skipped')
      assert(!html[/<video\b[^>]*>/m].match?(/\b(?:loading|width|height)=/), 'Image options affected a video')
    end,
    'SVG playback is opt-in per import and preserves fallback images' => lambda do
      markdown = "![Animated](images/demo.svg)\n\n![Static](images/static.svg)\n\n![Photo](images/photo.png)"
      ['', 'svg_controls: false'].each do |options|
        html = render_remote(site, markdown, options)
        assert(!html.include?('data-svg-controls'), 'SVG controls enabled without opt-in')
      end
      html = render_remote(site, markdown, 'svg_controls: true lazy_images: true image_width: 600 image_height: 750')
      assert(html.include?('<div class="remote-markdown" data-svg-controls="true">'), 'SVG opt-in marker missing')
      assert(html.scan(/<img\b/).length == 3, 'Fallback images were removed')
      assert(html.include?('src="https://raw.githubusercontent.com/owner/repo/main/docs/images/demo.svg"'), 'SVG URL not resolved')
      assert(html.include?('loading="lazy"'), 'SVG option interfered with image loading options')
      assert(html.include?('width="600"'), 'SVG option lost image dimensions')
      template = Liquid::Template.parse("{% remote_markdown '#{SOURCE_URL}' svg_controls: true %}{% remote_markdown '#{SOURCE_URL}' %}")
      html = template.render!({}, registers: { site: site })
      assert(html.scan('data-svg-controls="true"').length == 1, 'SVG option leaked to another import')
    end,
    'invalid options fail explicitly' => lambda do
      ['gif_to_video: yes', 'gif_to_video: "true"', 'unknown: true',
       'gif_to_video: true autoplay: yes', 'loop: "false"', 'muted: falsejunk',
       'autoplay: true autoplay: false', 'video_width: 0', 'video_width: -20',
       'video_width: 1.5', 'video_width: 600px', 'video_width: true',
       'video_width: 600 video_width: 400', 'lazy_images: yes',
       'image_width: 0', 'image_height: -1', 'image_height: 750px',
       'lazy_images: true lazy_images: false', 'svg_controls: yes',
       'svg_controls: true svg_controls: false'].each do |option|
        begin
          Liquid::Template.parse("{% remote_markdown '#{SOURCE_URL}' #{option} %}")
        rescue ArgumentError
          next
        end
        raise "Accepted invalid option: #{option}"
      end
    end,
    'rendering videos does not mutate cached Markdown or leak include variables' => lambda do
      markdown = '![Demo](images/demo.gif)'
      site.instance_variable_set(:@remote_markdown_cache, { SOURCE_URL => [markdown, URI(SOURCE_URL)] })
      template = Liquid::Template.parse(<<~LIQUID)
        {% remote_markdown '#{SOURCE_URL}' gif_to_video: true %}
        {% remote_markdown '#{SOURCE_URL}' %}
        {% include video.html src='/local.mp4' %}
      LIQUID
      html = template.render!({}, registers: { site: site })
      assert(html.scan(/<video\s/).length == 2, 'Player count incorrect')
      assert(html.include?('images/demo.gif"'), 'Cached Markdown was changed')
      assert(html.include?('src="/blog/local.mp4"'), 'Existing local include URL behavior changed')
      assert(html.scan(/aria-label=/).length == 1, 'Label leaked to subsequent include')
      assert(html.scan(/poster=/).length == 1, 'Poster leaked to subsequent include')
      assert(html.scan(/<video[^>]*\bautoplay\b/m).length == 1, 'Autoplay leaked to subsequent include')
      assert(html.scan(/<figure class="video-embed">/).length == 2, 'Existing include wrapper changed')
    end
  }

  checks.each do |name, check|
    check.call
    puts "PASS: #{name}"
  end
  puts "#{checks.length} checks passed."
end
