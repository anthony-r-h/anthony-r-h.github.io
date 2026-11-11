require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../_plugins/tags/remote_markdown'

SOURCE_URL = 'https://raw.githubusercontent.com/owner/repo/main/docs/README.md'.freeze
PROJECT_ROOT = File.expand_path('..', __dir__)

def assert(condition, message)
  raise message unless condition
end

def render_remote(site, markdown, option = '')
  site.instance_variable_set(:@remote_markdown_cache, { SOURCE_URL => [markdown, URI(SOURCE_URL)] })
  template = Liquid::Template.parse("{% remote_markdown \"#{SOURCE_URL}\" #{option} %}")
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
    'invalid options fail explicitly' => lambda do
      ['gif_to_video: yes', 'gif_to_video: "true"', 'unknown: true',
       'gif_to_video: true autoplay: yes', 'loop: "false"', 'muted: falsejunk',
       'autoplay: true autoplay: false', 'video_width: 0', 'video_width: -20',
       'video_width: 1.5', 'video_width: 600px', 'video_width: true',
       'video_width: 600 video_width: 400'].each do |option|
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
