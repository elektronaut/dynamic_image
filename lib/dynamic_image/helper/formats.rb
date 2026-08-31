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
    # The +original+ and +download+ actions serve the stored file as it
    # is, so they always get the record's own format. Negotiating one
    # would put an extension on the URL that the response doesn't match.
    #
    # @see DynamicImage::FormatNegotiator
    module Formats
      private

      def dynamic_image_format(record, format, action = nil)
        return stored_format_for_image(record) if raw_action?(action)
        return format unless format.nil? || format.is_a?(Array)

        negotiated_format_for_image(record, format || accepted_image_formats)
      end

      def raw_action?(action)
        %w[original download].include?(action.to_s)
      end

      def stored_format_for_image(record)
        mime_format(DynamicImage::Format.content_type(record.content_type))
      end

      def negotiated_format_for_image(record, accepted)
        mime_format(DynamicImage::FormatNegotiator.new(record)
                                                  .negotiate(accepted))
      end

      def mime_format(format)
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
