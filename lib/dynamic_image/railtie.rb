# encoding: utf-8

module DynamicImage
  class Railtie < ::Rails::Railtie
    initializer 'dynamic_image' do
      ActionDispatch::Routing::Mapper.send :include, DynamicImage::Routing

      config.after_initialize do |app|
        secret = app.key_generator.generate_key('dynamic_image')
        DynamicImage.digest_verifier = DynamicImage::DigestVerifier.new(secret)
      end

      ActiveSupport.on_load(:active_record) do
        send :include, DynamicImage::BelongsTo
      end
    end
  end
end
