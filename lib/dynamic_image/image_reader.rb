# frozen_string_literal: true

module DynamicImage
  class ImageReader
    HEADER_BYTES = 12

    def initialize(data)
      @data = data
    end

    def format
      DynamicImage::Format.sniff(file_header)
    end

    def read
      raise DynamicImage::Errors::InvalidHeader unless valid_header?

      if @data.is_a?(String)
        Vips::Image.new_from_buffer(@data, option_string)
      else
        path = @data.is_a?(Pathname) ? @data.to_s : @data.path
        Vips::Image.new_from_file(path + option_string, access: :random)
      end
    end

    def valid_header?
      format ? true : false
    end

    private

    def file_header
      @file_header ||= read_file_header
    end

    def option_string
      format.animated? ? "[n=-1]" : ""
    end

    def read_file_header
      if @data.is_a?(Pathname)
        File.binread(@data.to_s, HEADER_BYTES)
      else
        data_stream = stream
        header = data_stream.read(HEADER_BYTES)
        data_stream.seek(0 - header.length, IO::SEEK_CUR) if header
        header
      end
    end

    def stream
      return StringIO.new(@data, "rb") if @data.is_a?(String)

      @data
    end
  end
end
