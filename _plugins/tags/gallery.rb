require 'cgi'
require 'yaml'

module Jekyll
  class RenderGalleryTag < Liquid::Block
    def render(context)
      items = parse_items(super(context))

      output = ['<div class="post-gallery" data-gallery aria-label="Image gallery">']
      output << '<div class="post-gallery__viewport">'
      items.each_with_index do |item, index|
        output << render_item(item, index.zero?, context)
      end
      output << '</div>'
      output.concat(render_controls(items.length)) if items.length > 1
      output << '</div>'
      output.join("\n")
    end

    private

    def parse_items(source)
      items = YAML.safe_load(source, permitted_classes: [], aliases: false)

      unless items.is_a?(Array) && !items.empty?
        raise Liquid::SyntaxError, 'Gallery contents must be a non-empty YAML list'
      end

      items.each_with_index do |item, index|
        unless item.is_a?(Hash)
          raise Liquid::SyntaxError, "Gallery item #{index + 1} must be a YAML object"
        end

        image = item['image'].to_s.strip
        if image.empty?
          raise Liquid::SyntaxError, "Gallery item #{index + 1} is missing an image"
        end
      end

      items
    rescue Psych::SyntaxError => error
      raise Liquid::SyntaxError, "Invalid gallery YAML: #{error.problem}"
    end

    def render_item(item, active, context)
      image = escape(item['image'].to_s.strip)
      caption = item['caption'].to_s.strip
      caption_html = caption.empty? ? '' : render_caption(caption, context)
      alt = if item.key?('alt')
              item['alt'].to_s.strip
            else
              strip_markup(caption_html)
            end

      output = [
        "<figure class=\"post-gallery__item#{active ? ' is-active' : ''}\" data-gallery-item>",
        "  <a class=\"post-gallery__link\" href=\"#{image}\">",
        "    <img class=\"post-gallery__image\" src=\"#{image}\" alt=\"#{escape(alt)}\" loading=\"lazy\" decoding=\"async\">",
        '  </a>'
      ]

      unless caption_html.empty?
        output << "  <figcaption class=\"post-gallery__caption\">#{caption_html}</figcaption>"
      end

      output << '</figure>'
      output.join("\n")
    end

    def render_caption(caption, context)
      site = context.registers.fetch(:site)
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      html = converter.convert(caption).strip
      html.sub(/\A<p>/, '').sub(%r{</p>\z}, '')
    end

    def strip_markup(value)
      CGI.unescapeHTML(value.gsub(%r{<[^>]+>}, ''))
    end

    def render_controls(item_count)
      [
        '<div class="post-gallery__controls" data-gallery-controls hidden>',
        '  <button class="post-gallery__button" type="button" data-gallery-previous aria-label="Previous image">&#8592;</button>',
        "  <span class=\"post-gallery__status\" data-gallery-status aria-live=\"polite\" aria-atomic=\"true\">1 / #{item_count}</span>",
        '  <button class="post-gallery__button" type="button" data-gallery-next aria-label="Next image">&#8594;</button>',
        '</div>'
      ]
    end

    def escape(value)
      CGI.escapeHTML(value)
    end
  end
end

Liquid::Template.register_tag('gallery', Jekyll::RenderGalleryTag)
