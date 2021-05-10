# frozen_string_literal: true

require "dynamic_image/image_processor/colors"
require "dynamic_image/image_processor/frames"
require "dynamic_image/image_processor/transform"

module DynamicImage
  # = ImageProcessor
  #
  # This is the image processing pipeline.
  #
  # ==== Example:
  #
  #   DynamicImage::ImageProcessor
  #     .new(file)
  #     .screen_profile
  #     .crop(crop_start, crop_size)
  #     .resize(size)
  #     .convert(:jpeg)
  #     .read
  class ImageProcessor
    include DynamicImage::ImageProcessor::Colors
    include DynamicImage::ImageProcessor::Frames
    include DynamicImage::ImageProcessor::Transform

    attr_reader :image, :target_format

    def initialize(image, target_format: nil)
      if image.is_a?(Vips::Image)
        @image = image
        @target_format = target_format
      else
        reader = DynamicImage::ImageReader.new(image)
        @image = reader.read.autorot
        @target_format = reader.format
      end
    end

    # Convert the image to a different format.
    def convert(new_format)
      unless new_format.is_a?(DynamicImage::Format)
        new_format = DynamicImage::Format.find(new_format)
      end
      if frame_count > 1 && !new_format.animated?
        self.class.new(extract_frame(0), target_format: new_format)
      else
        self.class.new(image, target_format: new_format)
      end
    end

    # Returns the image data as a binary string.
    def read
      tempfile = Tempfile.new(["dynamic_image", target_format.extension],
                              binmode: true)
      tempfile.close
      write(tempfile.path)
      tempfile.open
      tempfile.read
    ensure
      tempfile.close
    end

    # Returns the image size as a Vector2d.
    def size
      Vector2d.new(
        image.get("width"),
        image.get(
          image.get_fields.include?("page-height") ? "page-height" : "height"
        )
      )
    end

    # Write the image to a file.
    def write(path)
      image.write_to_file(path, **target_format.save_options)
    end

    private

    def apply(new_image)
      self.class.new(new_image, target_format: target_format)
    end

    def blank_image
      image.draw_rect([0.0, 0.0, 0.0, 0.0],
                      0, 0, image.get("width"), image.get("height"),
                      fill: true)
    end
  end
end
