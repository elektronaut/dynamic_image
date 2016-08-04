require "spec_helper"

describe ImagesController, type: :controller do
  def digest(str)
    DynamicImage.digest_verifier.generate(str)
  end

  def digested(action, options = {})
    key = ([action] + [:id, :size]
      .select { |k| options.key?(k) }.map { |k| options[k] }).join("-")
    { digest: digest(key) }.merge(options)
  end

  let(:file_path) { "../../support/fixtures/image.png" }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.create(file: uploaded_file) }

  let(:metadata) { DynamicImage::Metadata.new(response.body) }

  describe "signed params verification" do
    context "with an invalid digest" do
      it "should raise an error" do
        expect do
          get(:show,
              params: {
                id: 1,
                size: "100x101",
                digest: digest("show-1-100x100"),
                format: :png
              })
        end.to raise_error(DynamicImage::Errors::InvalidSignature)
      end
    end

    context "with a missing parameter" do
      it "should raise an error" do
        expect do
          get(:show,
              params: { id: 1, digest: digest("show-1-100x100"), format: :png })
        end.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "GET show" do
    context "with a nonexistant record" do
      it "should raise an error" do
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

      it "should respond with 304 not modified" do
        expect(response).to have_http_status(304)
      end
    end

    context "with ETag header" do
      before do
        request.env["HTTP_IF_MODIFIED_SINCE"] = (
          Time.zone.now + 10.minutes
        ).httpdate
        get(:show,
            params: digested(:show,
                             id: image.id,
                             size: "100x100",
                             format: :png))
      end

      it "should respond with 304 not modified" do
        expect(response).to have_http_status(304)
      end
    end

    context "with an existing record" do
      before do
        get :show, params: digested(
          :show, id: image.id, size: "100x100", format: :png
        ).merge(id: image.to_param)
      end

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "should set the caching headers" do
        expect(response.headers["Cache-Control"]).to(
          eq("max-age=2592000, public")
        )
        expect(response.headers["Last-Modified"]).to be_a(String)
        expect(response.headers["ETag"]).to be_a(String)
      end
    end

    context "as an image format" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :png)
      end

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should set the content disposition" do
        expect(response.headers["Content-Disposition"]).to eq("inline")
      end

      it "should resize the image" do
        expect(metadata.dimensions).to eq(Vector2d.new(100, 100))
      end
    end

    context "as GIF format" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :gif)
      end

      it "should set the content type" do
        expect(response.content_type).to eq("image/gif")
      end

      it "should return a GIF image" do
        expect(metadata.format).to eq("GIF")
      end
    end

    context "as JPEG format" do
      before do
        get(
          :show,
          params: digested(:show, id: image.id, size: "100x100", format: :jpeg)
        )
      end

      it "should set the content type" do
        expect(response.content_type).to eq("image/jpeg")
      end

      it "should return a JPEG image" do
        expect(metadata.format).to eq("JPEG")
      end
    end

    context "as JPG format" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :jpg)
      end

      it "should set the content type" do
        expect(response.content_type).to eq("image/jpeg")
      end

      it "should return a JPEG image" do
        expect(metadata.format).to eq("JPEG")
      end
    end

    context "as PNG format" do
      before do
        get :show,
            params: digested(:show, id: image.id, size: "100x100", format: :png)
      end

      it "should set the content type" do
        expect(response.content_type).to eq("image/png")
      end

      it "should return a PNG image" do
        expect(metadata.format).to eq("PNG")
      end
    end

    context "as TIFF format" do
      before do
        get(
          :show,
          params: digested(:show, id: image.id, size: "100x100", format: :tiff)
        )
      end

      it "should set the content type" do
        expect(response.content_type).to eq("image/tiff")
      end

      it "should return a TIFF image" do
        expect(metadata.format).to eq("TIFF")
      end
    end
  end

  describe "GET uncropped" do
    context "with a nonexistant record" do
      it "should raise an error" do
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

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "should set the caching headers" do
        expect(response.headers["Cache-Control"]).to(
          eq("max-age=2592000, public")
        )
        expect(response.headers["Last-Modified"]).to be_a(String)
        expect(response.headers["ETag"]).to be_a(String)
      end

      it "should return a PNG image" do
        expect(metadata.format).to eq("PNG")
        expect(metadata.dimensions).to eq(Vector2d.new(100, 100))
      end
    end
  end

  describe "GET original" do
    context "with a nonexistant record" do
      it "should raise an error" do
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

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "should set the caching headers" do
        expect(response.headers["Cache-Control"]).to(
          eq("max-age=2592000, public")
        )
        expect(response.headers["Last-Modified"]).to be_a(String)
        expect(response.headers["ETag"]).to be_a(String)
      end

      it "should return the original PNG image" do
        expect(metadata.format).to eq("PNG")
        expect(metadata.dimensions).to eq(Vector2d.new(320, 200))
      end
    end
  end
end
