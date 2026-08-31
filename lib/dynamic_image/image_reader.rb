# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Image Reader
  #
  # Reads an image into vips, identifying the format from the file
  # header rather than from anything the client claims. Accepts a
  # Pathname, an IO object or a binary string.
  #
  # Animated formats are opened with all their frames.
  class ImageReader
    # Number of bytes needed to identify a format.
    HEADER_BYTES = 32

    # @param data [Pathname, IO, String] the image
    def initialize(data)
      @data = data
    end

    # The format of the image, sniffed from its header.
    #
    # @return [DynamicImage::Format, nil] the format, if recognized
    def format
      DynamicImage::Format.sniff(file_header)
    end

    # Reads the image.
    #
    # @return [Vips::Image] the image
    # @raise [DynamicImage::Errors::InvalidHeader] if the data isn't in
    #   a recognized format
    def read
      raise DynamicImage::Errors::InvalidHeader unless valid_header?

      if @data.is_a?(String)
        Vips::Image.new_from_buffer(@data, option_string)
      else
        path = @data.is_a?(Pathname) ? @data.to_s : @data.path
        Vips::Image.new_from_file(path + option_string, access: :random)
      end
    end

    # Returns true if the header belongs to a supported format.
    #
    # @return [Boolean]
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
