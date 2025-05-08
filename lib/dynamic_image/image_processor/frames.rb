# frozen_string_literal: true

module DynamicImage
  class ImageProcessor
    module Frames
      # Extracts a single frame from a multi-frame image.
      def frame(index)
        apply extract_frame(index)
      end

      # Returns the number of frames.
      def frame_count
        image.get("height") / size.y
      end

      private

      def each_frame(&block)
        return apply(block.call(image)) unless frame_count > 1

        apply(replace_frames(frames.map { |f| block.call(f) }))
      end

      def extract_frame(index)
        image.extract_area(0, index * size.y, size.x, size.y)
      end

      def frames
        frame_count.times.map { |i| extract_frame(i) }
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
    end
  end
end
