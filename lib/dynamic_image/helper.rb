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
      dynamic_image_sizing!(record, options)

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

    def extract_sizing_options(options)
      size_options = options.extract!(:size, :crop, :upscale)
      options[:size] = nil
      if size_options[:size]
        [sizing_vector(size_options[:size]), size_options]
      else
        [nil, size_options]
      end
    end

    def dynamic_image_sizing!(record, options)
      size, size_options = extract_sizing_options(options)
      if size
        if size_options[:crop] && (size.x == 0 || size.y == 0)
          raise DynamicImage::Errors::InvalidSizeOptions,
                'both width and height must be set when cropping'
        end

        size = record.size.fit(size)     unless size_options[:crop]
        size = record.size.contain(size) unless size_options[:upscale]

        options[:size] = size.floor.to_s
      end
      options
    end

    def sizing_vector(str)
      x, y = str.match(/(\d*)x(\d*)/)[1,2].map(&:to_i)
      Vector2d.new(x, y)
    end
  end
end
