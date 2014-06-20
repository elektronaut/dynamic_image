# encoding: utf-8

module DynamicImage
  module Helper
    def dynamic_image_path(record_or_array, options={})
      dynamic_image_url(record_or_array, { routing_type: :path }.merge(options))
    end

    def dynamic_image_tag(record_or_array, options={})
      record = extract_record(record_or_array)
      options = {
        alt: image_alt(record.filename)
      }.merge(options)

      size = fit_size!(record_or_array, options)
      url_options = options.extract!(*allowed_dynamic_image_url_options)
      html_options = { size: size }.merge(options)

      image_tag(
        dynamic_image_path_with_size(
          record_or_array,
          size,
          url_options
        ),
        html_options
      )
    end

    def dynamic_image_url(record_or_array, options={})
      size = fit_size!(record_or_array, options)
      dynamic_image_url_with_size(record_or_array, size, options)
    end

    def original_dynamic_image_path(record_or_array, options={})
      dynamic_image_path(record_or_array, { action: :original }.merge(options))
    end

    def original_dynamic_image_url(record_or_array, options={})
      dynamic_image_url(record_or_array, { action: :original }.merge(options))
    end

    def uncropped_dynamic_image_path(record_or_array, options={})
      dynamic_image_path(record_or_array, { action: :uncropped }.merge(options))
    end

    def uncropped_dynamic_image_tag(record_or_array, options={})
      dynamic_image_tag(record_or_array, { action: :uncropped }.merge(options))
    end

    def uncropped_dynamic_image_url(record_or_array, options={})
      dynamic_image_url(record_or_array, { action: :uncropped }.merge(options))
    end

    private

    def allowed_dynamic_image_url_options
      [
        :format, :only_path, :protocol, :host, :subdomain, :domain,
        :tld_length, :port, :anchor, :trailing_slash, :script_name,
        :action, :routing_type
      ]
    end

    def default_format_for_image(record)
      Mime::Type.lookup(record.safe_content_type).to_sym
    end

    def dynamic_image_digest(record, action, size=nil)
      key = [action || 'show', record.id, size].compact.join('-')
      DynamicImage.digest_verifier.generate(key)
    end

    def dynamic_image_path_with_size(record_or_array, size=nil, options={})
      dynamic_image_url_with_size(record_or_array, size, { routing_type: :path }.merge(options))
    end

    def dynamic_image_url_with_size(record_or_array, size=nil, options={})
      record = extract_record(record_or_array)
      options = {
        routing_type: :url,
        action: nil,
        format: default_format_for_image(record),
        size: size
      }.merge(options)
      options[:digest] = dynamic_image_digest(record, options[:action], options[:size])
      polymorphic_url(record_or_array, options)
    end

    def fit_size!(record_or_array, options)
      record = extract_record(record_or_array)
      action = options[:action].try(:to_s)
      size_opts = options.extract!(:size, :crop, :upscale)

      if size_opts[:size]
        DynamicImage::ImageSizing.new(
          record,
          uncropped: (action == "uncropped")
        ).fit(size_opts[:size], size_opts).floor.to_s
      elsif action != "original"
        record.size.floor.to_s
      else
        nil
      end
    end
  end
end
