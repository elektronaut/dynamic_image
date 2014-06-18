# encoding: utf-8

module DynamicImage
  class Railtie < ::Rails::Railtie
    initializer "dynamic_image" do
      config.after_initialize do |app|
        secret = app.key_generator.generate_key('dynamic_image')
        DynamicImage.digest_verifier = DynamicImage::DigestVerifier.new(secret)
      end
    end
  end
end
