# frozen_string_literal: true

module DynamicImage
  class ImageReader
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
        File.binread(@data.to_s, 8)
      else
        data_stream = stream
        header = data_stream.read(8)
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
