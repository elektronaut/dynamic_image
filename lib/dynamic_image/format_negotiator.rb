# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Format Negotiator
  #
  # Picks the format to render an image in, given the formats the consumer accepts.
  #
  # An acceptable source format is used as-is. Otherwise the image is transcoded to the candidate that keeps the
  # most of it: animation is preserved before transparency, and a constraint no candidate can satisfy is dropped
  # instead of vetoing the next one.
  #
  # Selection is keyed on the properties the image has, not on what its format is capable of. A photograph uploaded
  # as WebP renders as JPEG, not as a 256 colour GIF.
  #
  # Images stored before +frame_count+ and +alpha+ existed have neither, and an unacceptable source format resolves
  # to JPEG.
  #
  # @example
  #   DynamicImage::FormatNegotiator.new(image).negotiate(%i[jpeg png gif])
  #   # => the PNG format
  #
  # @see DynamicImage::Format
  class FormatNegotiator
    FALLBACK = "JPEG"

    # @!attribute [r] record
    #   @return [DynamicImage::Model]
    attr_reader :record

    # @param record [DynamicImage::Model] the image
    def initialize(record)
      @record = record
    end

    # Returns the format to render in.
    #
    # @param accepted [Array<Symbol, String>] the acceptable format names, most preferred first. Unrecognized names
    #   are ignored.
    # @return [DynamicImage::Format]
    def negotiate(accepted)
      candidates = Array(accepted).filter_map { |name| Format.find(name) }
      source(candidates) || transcode(candidates) || Format.find(FALLBACK)
    end

    private

    def source(candidates)
      candidates.find { |f| f.content_types.include?(record.content_type) }
    end

    def transcode(candidates)
      return unless known?

      candidates = narrow(candidates, :animated?) if animated?
      candidates = narrow(candidates, :alpha?) if alpha?
      candidates.first
    end

    def narrow(candidates, capability)
      supported = candidates.select(&capability)
      supported.any? ? supported : candidates
    end

    def frame_count
      record.frame_count if record.has_attribute?(:frame_count)
    end

    def alpha
      record.alpha if record.has_attribute?(:alpha)
    end

    def known?
      !frame_count.nil? && !alpha.nil?
    end

    def animated?
      record.animated?
    end

    def alpha?
      alpha ? true : false
    end
  end
end
