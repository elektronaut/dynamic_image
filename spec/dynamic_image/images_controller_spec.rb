# frozen_string_literal: true

require "spec_helper"

describe ImagesController, type: :controller do
  def digest(str)
    DynamicImage.digest_verifier.generate(str)
  end

  def digested(action, options = {})
    key = ([action] + %i[id size]
      .select { |k| options.key?(k) }.map { |k| options[k] }).join("-")
    { digest: digest(key) }.merge(options)
  end

  let(:image) do
    Image.create(
      file: Rack::Test::UploadedFile.new(
        File.open(File.expand_path("../support/fixtures/image.png",
                                   __dir__)),
        "image/png"
      )
    )
  end
  let(:metadata) { DynamicImage::Metadata.new(response.body) }

  describe "signed params verification" do
    context "with an invalid digest" do
      let(:params) do
        { id: 1,
          size: "100x101",
          digest: digest("show-1-100x100"),
          format: :png }
      end

      it "raises an error" do
        expect { get(:show, params: params) }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end

    context "with a missing parameter" do
      it "raises an error" do
        expect do
          get(:show,
              params: { id: 1, digest: digest("show-1-100x100"), format: :png })
        end.to raise_error(DynamicImage::Errors::ParameterMissing)
      end
    end
  end

  describe "GET show" do
    context "with a nonexistant record" do
      it "raises an error" do
        expect do
          get :show, params: digested(:show, id: 1, size: "100x100")
        end.to(
          raise_error(ActiveRecord::RecordNotFound)
        )
      end
    end

    context "with If-Modified-Since header" do
      before do
        request.env["HTTP_IF_MODIFIED_SINCE"] = (
          Time.zone.now + 10.minutes
        ).httpdate
        get(:show, params: digested(:show,
                                    id: image.id,
                                    size: "100x100",
                                    format: :png))
      end

      it "responds with 304 not modified" do
        expect(response).to have_http_status(:not_modified)
      end
    end

    context "with an existing record" do
      before do
        get :show, params: digested(
          :show, id: image.id, size: "100x100", format: :png
        ).merge(id: image.to_param)
      end

      it "responds with success" do
        expect(response.successful?).to eq(true)
      end

      it "finds the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "sets the Cache-Control header" do
        expect(response.headers["Cache-Control"]).to(
          eq("max-age=2592000, public")
        )
      end

      it "sets the Last-Modified header" do
        expect(response.headers["Last-Modified"]).to be_a(String)
      end

      it "sets the ETag header" do
        expect(response.headers["ETag"]).to be_a(String)
      end
    end

    context "with an image format" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :png)
      end

      it "responds with success" do
        expect(response.successful?).to eq(true)
      end

      it "sets the content disposition" do
        expect(response.headers["Content-Disposition"]).to eq("inline")
      end

      it "resizes the image" do
        expect(metadata.dimensions).to eq(Vector2d.new(100, 100))
      end
    end

    context "when format is GIF" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :gif)
      end

      it "sets the content type" do
        expect(response.media_type).to eq("image/gif")
      end

      it "returns a GIF image" do
        expect(metadata.format).to eq("GIF")
      end
    end

    context "when format is JPEG" do
      before do
        get(
          :show,
          params: digested(:show, id: image.id, size: "100x100", format: :jpeg)
        )
      end

      it "sets the content type" do
        expect(response.media_type).to eq("image/jpeg")
      end

      it "returns a JPEG image" do
        expect(metadata.format).to eq("JPEG")
      end
    end

    context "when format is JPG" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :jpg)
      end

      it "sets the content type" do
        expect(response.media_type).to eq("image/jpeg")
      end

      it "returns a JPEG image" do
        expect(metadata.format).to eq("JPEG")
      end
    end

    context "when format is PNG" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :png)
      end

      it "sets the content type" do
        expect(response.media_type).to eq("image/png")
      end

      it "returns a PNG image" do
        expect(metadata.format).to eq("PNG")
      end
    end

    context "when format is TIFF" do
      before do
        get(
          :show,
          params: digested(:show, id: image.id, size: "100x100", format: :tiff)
        )
      end

      it "sets the content type" do
        expect(response.media_type).to eq("image/tiff")
      end

      it "returns a TIFF image" do
        expect(metadata.format).to eq("TIFF")
      end
    end

    context "when format is WEBP" do
      before do
        get(
          :show,
          params: digested(:show, id: image.id, size: "100x100", format: :webp)
        )
      end

      it "sets the content type" do
        expect(response.media_type).to eq("image/webp")
      end

      xit "returns a WEBP image" do
        expect(metadata.format).to eq("WEBP")
      end
    end
  end

  describe "GET uncropped" do
    context "with a nonexistant record" do
      it "raises an error" do
        expect do
          get :uncropped, params: digested(:uncropped, id: 1, size: "100x100")
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an existing record" do
      before do
        get(:uncropped,
            params: digested(:uncropped,
                             id: image.id,
                             size: "100x100",
                             format: :png))
      end

      it "responds with success" do
        expect(response.successful?).to eq(true)
      end

      it "finds the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "sets the Cache-Control header" do
        expect(response.headers["Cache-Control"]).to(
          eq("max-age=2592000, public")
        )
      end

      it "sets the Last-Modified header" do
        expect(response.headers["Last-Modified"]).to be_a(String)
      end

      it "sets the ETag header" do
        expect(response.headers["ETag"]).to be_a(String)
      end

      it "returns a PNG image" do
        expect(metadata.format).to eq("PNG")
      end

      it "returns the requested size" do
        expect(metadata.dimensions).to eq(Vector2d.new(100, 100))
      end
    end
  end

  describe "GET original" do
    context "with a nonexistant record" do
      it "raises an error" do
        expect do
          get :original, params: digested(:original, id: 1, size: "320x200")
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an existing record" do
      before do
        get(:original,
            params: digested(:original,
                             id: image.id,
                             size: "320x200",
                             format: :png))
      end

      it "responds with success" do
        expect(response.successful?).to eq(true)
      end

      it "finds the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "sets the Cache-Control header" do
        expect(response.headers["Cache-Control"]).to(
          eq("max-age=2592000, public")
        )
      end

      it "sets the Last-Modified header" do
        expect(response.headers["Last-Modified"]).to be_a(String)
      end

      it "sets the ETag header" do
        expect(response.headers["ETag"]).to be_a(String)
      end

      it "returns the correct format" do
        expect(metadata.format).to eq("PNG")
      end

      it "returns the correct size" do
        expect(metadata.dimensions).to eq(Vector2d.new(320, 200))
      end

      it "sets the Content-Disposition header" do
        expect(response.headers["Content-Disposition"]).to eq("inline")
      end
    end
  end

  describe "GET download" do
    before do
      get(:download,
          params: digested(:download,
                           id: image.id,
                           size: "320x200",
                           format: :png))
    end

    it "responds with success" do
      expect(response.successful?).to eq(true)
    end

    it "finds the record" do
      expect(assigns(:record)).to eq(image)
    end

    it "sets the Cache-Control header" do
      expect(response.headers["Cache-Control"]).to(
        eq("max-age=2592000, public")
      )
    end

    it "sets the Last-Modified header" do
      expect(response.headers["Last-Modified"]).to be_a(String)
    end

    it "sets the ETag header" do
      expect(response.headers["ETag"]).to be_a(String)
    end

    it "returns the correct format" do
      expect(metadata.format).to eq("PNG")
    end

    it "returns the correct size" do
      expect(metadata.dimensions).to eq(Vector2d.new(320, 200))
    end

    it "sets the Content-Disposition header" do
      expect(response.headers["Content-Disposition"]).to eq(
        'attachment; filename="image.png"; filename*=UTF-8\'\'image.png'
      )
    end
  end
end
