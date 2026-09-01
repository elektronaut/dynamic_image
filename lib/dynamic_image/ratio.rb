# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Ratio
  #
  # Coerces an aspect ratio into a float. Strings, rationals, floats and vectors are all accepted.
  #
  # @example
  #   DynamicImage::Ratio.parse("16:9")           # => 1.7777..
  #   DynamicImage::Ratio.parse("16x9")           # => 1.7777..
  #   DynamicImage::Ratio.parse(Rational(16, 9))  # => 1.7777..
  #   DynamicImage::Ratio.parse(Vector2d(16, 9))  # => 1.7777..
  module Ratio
    class << self
      # Returns the ratio as width divided by height.
      #
      # @param value [Numeric, Vector2d, String, nil] the ratio, as a number, a vector, or a string written with
      #   <tt>:</tt>, <tt>x</tt> or <tt>/</tt> between the two sides
      # @return [Float, nil]
      # @raise [ArgumentError] if the value isn't a usable ratio
      def parse(value)
        return if value.nil?

        ratio = coerce(value)
        unless ratio.is_a?(Float) && ratio.positive? && ratio.finite?
          raise ArgumentError, "invalid ratio: #{value.inspect}"
        end

        ratio
      end

      private

      def coerce(value)
        case value
        when Numeric then value.to_f
        when Vector2d then value.x.to_f / value.y
        when String then value.split(%r{[:x/]}).map(&:to_f).reduce(:/)
        end
      end
    end
  end
end
