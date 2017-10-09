# encoding: utf-8

module DynamicImage
  class Railtie < ::Rails::Railtie
    initializer "dynamic_image" do
      ActionDispatch::Routing::Mapper.send :include, DynamicImage::Routing

      ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
        "DynamicImage::Errors::InvalidSignature" => :unauthorized
      )

      # If Sentry is configured, exclude reporting of tampered signatures
      if Object.const_defined?("Raven")
        Raven.configure do |c|
          c.excluded_exceptions += ["DynamicImage::Errors::InvalidSignature"]
        end
      end

      config.after_initialize do |app|
        secret = app.key_generator.generate_key("dynamic_image")
        DynamicImage.digest_verifier = DynamicImage::DigestVerifier.new(secret)
      end

      ActiveSupport.on_load(:active_record) do
        send :include, DynamicImage::BelongsTo
      end
    end
  end
end
