# frozen_string_literal: true

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

    # Crops the image
    def crop(crop_size, crop_start)
      return self if crop_start == Vector2d(0, 0) && crop_size == size

      unless valid_crop?(crop_start, crop_size)
        raise DynamicImage::Errors::InvalidTransformation,
              "crop size is out of bounds"
      end

      each_frame do |frame|
        frame.crop(crop_start.x, crop_start.y, crop_size.x, crop_size.y)
      end
    end

    # Extracts a single frame from a multi-frame image.
    def frame(index)
      apply extract_frame(index)
    end

    # Returns the number of frames.
    def frame_count
      return 1 unless image.get_fields.include?("page-height")

      image.get("height") / image.get("page-height")
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

    # Resize the image to a new size.
    def resize(new_size)
      new_size = Vector2d(new_size)
      apply image.thumbnail_image(new_size.x.to_i,
                                  height: new_size.y.to_i,
                                  crop: :none,
                                  size: :both)
    end

    # Rotates the image. The rotation must be a multiple of 90 degrees.
    def rotate(degrees)
      degrees = degrees.to_i % 360
      return self if degrees.zero?

      if (degrees % 90).nonzero?
        raise DynamicImage::Errors::InvalidTransformation,
              "angle must be a multiple of 90 degrees"
      end

      each_frame { |frame| frame.rotate(degrees) }
    end

    # Performs the necessary profile conversions on the image. All images are
    # converted to the sRGB colorspace using either the embedded profile, or the
    # built-in generic profile. Grayscale images are converted back to
    # grayscale after processing.
    def screen_profile
      return self if !icc_profile? && %i[rgb b-w].include?(image.interpretation)

      target_space = image.interpretation == :"b-w" ? "b-w" : "srgb"
      apply icc_transform_srgb(image).colourspace(target_space)
    end

    # Returns the image size as a Vector2d.
    def size
      height = if image.get_fields.include?("page-height")
                 image.get("page-height")
               else
                 image.get("height")
               end
      Vector2d.new(image.get("width"), height)
    end

    # Write the image to a file.
    def write(path)
      image.write_to_file(path, **target_format.save_options)
    end

    private

    def apply(new_image)
      self.class.new(new_image, target_format: target_format)
    end

    def each_frame(&block)
      return apply(block.call(image)) unless frame_count > 1

      apply(replace_frames(frames.map { |f| block.call(f) }))
    end

    def extract_frame(index)
      image.extract_area(0, (index * size.y), size.x, size.y)
    end

    def frames
      frame_count.times.map { |i| extract_frame(i) }
    end

    def icc_profile?
      image.get_fields.include?("icc-profile-data")
    end

    def icc_transform_srgb(image)
      return image unless icc_profile?

      image.icc_transform("srgb", embedded: true, intent: :perceptual)
    end

    def blank_image
      image.draw_rect([0.0, 0.0, 0.0, 0.0],
                      0, 0, image.get("width"), image.get("height"),
                      fill: true)
    end

    def replace_frames(new_frames)
      new_size = Vector2d(new_frames.first.size)
      new_image = blank_image.insert(
        Vips::Image.arrayjoin(new_frames, across: 1),
        0, 0, expand: true
      ).extract_area(0, 0, new_size.x, new_size.y * frame_count).copy
      new_image.set("page-height", new_size.y)
      new_image
    end

    def valid_crop?(crop_start, crop_size)
      bounds = crop_start + crop_size
      bounds.x <= size.x && bounds.y <= size.y
    end
  end
end
