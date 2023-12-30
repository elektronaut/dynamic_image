# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Helper
  #
  # Provides helper methods for rendering and linking to images.
  module Helper
    # Returns the path for a DynamicImage::Model record.
    # Takes the same options as +dynamic_image_url+
    def dynamic_image_path(record_or_array, options = {})
      dynamic_image_url(record_or_array, { routing_type: :path }.merge(options))
    end

    # Returns an HTML image tag for the record. If no size is given, it will
    # render at the original size.
    #
    # ==== Options
    # * <tt>:alt</tt>: If no alt text is given, it will default to the
    #   filename of the uploaded image.
    #
    # See +dynamic_image_url+ for info on how to size and cropping. Options
    # supported by +polymorphic_url+ will be passed to the router. Any other
    # options will be added as HTML attributes.
    #
    # ==== Examples
    #
    #   image = Image.find(params[:id])
    #   dynamic_image_tag(image)
    #   # => <img alt="My file" height="200" src="..." width="320" />
    #   dynamic_image_tag(image, size: "100x100", alt="Avatar")
    #   # => <img alt="Avatar" height="62" src="..." width="100" />
    def dynamic_image_tag(record_or_array, options = {})
      record = extract_dynamic_image_record(record_or_array)
      options = { alt: filename_to_alt(record.filename) }.merge(options)

      size = fit_size!(record_or_array, options)
      url_options = options.extract!(*allowed_dynamic_image_url_options)
      html_options = { size: }.merge(options)

      image_tag(dynamic_image_path_with_size(record_or_array,
                                             size,
                                             url_options),
                html_options)
    end

    # Returns the URL for a DynamicImage::Model record.
    #
    # ==== Options
    #
    # * <tt>:size</tt> - Desired image size, supplied as "{width}x{height}".
    #   The image will be scaled to fit. A partial size like "100x" or "x100"
    #   can be given, if you want a fixed width or height.
    # * <tt>:crop</tt> - If true, the image will be cropped to the given size.
    # * <tt>:upscale</tt> - By default, DynamicImage only scale images down,
    #   never up. Pass <tt>upscale: true</tt> to force upscaling.
    #
    # Any options supported by +polymorphic_url+ are also accepted.
    #
    # ==== Examples
    #
    #   image = Image.find(params[:id])
    #   dynamic_image_url(image)
    #   # => "http://example.com/images/96...d1/300x187/1-2014062020...00.jpg"
    #   dynamic_image_url(image, size: '100x100')
    #   # => "http://example.com/images/72...c2/100x62/1-2014062020...00.jpg"
    #   dynamic_image_url(image, size: '100x100', crop: true)
    #   # => "http://example.com/images/a4...6b/100x100/1-2014062020...00.jpg"
    def dynamic_image_url(record_or_array, options = {})
      size = fit_size!(record_or_array, options)
      dynamic_image_url_with_size(record_or_array, size, options)
    end

    # Returns a path to the original uploaded file for download,
    # without any processing applied. Sizing options are not
    # supported.
    def download_dynamic_image_path(record_or_array, options = {})
      dynamic_image_path(record_or_array, { action: :download }.merge(options))
    end

    # Returns a URL to the original uploaded file for download,
    # without any processing applied. Sizing options are not
    # supported.
    def download_dynamic_image_url(record_or_array, options = {})
      dynamic_image_url(record_or_array, { action: :download }.merge(options))
    end

    # Returns a path to the original uploaded file, without any processing
    # applied. Sizing options are not supported.
    def original_dynamic_image_path(record_or_array, options = {})
      dynamic_image_path(record_or_array, { action: :original }.merge(options))
    end

    # Returns a URL to the original uploaded file, without any processing
    # applied. Sizing options are not supported.
    def original_dynamic_image_url(record_or_array, options = {})
      dynamic_image_url(record_or_array, { action: :original }.merge(options))
    end

    # Same as +dynamic_image_path+, but points to an image with any
    # pre-cropping disabled.
    def uncropped_dynamic_image_path(record_or_array, options = {})
      dynamic_image_path(record_or_array, { action: :uncropped }.merge(options))
    end

    # Same as +dynamic_image_tag+, but renders an image with any
    # pre-cropping disabled.
    def uncropped_dynamic_image_tag(record_or_array, options = {})
      dynamic_image_tag(record_or_array, { action: :uncropped }.merge(options))
    end

    # Same as +dynamic_image_url+, but points to an image with any
    # pre-cropping disabled.
    def uncropped_dynamic_image_url(record_or_array, options = {})
      dynamic_image_url(record_or_array, { action: :uncropped }.merge(options))
    end

    private

    def allowed_dynamic_image_url_options
      %i[format only_path protocol host subdomain domain
         tld_length port anchor trailing_slash script_name
         action routing_type ]
    end

    def default_format_for_image(record)
      Mime::Type.lookup(record.safe_content_type).to_sym
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
      options = {
        routing_type: :url,
        action: nil,
        format: default_format_for_image(record),
        size:
      }.merge(options)
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

    def filename_to_alt(str)
      File.basename(str, ".*")
          .sub(/-[[:xdigit:]]{32,64}\z/, "")
          .tr("-_", " ")
          .capitalize
    end

    def fit_size!(record_or_array, options)
      record = extract_dynamic_image_record(record_or_array)
      action = options[:action].try(:to_s)
      size_opts = options.extract!(:size, :crop, :upscale)
      if size_opts[:size]
        image_sizing(record, size_opts, (action == "uncropped"))
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
