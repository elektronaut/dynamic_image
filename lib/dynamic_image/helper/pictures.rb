# frozen_string_literal: true

module DynamicImage
  module Helper
    # = DynamicImage Helper Pictures
    #
    # Renders responsive images: a <tt>picture</tt> element with a WebP <tt>source</tt> covering
    # a range of widths, and an <tt>img</tt> fallback in a format everything understands.
    #
    # These are the size agnostic helpers. Where {DynamicImage::Helper#dynamic_image_tag} answers <em>render this at
    # this size</em>, they answer <em>render this responsively</em>, and take an optional +ratio+ instead of a +size+.
    #
    # @see DynamicImage::Picture
    # @see DynamicImage::Breakpoints
    module Pictures
      # Returns a {DynamicImage::Picture} for the record, which is what the tag helpers render. Reach for it
      # directly when the markup is built somewhere else, such as a JSON API feeding a JavaScript component.
      #
      # @param record_or_array [DynamicImage::Model, Array] the record, or an array of records for a nested route
      # @param options [Hash] sizing and routing options, as taken by {DynamicImage::Picture#initialize}
      # @return [DynamicImage::Picture] the picture
      #
      # @example
      #   picture = dynamic_picture(image, ratio: "16:9")
      #   picture.srcset  # => "/images/… 420w, /images/… 590w, …"
      #   picture.sources # => [{ type: "image/webp", srcset: "…" }]
      def dynamic_picture(record_or_array, options = {})
        DynamicImage::Picture.new(self, record_or_array, picture_options(options.symbolize_keys))
      end

      # Renders a responsive <tt>picture</tt> element.
      #
      # The <tt>img</tt> carries the +width+ and +height+ of the
      # fallback, which needn't match whichever candidate is chosen.
      #
      # When the candidates are already in a format the <tt>img</tt> can carry, there is
      # nothing to negotiate: the +srcset+ goes on the <tt>img</tt> and no <tt>picture</tt> is
      # rendered at all. That is what happens to an animated image, which keeps its own format.
      #
      # No +alt+ attribute is generated; pass one as you would to +image_tag+.
      #
      # @param record_or_array [DynamicImage::Model, Array] the record, or an array of records for a nested route
      # @param options [Hash] sizing options, routing options and HTML attributes
      # @option options [Numeric, Vector2d, String] :ratio The aspect ratio to crop to. Implies cropping.
      # @option options [String] :sizes The +sizes+ attribute, telling the browser how large the image will
      #   be rendered. This is the one thing that can't be derived, and the one most worth getting right.
      # @option options [Range, Array<Integer>, Integer] :breakpoints The
      #   widths to offer, overriding {DynamicImage.default_breakpoints}
      # @option options [Numeric] :step The step between breakpoints, overriding {DynamicImage.breakpoint_step}
      # @option options [Integer] :fallback_width The width to ask for the
      #   <tt>img</tt>, overriding {DynamicImage.picture_fallback_width}
      # @return [String] the picture element
      #
      # @example
      #   dynamic_picture_tag(image, sizes: "50vw", alt: "A kitten")
      #   dynamic_picture_tag(image, ratio: "16:9", sizes: "50vw")
      def dynamic_picture_tag(record_or_array, options = {})
        options = options.symbolize_keys
        picture = dynamic_picture(record_or_array, options)
        image = picture_fallback_tag(record_or_array, picture, options)

        return image if picture.sources.empty?

        tag.picture { safe_join([picture_source_tag(picture), image]) }
      end

      # Renders a single <tt>source</tt> element, for composing a <tt>picture</tt> by hand.
      #
      # This is what art direction needs: several sources, each with its own crop and media
      # query. The browser takes the first one whose +media+ matches and whose +type+ it
      # supports, so put the specific queries first and the unconditional one last.
      #
      #
      # @param record_or_array [DynamicImage::Model, Array] the record, or an array of records for a nested route
      # @param options [Hash] sizing and routing options
      # @option options [String] :media The media query this source answers
      # @option options [Symbol, Array<Symbol>] :format The format to render
      #   in. A symbol forces, an array is negotiated. Defaults to WebP.
      # @return [String, nil] the source element
      #
      # @example Art direction
      #   <picture>
      #     <%= dynamic_picture_source_tag(image, ratio: "21:9",
      #                                    media: "(min-width: 1000px)") %>
      #     <%= dynamic_picture_source_tag(image, ratio: "1:1") %>
      #     <%= dynamic_image_tag(image, size: "1200x1200", crop: true) %>
      #   </picture>
      #
      # @example A source for browsers without WebP
      #   dynamic_picture_source_tag(image, ratio: "21:9",
      #                              format: DynamicImage::COMPATIBLE_FORMATS)
      def dynamic_picture_source_tag(record_or_array, options = {})
        options = options.symbolize_keys

        picture_source_tag(dynamic_picture(record_or_array, options), options[:media])
      end

      private

      def picture_source_tag(picture, media = nil)
        srcset = picture.srcset
        return unless srcset

        tag.source(type: picture.type, srcset:, sizes: picture.sizes, media:)
      end

      def picture_fallback_tag(record_or_array, picture, options)
        dynamic_image_tag(
          record_or_array,
          options.except(*DynamicImage::Picture::OPTIONS, :media)
                 .merge(img_srcset_attributes(picture))
                 .merge(size: picture.fallback_size,
                        crop: picture.crop?,
                        format: mime_format(picture.fallback_format))
        )
      end

      # The candidates ride on the img itself when no source carries them.
      def img_srcset_attributes(picture)
        return {} unless picture.sources.empty?

        { srcset: picture.srcset, sizes: picture.sizes }
      end

      # Passes on only the options the picture and the router understand.
      def picture_options(options)
        options.slice(*DynamicImage::Picture::OPTIONS, *allowed_dynamic_image_url_options)
      end
    end
  end
end
