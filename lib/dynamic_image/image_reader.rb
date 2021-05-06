# frozen_string_literal: true

module DynamicImage
  class ImageReader
    def initialize(data)
      @data = data
    end

    def exif
      raise DynamicImage::Errors::InvalidHeader unless valid_header?

      MiniExiftool.new(stream)
    end

    def format
      DynamicImage::Format.sniff(file_header)
    end

    def read
      raise DynamicImage::Errors::InvalidHeader unless valid_header?

      Vips::Image.new_from_file(file.path, access: :sequential)
    end

    def valid_header?
      format ? true : false
    end

    private

    def file
      return tempfile if @data.is_a?(String)

      @data
    end

    def tempfile
      tempfile = Tempfile.new(["dynamic_image", format.extension],
                              binmode: true)
      tempfile.write(@data)
      tempfile.open
      tempfile
    end

    def file_header
      @file_header ||= read_file_header
    end

    def read_file_header
      data_stream = stream
      header = data_stream.read(8)
      data_stream.seek((0 - header.length), IO::SEEK_CUR) if header
      header
    end

    def stream
      return StringIO.new(@data, "rb") if @data.is_a?(String)

      @data
    end
  end
end
