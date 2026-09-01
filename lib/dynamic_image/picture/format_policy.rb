# frozen_string_literal: true

module DynamicImage
  class Picture
    # = DynamicImage Picture Format Policy
    #
    # Decides what a responsive image is rendered in. The <tt>source</tt> gets the best format available for
    # output, transcoded unconditionally. The <tt>img</tt> gets one of {DynamicImage::COMPATIBLE_FORMATS}.
    #
    # @see DynamicImage::FormatNegotiator
    class FormatPolicy
      # The format the candidates are rendered in when the view doesn't ask for one.
      DEFAULT_SOURCE_FORMAT = :webp

      # @!attribute [r] record
      #   @return [DynamicImage::Model]
      # @!attribute [r] requested
      #   @return [Symbol, Array<Symbol>, nil]
      attr_reader :record, :requested

      # @param record [DynamicImage::Model] the image
      # @param requested [Symbol, Array<Symbol>, nil] the format the candidates are rendered in. A symbol forces
      #   that format, an array is negotiated, nil takes the default.
      def initialize(record, requested = nil)
        @record = record
        @requested = requested
      end

      # The format the candidates are rendered in.
      #
      # @return [DynamicImage::Format]
      def source
        @source ||= resolve(requested || default_source)
      end

      # The format the fallback image is rendered in.
      #
      # @return [DynamicImage::Format]
      def fallback
        @fallback ||= resolve(fallback_formats)
      end

      private

      def default_source
        record.animated? ? fallback_formats : DEFAULT_SOURCE_FORMAT
      end

      def resolve(value)
        return negotiate(value) if value.is_a?(Array)

        DynamicImage::Format.find(value) ||
          raise(ArgumentError, "unknown format: #{value.inspect}")
      end

      def negotiate(formats)
        DynamicImage::FormatNegotiator.new(record).negotiate(formats)
      end

      # An animated image keeps its own format if it can.
      def fallback_formats
        return DynamicImage::COMPATIBLE_FORMATS unless record.animated?

        [stored_format_name, *DynamicImage::COMPATIBLE_FORMATS].compact
      end

      def stored_format_name
        DynamicImage::Format.content_type(record.content_type)&.name
      end
    end
  end
end
