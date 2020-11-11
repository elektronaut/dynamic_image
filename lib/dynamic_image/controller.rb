# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Controller
  #
  # Generating images is rather expensive, so all requests must be
  # signed with a HMAC digest in order to avoid denial of service attacks.
  # The methods in +DynamicImage::Helper+ handles this transparently.
  # As a bonus, this also prevents unauthorized URL enumeration.
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :verify_signed_params
      before_action :find_record
      after_action :cache_expiration_header
      helper_method :requested_size
    end

    # Renders the image.
    def show
      render_image(format: requested_format)
    end

    # Same as +show+, but renders the image without any pre-cropping applied.
    def uncropped
      render_image(format: requested_format, uncropped: true)
    end

    # Renders the original image data, without any processing.
    def original
      render_raw_image
    end

    def download
      render_raw_image(disposition: "attachment", filename: @record.filename)
    end

    # Returns the requested size as a vector.
    def requested_size
      Vector2d.parse(params[:size])
    end

    private

    def cache_expiration_header
      expires_in 30.days, public: true if response.status == 200
    end

    def find_record
      @record = model.find(params[:id])
    end

    def process_later?(processed_image, size)
      return false unless DynamicImage.process_later_limit

      image_size = processed_image.record.size.x * processed_image.record.size.y
      image_size > DynamicImage.process_later_limit &&
        !processed_image.find_variant(size)
    end

    def render_image(options)
      return unless stale?(@record)

      respond_to do |format|
        format.html do
          render(file: File.join(File.dirname(__FILE__), "templates/show"),
                 layout: false, locals: { options: options })
        end
        format.any(:gif, :jpeg, :jpg, :png, :tiff, :webp) do
          send_image(@record, options)
        end
      end
    end

    def render_raw_image(disposition: "inline", filename: nil)
      return unless stale?(@record)

      respond_to do |format|
        format.any(:gif, :jpeg, :jpg, :png, :tiff, :webp) do
          send_data(@record.data,
                    filename: filename,
                    content_type: @record.content_type,
                    disposition: disposition)
        end
      end
    end

    def requested_format
      params[:format]
    end

    def send_image(image, options)
      processed_image = DynamicImage::ProcessedImage.new(image, options)
      if process_later?(processed_image, requested_size)
        DynamicImage::Jobs::CreateVariant
          .perform_later(image, options, requested_size.to_s)
        head 503, retry_after: 10
      else
        send_data(processed_image.cropped_and_resized(requested_size),
                  content_type: processed_image.content_type,
                  disposition: "inline")
      end
    end

    def verify_signed_params
      key = %i[action id size].map do |k|
        k == :id ? params.require(k).to_i : params.require(k)
      end.join("-")
      DynamicImage.digest_verifier.verify(key, params[:digest])
    rescue ActionController::ParameterMissing => e
      raise DynamicImage::Errors::ParameterMissing, e.message
    end
  end
end
