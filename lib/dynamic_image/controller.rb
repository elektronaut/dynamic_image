# encoding: utf-8

module DynamicImage
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :verify_signed_params
      before_action :find_record
      after_action :cache_expiration_header
      respond_to :gif, :jpeg, :png, :tiff
    end

    def show
      render_image(format: requested_format)
    end

    def uncropped
      render_image(format: requested_format, uncropped: true)
    end

    def original
      if stale?(@record)
        respond_with(@record) do |format|
          format.any(:gif, :jpeg, :png, :tiff) do
            send_data(
              @record.data,
              content_type: @record.content_type,
              disposition:  'inline'
            )
          end
        end
      end
    end

    private

    def cache_expiration_header
      expires_in 30.days, public: true
    end

    def find_record
      @record = model.find(params[:id])
    end

    def render_image(options)
      processed_image = DynamicImage::ProcessedImage.new(@record, options)
      if stale?(@record)
        respond_with(@record) do |format|
          format.any(:gif, :jpeg, :png, :tiff) do
            send_data(
              processed_image.cropped_and_resized(requested_size),
              content_type: processed_image.content_type,
              disposition:  'inline'
            )
          end
        end
      end
    end

    def requested_format
      params[:format]
    end

    def requested_size
      Vector2d.parse(params[:size])
    end

    def signed_params
      case request[:action]
      when "show", "uncropped"
        [:action, :id, :size]
      else
        [:action, :id]
      end
    end

    def verify_signed_params
      key = signed_params.map { |k| params.require(k) }.join('-')
      DynamicImage.digest_verifier.verify(key, params[:digest])
    end
  end
end