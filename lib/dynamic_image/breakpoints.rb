# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Breakpoints
  #
  # Works out the candidate widths for a +srcset+, given the widest the image can be rendered at.
  #
  # A range steps down geometrically from the available width. An array
  # lists the widths outright. A single number asks for one candidate.
  #
  # @example
  #   DynamicImage::Breakpoints.new(320..3200).widths(2000)
  #   # => [370, 520, 720, 1020, 1420, 2000]
  #
  #   DynamicImage::Breakpoints.new([400, 800, 1600]).widths(1000)
  #   # => [400, 800]
  #
  # @see DynamicImage::Picture
  class Breakpoints
    # Candidate widths are snapped down to a multiple of this, so
    # that nearby images don't each get their own set of odd sizes.
    SNAP = 10

    # @!attribute [r] spec
    #   @return [Range, Array<Integer>, Integer] the breakpoint spec
    # @!attribute [r] step
    #   @return [Float] the ratio between two candidates
    attr_reader :spec, :step

    # @param spec [Range, Array<Integer>, Integer, nil] the breakpoint
    #   spec. Defaults to {DynamicImage.default_breakpoints}.
    # @param step [Numeric, nil] the ratio between two candidates
    #   in a range. Defaults to {DynamicImage.breakpoint_step}.
    # @raise [ArgumentError] if the step or range would never terminate
    def initialize(spec = nil, step: nil)
      @spec = spec.nil? ? DynamicImage.default_breakpoints : spec
      @step = (step || DynamicImage.breakpoint_step).to_f
      validate!
    end

    # Returns the candidate widths, smallest first.
    #
    # The largest candidate is always the available width, whether or not it falls
    # inside the range. An image narrower than the range gets a single candidate.
    #
    # @param available [Integer] the widest the image can be rendered
    #   at, as returned by {DynamicImage::ImageSizing#available_width}
    # @return [Array<Integer>] the widths
    # @raise [ArgumentError] if the spec isn't understood
    def widths(available)
      available = available.to_i
      return [] unless available.positive?

      case spec
      when Range then stepped(available)
      when Array then fixed(available)
      when Integer then [spec]
      else unknown_spec!
      end
    end

    private

    def fixed(available)
      widths = spec.map(&:to_i).select { _1 <= available }.uniq.sort
      widths.any? ? widths : [available]
    end

    def stepped(available)
      top = [available, spec.end || available].min.to_f
      rest = Enumerator.produce(top / step) { _1 / step }
                       .take_while { _1 >= spec.begin }

      [top, *rest].map { snap(_1) }.reverse.uniq
    end

    def snap(width)
      [(width / SNAP).floor * SNAP, 1].max
    end

    def unknown_spec!
      raise ArgumentError,
            "breakpoints must be a Range, Array or Integer, " \
            "got #{spec.class}"
    end

    def validate!
      raise ArgumentError, "step must be greater than 1" unless step > 1
      return unless spec.is_a?(Range) && spec.begin.nil?

      raise ArgumentError, "breakpoints range must have a beginning"
    end
  end
end
