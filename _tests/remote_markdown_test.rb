require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../_plugins/tags/remote_markdown'

class RemoteMarkdownTest
  URL = 'https://raw.githubusercontent.com/owner/project/main/docs/README.md'
  RAW = 'https://raw.githubusercontent.com/owner/project/main/'
  BLOB = 'https://github.com/owner/project/blob/main/'

  def assert(condition, message = 'assertion failed')
    raise message unless condition
  end

  def includes(text, expected)
    assert(text.include?(expected), "Missing #{expected.inspect} in #{text}")
  end

  def failure(expected)
    error = begin
      yield
      nil
    rescue Jekyll::Errors::FatalException, Liquid::SyntaxError, ArgumentError => caught
      caught
    end
    assert(error, "Expected failure containing #{expected.inspect}")
    includes(error.message, expected)
  end

  def site
    @site ||= Jekyll::Site.new(Jekyll.configuration(
      'source' => @directory, 'destination' => File.join(@directory, '_site'),
      'quiet' => true, 'plugins' => [], 'plugins_dir' => []
    ))
  end

  def render(url = URL)
    Liquid::Template.parse("{% remote_markdown '#{url}' %}").render!(
      {}, registers: { site: site }
    )
  end

  def with_http(routes)
    calls = []
    original = Net::HTTP.method(:start)
    Net::HTTP.define_singleton_method(:start) do |host, port, **options, &block|
      raise 'HTTPS and timeouts required' unless port == 443 && options[:use_ssl] &&
                                                options[:open_timeout] && options[:read_timeout]

      http = Object.new
      http.define_singleton_method(:request) do |request, &response_block|
        url = "https://#{host}#{request.path}"
        calls << url
        result = routes.fetch(url)
        raise result if result.is_a?(Exception)

        code, body, headers = result
        response = Net::HTTPResponse::CODE_TO_OBJ.fetch(code.to_s).new('1.1', code.to_s, '')
        (headers || {}).each { |name, value| response[name] = value }
        response.define_singleton_method(:read_body) { |&consumer| Array(body).each(&consumer) }
        response_block.call(response)
      end
      block.call(http)
    end
    yield calls
  ensure
    Net::HTTP.define_singleton_method(:start, original)
  end

  def test_markdown_links_images_references_and_code
    markdown = <<~'MD'
      ## Assembly

      [Guide](../guide.md?view=1#steps) ![Photo](images/test.png)
      [Root](/LICENSE) ![Root image](/assets/hero.svg)
      [Folder](../examples/) [Local](#assembly)
      [Web](https://example.com/x) [Email](mailto:me@example.com)
      ![CDN](//example.com/pic.png)
      [Reference][guide] ![Reference photo][photo]
      [Space](<../some guide.md>) ![Unicode](<images/café.png>)

      [guide]: ../guide.md "Guide title"
      [photo]: ../images/test.png "Image title"

      `[Example](../unchanged.md)`

      ```markdown
      ![Example](images/unchanged.png)
      {% include secret.html %}
      ```

      {{ site.title }}

      | Part | Count |
      | --- | --- |
      | Frame | 1 |
    MD
    with_http(URL => [200, markdown]) do
      html = render
      includes(html, "href=\"#{BLOB}guide.md?view=1#steps\"")
      includes(html, "src=\"#{RAW}docs/images/test.png\"")
      includes(html, "href=\"#{BLOB}LICENSE\"")
      includes(html, "src=\"#{RAW}assets/hero.svg\"")
      includes(html, "href=\"#{BLOB}examples/\"")
      includes(html, 'href="#assembly"')
      includes(html, 'href="https://example.com/x"')
      includes(html, 'href="mailto:me@example.com"')
      includes(html, 'src="//example.com/pic.png"')
      includes(html, "src=\"#{RAW}images/test.png\"")
      includes(html, "href=\"#{BLOB}some%20guide.md\"")
      includes(html, "src=\"#{RAW}docs/images/caf%C3%A9.png\"")
      includes(html, 'title="Guide title"')
      includes(html, '[Example](../unchanged.md)')
      includes(html, 'images/unchanged.png')
      includes(html, '{{ site.title }}')
      includes(html, '<table>')
    end
  end

  def test_nested_html_media_and_srcset
    markdown = <<~'MD'
      <div><a href="../guide.md"><img src="img/pic.png" width="300"></a>
      <picture><source srcset="small.png 1x, large.png 2x"><img src="fallback.png"></picture>
      <img srcset="one.png, two.png" src="three.png">
      <img srcset="data:image/png;base64,AAAA 1x, other.png 2x">
      <video src="demo.mp4" poster="poster.jpg"><source src="demo.webm"></video></div>
    MD
    with_http(URL => [200, markdown]) do
      html = render
      includes(html, "href=\"#{BLOB}guide.md\"")
      includes(html, "src=\"#{RAW}docs/img/pic.png\"")
      includes(html, 'width="300"')
      includes(html, "srcset=\"#{RAW}docs/small.png 1x, #{RAW}docs/large.png 2x\"")
      includes(html, "srcset=\"#{RAW}docs/one.png, #{RAW}docs/two.png\"")
      includes(html, "srcset=\"data:image/png;base64,AAAA 1x, #{RAW}docs/other.png 2x\"")
      includes(html, "poster=\"#{RAW}docs/poster.jpg\"")
      includes(html, "src=\"#{RAW}docs/demo.webm\"")
    end
  end

  def test_front_matter_and_footnotes
    markdown = "\uFEFF---\r\ntitle: Imported title\r\n---\r\n## Body\n\nText[^1]\n\n[^1]: [Details](../details.md)\n"
    with_http(URL => [200, markdown]) do
      html = render
      assert(!html.include?('Imported title'))
      includes(html, '>Body</h2>')
      includes(html, "href=\"#{BLOB}details.md\"")
    end
  end

  def test_display_math_delimiters
    markdown = <<~'MD'
      Inline math $x^2$.

      $$
      v_0^{\mathrm{DROP}} = \sqrt{2gH^{\mathrm{DROP}}}
      $$

      ```text
      $$
      This is a code sample.
      $$
      ```
    MD
    with_http(URL => [200, markdown]) do
      embedded = render
      html = Kramdown::Document.new(embedded, input: 'GFM').to_html
      includes(html, '$x^2$')
      includes(html, '\\[v_0^{\\mathrm{DROP}} = \\sqrt{2gH^{\\mathrm{DROP}}}\\]')
      includes(html, "$$\nThis is a code sample.\n$$\n")
      assert(!html.include?('<p>[v_0'), 'Display math was parsed as escaped Markdown')
    end
  end

  def test_source_validation_and_syntax
    ['http://raw.githubusercontent.com/a/b/main/README.md',
     'https://example.com/a/b/main/README.md', 'file:///etc/passwd',
     'https://raw.githubusercontent.com/a/b',
     'https://raw.githubusercontent.com/a/b/main/../README.md',
     "#{URL}?token=secret", "#{URL}#heading"].each do |url|
      failure('remote_markdown') { render(url) }
    end
    failure('one quoted GitHub raw URL') { Liquid::Template.parse('{% remote_markdown %}') }
    failure('one quoted GitHub raw URL') do
      Liquid::Template.parse('{% remote_markdown url extra %}')
    end
  end

  def test_empty_front_matter_and_pinned_reference
    url = URL.sub('/main/', '/a1b2c3d4/')
    with_http(url => [200, "---\n---\n![Photo](../pic.png)"]) do
      html = render(url)
      assert(!html.include?('<hr'))
      includes(html, 'src="https://raw.githubusercontent.com/owner/project/a1b2c3d4/pic.png"')
    end
  end

  def test_http_errors_timeouts_size_and_encoding
    [[404, '', {}], [500, '', {}], Net::ReadTimeout.new('timed out'),
     [200, 'x' * (Jekyll::RemoteMarkdownTag::MAX_BYTES + 1)],
     [200, "\xFF".b]].zip(['HTTP 404', 'HTTP 500', 'timed out', '2 MiB', 'UTF-8']).each do |result, message|
      with_http(URL => result) { failure(message) { render } }
    end
  end

  def test_redirects_use_final_file_location
    target = 'https://raw.githubusercontent.com/owner/moved/v1/README.md'
    with_http(URL => [302, '', { 'location' => target }], target => [200, '![Photo](img.png)']) do |calls|
      includes(render, 'src="https://raw.githubusercontent.com/owner/moved/v1/img.png"')
      assert(calls == [URL, target])
    end
  end

  def test_redirect_failures
    with_http(URL => [302, '', { 'location' => URL }]) do |calls|
      failure('too many redirects') { render }
      assert(calls.length == 4)
    end
    with_http(URL => [302, '', { 'location' => 'https://example.com/file.md' }]) do
      failure('use https://raw.githubusercontent.com') { render }
    end
    with_http(URL => [302, '']) { failure('no Location') { render } }
  end

  def test_build_integration_and_cache_reset
    FileUtils.mkdir_p(File.join(@directory, '_posts'))
    File.write(File.join(@directory, '_posts/2020-01-01-example.md'), <<~MD)
      ---
      title: Local title
      permalink: /example/
      ---
      ## Before

      {% remote_markdown '#{URL}' %}

      {% remote_markdown '#{URL}' %}

      **After**
    MD
    routes = { URL => [200, "## Imported\n\n![Photo](pic.png)\n\n{{ site.title }}"] }
    with_http(routes) do |calls|
      site.process
      html = File.read(File.join(@directory, '_site/example/index.html'))
      includes(html, '<h2 id="before">Before</h2>')
      includes(html, '<h2 id="imported">Imported</h2>')
      includes(html, '<strong>After</strong>')
      includes(html, "src=\"#{RAW}docs/pic.png\"")
      includes(html, '{{ site.title }}')
      assert(calls.length == 1, 'Repeated includes should fetch only once per build')
      routes[URL] = [200, 'Updated source']
      site.process
      includes(File.read(File.join(@directory, '_site/example/index.html')), 'Updated source')
      assert(calls.length == 2, 'A new build must fetch fresh source')
    end
  end

  def run
    tests = methods.grep(/^test_/).sort
    tests.each do |name|
      Dir.mktmpdir('remote-markdown-test') do |directory|
        @directory = directory
        @site = nil
        public_send(name)
        puts "PASS #{name}"
      end
    end
    puts "#{tests.length} tests passed"
  end
end

RemoteMarkdownTest.new.run
