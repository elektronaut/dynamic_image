# encoding: utf-8

module DynamicImage
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :find_record, only: [:show]
      respond_to :gif, :jpeg, :png, :tiff
    end

    def show
      @size = Vector2d.parse(params[:size])
      respond_with(@record) do |format|
        format.any(:gif, :jpeg, :png, :tiff) do
          send_data(
            processed_image.cropped_and_resized(@size),
            content_type: processed_image.content_type,
            disposition:  'inline'
          )
        end
      end
    end

    private

    def find_record
      @record = model.find(params[:id])
    end

    def processed_image
      @processed_image ||= DynamicImage::ProcessedImage.new(@record, requested_format)
    end

    def requested_format
      params[:format]
    end
  end
end