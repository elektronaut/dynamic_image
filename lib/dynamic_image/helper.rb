# encoding: utf-8

module DynamicImage
  module Helper
    def dynamic_image_path(record_or_array, options={})
      dynamic_image_url(record_or_array, { routing_type: :path }.merge(options))
    end

    # def dynamic_image_tag(record_or_array, options={})
    #   url_options = options.extract!(allowed_dynamic_image_url_options)
    #   # Pass size to url_options
    #   image_tag(dynamic_image_path(record_or_array, url_options), options)
    # end

    def dynamic_image_url(record_or_array, options={})
      record = extract_record(record_or_array)
      options[:size] = fit_size!(record, options)

      # Calculate size
      options = {
        routing_type: :url,
        action: nil,
        format: default_format_for_image(record)
      }.merge(options)
      options[:digest] = dynamic_image_digest(record, options[:action], options[:size])
      polymorphic_url(record_or_array, options)
    end

    # Not sure if these are needed
    # def uncropped_dynamic_image_path(record_or_array, options={})
    #   dynamic_image_path(record_or_array, { action: :uncropped }.merge(options))
    # end

    # def uncropped_dynamic_image_tag(record_or_array, options={})
    #   dynamic_image_tag(record_or_array, { action: :uncropped }.merge(options))
    # end

    # def uncropped_dynamic_image_url(record_or_array, options={})
    #   dynamic_image_url(record_or_array, { action: :uncropped }.merge(options))
    # end

    # def original_dynamic_image_path(record_or_array, options={})
    #   dynamic_image_path(record_or_array, { action: :original }.merge(options))
    # end

    # def original_dynamic_image_tag(record_or_array, options={})
    #   dynamic_image_tag(record_or_array, { action: :original }.merge(options))
    # end

    # def original_dynamic_image_url(record_or_array, options={})
    #   dynamic_image_url(record_or_array, { action: :original }.merge(options))
    # end

    private

    # def allowed_dynamic_image_url_options
    #   [
    #     :format, :only_path, :protocol, :host, :subdomain, :domain,
    #     :tld_length, :port, :anchor, :trailing_slash, :script_name,
    #     :action, :routing_type
    #   ]
    # end

    def default_format_for_image(record)
      Mime::Type.lookup(record.safe_content_type).to_sym
    end

    def dynamic_image_digest(record, action, size=nil)
      key = [action || 'show', record.id, size].compact.join('-')
      DynamicImage.digest_verifier.generate(key)
    end

    def fit_size!(record, options)
      size_opts = options.extract!(:size, :crop, :upscale)
      if size_opts[:size]
        DynamicImage::ImageSizing.new(
          record,
          uncropped: (options[:action].try(:to_s) == "uncropped")
        ).fit(size_opts[:size], size_opts).floor.to_s
      else
        nil
      end
    end
  end
end
