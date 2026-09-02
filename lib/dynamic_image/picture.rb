# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Picture
  #
  # Everything needed to render an image responsively: the candidate widths, the signed URLs behind them, and the
  # fallback the <tt>img</tt> points at.
  #
  # Sizing is expressed as an optional ratio instead of a size.
  #
  # @example
  #   picture = DynamicImage::Picture.new(self, image, ratio: "16:9")
  #   picture.srcset # => "/images/… 420w, /images/… 590w, …"
  #   picture.src    # => "/images/…/1200x675/…jpg"
  #
  # @see DynamicImage::Breakpoints for how the widths are chosen
  # @see DynamicImage::Helper#dynamic_picture_tag
  class Picture
    # The options this class consumes. Anything else is passed on to the router.
    OPTIONS = %i[ratio sizes breakpoints step fallback_width format uncropped].freeze

    # @!attribute [r] record
    #   @return [DynamicImage::Model]
    # @!attribute [r] ratio
    #   @return [Float, nil]
    # @!attribute [r] sizes
    #   @return [String] the +sizes+ attribute
    # @!attribute [r] breakpoints
    #   @return [DynamicImage::Breakpoints] the candidate widths
    # @!attribute [r] fallback_width
    #   @return [Integer] the width asked for the fallback image
    attr_reader :template, :record_or_array, :ratio, :sizes, :breakpoints, :fallback_width, :url_options

    # @param template [ActionView::Base] the view context, for routing
    # @param record_or_array [DynamicImage::Model, Array] the record, or an array of records for a nested route
    # @param options [Hash]
    # @option options [Numeric, Vector2d, String, nil] :ratio The aspect ratio to crop to, as a number, a vector, or a
    #   string like <tt>"16:9"</tt>. Implies cropping. Omit for the image's own.
    # @option options [String] :sizes The +sizes+ attribute
    # @option options [Range, Array<Integer>, Integer] :breakpoints The widths to offer, overriding
    #   {DynamicImage.default_breakpoints}
    # @option options [Numeric] :step The step between breakpoints, overriding {DynamicImage.breakpoint_step}
    # @option options [Integer] :fallback_width The width to ask for the fallback image, overriding
    #   {DynamicImage.picture_fallback_width}
    # @option options [Symbol, Array<Symbol>] :format The format the candidates are rendered in. A symbol forces
    #   that format, an array is negotiated. Defaults to WebP, or the image's own format if it is animated.
    # @option options [Boolean] :uncropped Size against the whole image, ignoring any pre-cropping. Defaults to
    #   whether the URL points at the +uncropped+ action.
    #
    # Any options supported by +polymorphic_url+ are also accepted, and passed on to the router.
    def initialize(template, record_or_array, options = {})
      options = options.symbolize_keys
      @template = template
      @record_or_array = Array(record_or_array)
      @ratio = DynamicImage::Ratio.parse(options[:ratio])
      @sizes = options[:sizes] || "100vw"
      @requested_format = options[:format]
      @fallback_width = fallback_width_from(options)
      @breakpoints = breakpoints_from(options)
      @url_options = options.except(*OPTIONS)
      @uncropped = options.fetch(:uncropped) { url_options[:action].to_s == "uncropped" }
    end

    # Returns true if the image is cropped, which it is whenever a ratio is given.
    #
    # @return [Boolean]
    def crop?
      !ratio.nil?
    end

    # The widest the image can be rendered at: its own width, or the width of the largest crop matching the ratio.
    #
    # @return [Integer]
    def available_width
      @available_width ||= sizing.available_width(ratio)
    end

    # The candidate widths, smallest first.
    #
    # @return [Array<Integer>]
    def widths
      @widths ||= breakpoints.widths(available_width)
    end

    # Every candidate, as the URL and the size it is actually rendered at.
    #
    # @return [Array<Hash>]
    def variants
      @variants ||= widths.map { |width| variant(width) }
    end

    # The +srcset+ attribute for the candidates, or nil if there are none. It belongs on the <tt>source</tt> when
    # {#sources} has one, and on the <tt>img</tt> when it doesn't.
    #
    # @return [String, nil]
    def srcset
      return if variants.empty?

      variants.map { |v| "#{v[:url]} #{v[:width]}w" }.join(", ")
    end

    # The sources to render, as +type+ and +srcset+ pairs.
    #
    # Empty when the candidates are in the same format as the fallback; {#srcset} goes on the <tt>img</tt> instead.
    # That is what happens to an animated image, which keeps its own format.
    #
    # @return [Array<Hash>]
    def sources
      candidates = srcset
      return [] if candidates.nil? || format == fallback_format

      [{ type:, srcset: candidates }]
    end

    # The content type the candidates are rendered as, for the +type+ attribute.
    #
    # @return [String]
    def type
      format.content_type
    end

    # The format the fallback image is rendered in, negotiated from {DynamicImage::COMPATIBLE_FORMATS}.
    #
    # @return [DynamicImage::Format]
    def fallback_format
      format_policy.fallback
    end

    # The size asked for the fallback image, as a <tt>"{width}x{height}"</tt> string.
    #
    # @return [String]
    def fallback_size
      @fallback_size ||= size_for(fallback_width)
    end

    # The size the fallback image is actually rendered at. Smaller than {#fallback_size} when the image is.
    #
    # @return [Vector2d]
    def dimensions
      @dimensions ||= sizing.fit(fallback_size, crop: crop?).floor
    end

    # The URL for the fallback image.
    #
    # @return [String]
    def src
      url_for(fallback_size, fallback_format)
    end

    # The width of the fallback image.
    #
    # @return [Integer]
    def width
      dimensions.x.to_i
    end

    # The height of the fallback image.
    #
    # @return [Integer]
    def height
      dimensions.y.to_i
    end

    private

    def fallback_width_from(options)
      (options[:fallback_width] || DynamicImage.picture_fallback_width).to_i
    end

    def breakpoints_from(options)
      DynamicImage::Breakpoints.new(options[:breakpoints], step: options[:step])
    end

    def record
      record_or_array.last
    end

    def sizing
      @sizing ||= DynamicImage::ImageSizing.new(record, uncropped: @uncropped)
    end

    def variant(width)
      requested = size_for(width)
      size = sizing.fit(requested, crop: crop?).floor
      # {#url_for} fits the size it is given. +size+ has been floored to whole pixels, so it is no longer exactly
      # proportional and would fit smaller a second time. Pass the request instead.
      { url: url_for(requested, format),
        width: size.x.to_i,
        height: size.y.to_i }
    end

    def size_for(width)
      return "#{width}x" unless ratio

      "#{width}x#{(width / ratio).round}"
    end

    def url_for(requested_size, image_format)
      template.dynamic_image_path(record_or_array,
                                  url_options.merge(
                                    size: requested_size,
                                    crop: crop?,
                                    format: image_format.mime_type.to_sym
                                  ))
    end

    def format
      format_policy.source
    end

    def format_policy
      @format_policy ||= FormatPolicy.new(record, @requested_format)
    end
  end
end
