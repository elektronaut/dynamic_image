# frozen_string_literal: true

module DynamicImage
  class Engine < ::Rails::Engine
    initializer "dynamic_image.digest_verifier" do
      config.after_initialize do |app|
        secret = app.key_generator.generate_key("dynamic_image")
        DynamicImage.digest_verifier = DynamicImage::DigestVerifier.new(secret)
      end
    end

    initializer "dynamic_image.migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "dynamic_image.mime_types" do
      Mime::Type.register "image/bmp", :bmp
      Mime::Type.register "image/gif", :gif
      Mime::Type.register "image/jpeg", :jpg
      Mime::Type.register "image/jpeg", :jpeg
      Mime::Type.register "image/png", :png
      Mime::Type.register "image/tiff", :tiff
      Mime::Type.register "image/webp", :webp
    end

    initializer "dynamic_image.extensions", before: :load_active_support do
      ActiveSupport.on_load(:active_record) do
        send :include, DynamicImage::BelongsTo
      end
      ActionDispatch::Routing::Mapper.include DynamicImage::Routing

      ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
        "DynamicImage::Errors::InvalidSignature" => :unauthorized
      )
    end

    initializer "dynamic_image.sentry" do
      # If Sentry is configured, exclude reporting of tampered signatures
      if Object.const_defined?("Raven")
        Raven.configure do |c|
          c.excluded_exceptions += ["DynamicImage::Errors::InvalidSignature"]
        end
      end
    end
  end
end
