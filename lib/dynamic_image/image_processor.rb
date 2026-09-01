# frozen_string_literal: true

require "dynamic_image/image_processor/colors"
require "dynamic_image/image_processor/frames"
require "dynamic_image/image_processor/transform"

module DynamicImage
  # = ImageProcessor
  #
  # The image processing pipeline.
  #
  # Every operation returns a new processor instead of modifying the one it was called on, so operations chain.
  # Images are converted to sRGB and EXIF rotation is applied when the processor is built, so the pipeline always
  # starts from a normalized image.
  #
  # @see DynamicImage::ImageProcessor::Colors
  # @see DynamicImage::ImageProcessor::Frames
  # @see DynamicImage::ImageProcessor::Transform
  #
  # @example
  #   DynamicImage::ImageProcessor
  #     .new(file)
  #     .crop(crop_start, crop_size)
  #     .resize(size)
  #     .convert(:jpeg)
  #     .read
  class ImageProcessor
    include DynamicImage::ImageProcessor::Colors
    include DynamicImage::ImageProcessor::Frames
    include DynamicImage::ImageProcessor::Transform

    # @!attribute [r] image
    #   @return [Vips::Image]
    # @!attribute [r] target_format
    #   @return [DynamicImage::Format] the format it will be written in
    attr_reader :image, :target_format

    # @param image [Vips::Image, Pathname, IO, String] the image, either an already loaded vips image or something
    #   {DynamicImage::ImageReader} can read
    # @param target_format [DynamicImage::Format, nil] the format to write in, defaulting to the format the image was
    #   read from
    def initialize(image, target_format: nil)
      if image.is_a?(Vips::Image)
        @image = image
        @target_format = target_format
      else
        reader = DynamicImage::ImageReader.new(image)
        @image = screen_profile(reader.read.autorot)
        @target_format = reader.format
      end
    end

    # Convert the image to a different format.
    #
    # Converting a multi-frame image to a format that doesn't support animation keeps the first frame.
    #
    # @param new_format [DynamicImage::Format, Symbol, String] the format to convert to
    # @return [DynamicImage::ImageProcessor] a new processor
    def convert(new_format)
      new_format = DynamicImage::Format.find(new_format) unless new_format.is_a?(DynamicImage::Format)

      if frame_count > 1 && !new_format.animated?
        self.class.new(extract_frame(0), target_format: new_format)
      else
        self.class.new(image, target_format: new_format)
      end
    end

    # Returns the image data as a binary string.
    #
    # @return [String] the encoded image
    def read
      image.write_to_buffer(target_format.extension,
                            **target_format.save_options)
    end

    # Returns the image size as a Vector2d. For multi-frame images this is the size of a single frame, not of the
    # filmstrip vips holds them in.
    #
    # @return [Vector2d]
    def size
      Vector2d.new(
        image.get("width"),
        image.get(
          image.get_fields.include?("page-height") ? "page-height" : "height"
        )
      )
    end

    # Write the image to a file.
    #
    # @param path [String] the path to write to
    # @return [void]
    def write(path)
      image.write_to_file(path, **target_format.save_options)
    end

    private

    def apply(new_image)
      self.class.new(new_image, target_format:)
    end
  end
end
