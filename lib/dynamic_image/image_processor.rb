# frozen_string_literal: true

# DynamicImage::ImageProcessor
#   .new(data)
#   .screen_profile
#   .crop(crop_start, crop_size)
#   .resize(size)
#   .convert(DynamicImage::Format.find("JPEG"))
#   .read

module DynamicImage
  class ImageProcessor
    attr_reader :image, :intent

    def initialize(image, intent: nil)
      if image.is_a?(Vips::Image)
        @image = image
        @intent = intent
      else
        reader = DynamicImage::ImageReader.new(image)
        @image = reader.read.autorot
        @intent = reader.format
      end
    end

    def convert(new_format)
      self.class.new(image, intent: new_format)
    end

    def crop(crop_start, crop_size)
      return self if crop_start == Vector2d(0, 0) && crop_size == size

      unless valid_crop?(crop_start, crop_size)
        raise DynamicImage::Errors::InvalidTransformation,
              "crop size is out of bounds"
      end

      each_frame do |frame|
        frame.crop(crop_start.x, crop_start.y, crop_size.x, crop_size.y)
      end
    end

    def frame(index)
      apply extract_frame(index)
    end

    def frame_count
      return 1 unless image.get_fields.include?("page-height")

      image.get("height") / image.get("page-height")
    end

    def read
      tempfile = Tempfile.new(["dynamic_image", intent.extension],
                              binmode: true)
      tempfile.close
      write(tempfile.path)
      tempfile.open
      tempfile.read
    ensure
      tempfile.close
    end

    def resize(new_size)
      new_size = Vector2d(new_size)
      apply image.thumbnail_image(new_size.x.to_i,
                                  height: new_size.y.to_i,
                                  crop: :none,
                                  size: :both)
    end

    def rotate(degrees)
      degrees = degrees.to_i % 360

      return self if degrees.zero?

      if (degrees % 90).nonzero?
        raise DynamicImage::Errors::InvalidTransformation,
              "angle must be a multiple of 90 degrees"
      end

      each_frame do |frame|
        frame.rotate(degrees)
      end
    end

    def screen_profile
      return self if !icc_profile? && %i[rgb b-w].include?(image.interpretation)

      target_space = image.interpretation == :"b-w" ? "b-w" : "srgb"
      apply icc_transform_srgb(image).colourspace(target_space)
    end

    def size
      height = if image.get_fields.include?("page-height")
                 image.get("page-height")
               else
                 image.get("height")
               end
      Vector2d.new(image.get("width"), height)
    end

    def write(path)
      image.write_to_file(path, **intent.save_options)
    end

    private

    def apply(new_image)
      self.class.new(new_image, intent: intent)
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

      image.icc_transform("srgb")
    end

    def replace_frames(new_frames)
      new_size = Vector2d(new_frames.first.size)
      image.insert(
        Vips::Image.arrayjoin(new_frames, across: 1),
        0, 0, expand: true
      ).extract_area(
        0, 0, new_size.x, new_size.y * frame_count
      ).mutate { |img| img.set!("page-height", new_size.y) }
    end

    def valid_crop?(crop_start, crop_size)
      bounds = crop_start + crop_size
      bounds.x <= size.x && bounds.y <= size.y
    end
  end
end
