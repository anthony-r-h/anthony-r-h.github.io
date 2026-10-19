require 'net/http'
require 'uri'
require 'strscan'
require 'kramdown'
require 'kramdown-parser-gfm'

module Jekyll
  class RemoteMarkdownTag < Liquid::Tag
    MAX_BYTES = 2 * 1024 * 1024

    def initialize(tag_name, input, tokens)
      super
      match = input.strip.match(/\A(["'])(.+)\1\z/)
      raise ArgumentError, 'remote_markdown expects one quoted GitHub raw URL' unless match

      @url = match[2]
    end

    def render(context)
      site = context.registers[:site]
      cache = site.instance_variable_get(:@remote_markdown_cache) || {}
      site.instance_variable_set(:@remote_markdown_cache, cache)
      markdown, uri = cache[@url] ||= fetch(source_uri(@url))
      options = site.config.fetch('kramdown', {}).merge(
        'input' => 'GFM', 'syntax_highlighter' => site.config['highlighter']
      )
      document = Kramdown::Document.new(markdown, options)
      rewrite_links(document.root, uri)
      "\n\n#{document.to_html}\n\n"
    rescue StandardError => error
      raise Jekyll::Errors::FatalException, "remote_markdown #{@url}: #{error.message}"
    end

    private

    def source_uri(url)
      uri = URI.parse(url)
      parts = uri.path.split('/').drop(1)
      unless uri.is_a?(URI::HTTPS) && uri.host == 'raw.githubusercontent.com' &&
             uri.port == 443 && !uri.userinfo && !uri.query && !uri.fragment &&
             parts.length >= 4 && parts.none?(&:empty?) &&
             parts.none? { |part| ['.', '..'].include?(URI::DEFAULT_PARSER.unescape(part)) }
        raise ArgumentError, 'use https://raw.githubusercontent.com/OWNER/REPO/REF/path/to/file.md'
      end
      uri
    end

    def fetch(uri, redirects = 3)
      body = +''
      redirect = nil
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = 'Jekyll remote_markdown'
        http.request(request) do |response|
          case response
          when Net::HTTPSuccess
            response.read_body do |chunk|
              raise 'file exceeds the 2 MiB limit' if body.bytesize + chunk.bytesize > MAX_BYTES

              body << chunk
            end
          when Net::HTTPRedirection
            raise 'too many redirects' if redirects.zero?
            raise 'redirect has no Location header' unless response['location']

            redirect = source_uri(URI.join(uri, response['location']).to_s)
          else
            raise "HTTP #{response.code} fetching Markdown"
          end
        end
      end
      return fetch(redirect, redirects - 1) if redirect

      body.force_encoding(Encoding::UTF_8)
      raise 'file is not valid UTF-8' unless body.valid_encoding?

      body.delete_prefix!("\uFEFF")
      # Imported metadata must not become a heading/table or override the blog post.
      body.sub!(/\A---[ \t]*\r?\n.*?^(?:---|\.\.\.)[ \t]*(?:\r?\n|\z)/m, '')
      [body, uri]
    end

    def rewrite_links(element, uri)
      element.attr.each do |name, value|
        case name
        when 'href'
          element.attr[name] = resolve_url(value, uri, raw: false)
        when 'src', 'poster'
          element.attr[name] = resolve_url(value, uri, raw: true)
        when 'srcset'
          element.attr[name] = resolve_srcset(value, uri)
        end
      end
      element.children.each { |child| rewrite_links(child, uri) }
      rewrite_links(element.value, uri) if element.type == :footnote
    end

    def resolve_srcset(value, uri)
      scanner = StringScanner.new(value)
      output = +''
      until scanner.eos?
        output << scanner.scan(/[\s,]*/)
        url = scanner.scan(/\S+/)
        break unless url

        # A data URL's internal comma is part of the URL, not a separator.
        commas = url[/,+\z/] || ''
        output << resolve_url(url.delete_suffix(commas), uri, raw: true) << commas
        output << scanner.scan(/[^,]*/) if commas.empty?
      end
      output
    end

    def resolve_url(value, uri, raw:)
      return value if value.empty? || value.start_with?('#', '//') || value.match?(/\A[a-z][a-z0-9+.-]*:/i)

      owner, repo, ref, *path = uri.path.split('/').drop(1)
      root = if raw
               "https://raw.githubusercontent.com/#{owner}/#{repo}/#{ref}/"
             else
               "https://github.com/#{owner}/#{repo}/blob/#{ref}/"
             end
      base = value.start_with?('/') ? root : "#{root}#{path.join('/')}"
      escaped = URI::DEFAULT_PARSER.escape(value.delete_prefix('/'), /[^\x21-\x7E]|[<>"{}|\\^`]/)
      URI.join(base, escaped).to_s
    end
  end
end

Liquid::Template.register_tag('remote_markdown', Jekyll::RemoteMarkdownTag)
Jekyll::Hooks.register :site, :after_reset do |site|
  site.instance_variable_set(:@remote_markdown_cache, {})
end
