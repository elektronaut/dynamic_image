# frozen_string_literal: true

module DynamicImage
  module Helper
    # = DynamicImage Helper Formats
    #
    # Resolves the <tt>format:</tt> option the helpers in
    # {DynamicImage::Helper} pass to the router.
    #
    # A symbol forces that format. An array, or nothing at all, is
    # negotiated against the image. The default list depends on where
    # the view is rendered: {DynamicImage.mailer_formats} in a mailer,
    # {DynamicImage.default_formats} everywhere else.
    #
    # @see DynamicImage::FormatNegotiator
    module Formats
      private

      def dynamic_image_format(record, format)
        return format unless format.nil? || format.is_a?(Array)

        negotiated_format_for_image(record, format || accepted_image_formats)
      end

      def negotiated_format_for_image(record, accepted)
        format = DynamicImage::FormatNegotiator.new(record).negotiate(accepted)
        Mime::Type.lookup(format.content_type).to_sym
      end

      def accepted_image_formats
        if mailer_view?
          DynamicImage.mailer_formats
        else
          DynamicImage.default_formats
        end
      end

      def mailer_view?
        defined?(ActionMailer::Base) && controller.is_a?(ActionMailer::Base)
      end
    end
  end
end
