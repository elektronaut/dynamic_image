# frozen_string_literal: true

require "dynamic_image/helper/formats"

module DynamicImage
  # = DynamicImage Helper
  #
  # Provides helper methods for rendering and linking to images.
  #
  # Every URL these helpers generate carries an HMAC digest of the
  # action, the record id and the size. The controller rejects anything
  # that doesn't match, so URLs have to be built here.
  #
  # Each variation comes in three flavours: +_tag+ renders an image tag,
  # +_path+ returns a relative path and +_url+ an absolute one.
  #
  # @see DynamicImage::ImageSizing for how sizes are calculated
  # @see DynamicImage::Helper::Formats for how the format is chosen
  module Helper
    include DynamicImage::Helper::Formats

    # Returns the path for a {DynamicImage::Model} record. Takes the
    # same options as {#dynamic_image_url}.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record, or
    #   an array of records for a nested route
    # @param options [Hash] sizing and routing options
    # @return [String] the path
    def dynamic_image_path(record_or_array, options = {})
      dynamic_image_url(record_or_array, { routing_type: :path }.merge(options))
    end

    # Returns an HTML image tag for the record, with +width+ and
    # +height+ set to the rendered size. If no size is given, it will
    # render at the original size.
    #
    # No +alt+ attribute is generated; pass one as you would to
    # +image_tag+. See {#dynamic_image_url} for sizing and cropping.
    # Options supported by +polymorphic_url+ will be passed to the
    # router, and any others are added as HTML attributes.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record, or
    #   an array of records for a nested route
    # @param options [Hash] sizing options, routing options and HTML
    #   attributes
    # @return [String] the image tag
    #
    # @example
    #   image = Image.find(params[:id])
    #
    #   dynamic_image_tag(image)
    #   # => <img src="..." width="320" height="200" />
    #
    #   dynamic_image_tag(image, size: "100x100", alt: "Avatar")
    #   # => <img alt="Avatar" src="..." width="100" height="62" />
    #
    # @example Responsive markup
    #   dynamic_image_tag(image, size: "800x", srcset: srcset, sizes: "50vw")
    def dynamic_image_tag(record_or_array, options = {})
      size = fit_size!(record_or_array, options)
      url_options = options.extract!(*allowed_dynamic_image_url_options)
      html_options = { size: }.merge(options)

      image_tag(dynamic_image_path_with_size(record_or_array,
                                             size,
                                             url_options),
                html_options)
    end

    # Returns the URL for a {DynamicImage::Model} record.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record, or
    #   an array of records for a nested route
    # @param options [Hash] sizing and routing options
    # @option options [String] :size Desired image size, as
    #   <tt>"{width}x{height}"</tt>. The image is scaled to fit. A
    #   partial size like <tt>"100x"</tt> or <tt>"x100"</tt> can be
    #   given for a fixed width or height.
    # @option options [Boolean] :crop Crop the image to the given size
    #   instead of fitting it. Both dimensions are required.
    # @option options [Boolean] :upscale By default images are only
    #   scaled down, never up. Pass true to force upscaling.
    # @option options [Symbol, Array<Symbol>] :format Render in a
    #   different format. A symbol forces that format. An array says any
    #   of them will do, and the best fit is chosen — see
    #   {DynamicImage::FormatNegotiator}. Defaults to
    #   {DynamicImage.default_formats}, or {DynamicImage.mailer_formats}
    #   in a mailer view.
    # @return [String] the URL
    # @raise [DynamicImage::Errors::InvalidSizeOptions] if
    #   <tt>crop: true</tt> is given without both dimensions
    #
    # Any options supported by +polymorphic_url+ are also accepted.
    #
    # @example
    #   image = Image.find(params[:id])
    #
    #   dynamic_image_url(image)
    #   # => "http://example.com/images/96...d1/300x187/1-2014062020...00.jpg"
    #
    #   dynamic_image_url(image, size: '100x100')
    #   # => "http://example.com/images/72...c2/100x62/1-2014062020...00.jpg"
    #
    #   dynamic_image_url(image, size: '100x100', crop: true)
    #   # => "http://example.com/images/a4...6b/100x100/1-2014062020...00.jpg"
    def dynamic_image_url(record_or_array, options = {})
      size = fit_size!(record_or_array, options)
      dynamic_image_url_with_size(record_or_array, size, options)
    end

    # Returns a path to the original uploaded file, served as an
    # attachment so the browser downloads it. No processing is applied
    # and sizing options are not supported. The URL carries the stored
    # format's extension; +:format+ has no effect.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] routing options
    # @return [String] the path
    def download_dynamic_image_path(record_or_array, options = {})
      dynamic_image_path(record_or_array, { action: :download }.merge(options))
    end

    # Same as {#download_dynamic_image_path}, but returns an absolute
    # URL.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] routing options
    # @return [String] the URL
    def download_dynamic_image_url(record_or_array, options = {})
      dynamic_image_url(record_or_array, { action: :download }.merge(options))
    end

    # Returns a path to the original uploaded file, exactly as it was
    # uploaded. No processing is applied and sizing options are not
    # supported. The URL carries the stored format's extension;
    # +:format+ has no effect.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] routing options
    # @return [String] the path
    def original_dynamic_image_path(record_or_array, options = {})
      dynamic_image_path(record_or_array, { action: :original }.merge(options))
    end

    # Same as {#original_dynamic_image_path}, but returns an absolute
    # URL.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] routing options
    # @return [String] the URL
    def original_dynamic_image_url(record_or_array, options = {})
      dynamic_image_url(record_or_array, { action: :original }.merge(options))
    end

    # Same as {#dynamic_image_path}, but points to an image with any
    # pre-cropping disabled.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] sizing and routing options
    # @return [String] the path
    def uncropped_dynamic_image_path(record_or_array, options = {})
      dynamic_image_path(record_or_array, { action: :uncropped }.merge(options))
    end

    # Same as {#dynamic_image_tag}, but renders an image with any
    # pre-cropping disabled.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] sizing options, routing options and HTML
    #   attributes
    # @return [String] the image tag
    def uncropped_dynamic_image_tag(record_or_array, options = {})
      dynamic_image_tag(record_or_array, { action: :uncropped }.merge(options))
    end

    # Same as {#dynamic_image_url}, but points to an image with any
    # pre-cropping disabled.
    #
    # @param record_or_array [DynamicImage::Model, Array] the record
    # @param options [Hash] sizing and routing options
    # @return [String] the URL
    def uncropped_dynamic_image_url(record_or_array, options = {})
      dynamic_image_url(record_or_array, { action: :uncropped }.merge(options))
    end

    private

    def allowed_dynamic_image_url_options
      %i[format only_path protocol host subdomain domain
         tld_length port anchor trailing_slash script_name
         action routing_type ]
    end

    def dynamic_image_digest(record, action, size = nil)
      key = [action || "show", record.id, size].compact.join("-")
      DynamicImage.digest_verifier.generate(key)
    end

    def dynamic_image_path_with_size(record_or_array, size = nil, options = {})
      dynamic_image_url_with_size(record_or_array,
                                  size,
                                  { routing_type: :path }.merge(options))
    end

    def dynamic_image_url_with_size(record_or_array, size = nil, options = {})
      record = extract_dynamic_image_record(record_or_array)
      options = { routing_type: :url, action: nil, size: }.merge(options)
      options[:routing_type] = :url if mailer_view?
      options[:format] = dynamic_image_format(record, options[:format],
                                              options[:action])
      options[:digest] =
        dynamic_image_digest(record, options[:action], options[:size])
      polymorphic_url(record_or_array, options)
    end

    def extract_dynamic_image_record(record_or_array)
      case record_or_array
      when Array
        record_or_array.last
      else
        record_or_array
      end
    end

    def fit_size!(record_or_array, options)
      record = extract_dynamic_image_record(record_or_array)
      action = options[:action].try(:to_s)
      size_opts = options.extract!(:size, :crop, :upscale)
      if size_opts[:size]
        image_sizing(record, size_opts, action == "uncropped")
      else
        (action == "original" ? record.real_size : record.size).floor.to_s
      end
    end

    def image_sizing(record, size_opts, uncropped)
      ImageSizing
        .new(record, uncropped:)
        .fit(size_opts[:size], size_opts).floor.to_s
    end
  end
end
