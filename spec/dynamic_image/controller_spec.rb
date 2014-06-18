require 'spec_helper'

describe ImagesController, type: :controller do
  storage_root = Rails.root.join('tmp', 'spec')

  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.create(file: uploaded_file) }

  let(:metadata) { DynamicImage::Metadata.new(response.body) }

  before(:all) do
    Shrouded::Storage.layers << Shrouded::Layer.new(Fog::Storage.new({provider: 'Local', local_root: storage_root}))
  end

  after do
    FileUtils.rm_rf(storage_root) if File.exists?(storage_root)
  end

  after(:all) do
    Shrouded::Storage.layers.clear!
  end

  describe "GET show" do
    context "with a nonexistant record" do
      it "should raise an error" do
        expect { get :show, id: 1 }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with If-Modified-Since header" do
      before do
        request.env['HTTP_IF_MODIFIED_SINCE'] = (Time.now + 10.minutes).httpdate
        get :show, id: image.id, size: '100x100', format: :png
      end

      it "should respond with 304 not modified" do
        expect(response).to have_http_status(304)
      end
    end

    context "with ETag header" do
      before do
        request.env['HTTP_IF_MODIFIED_SINCE'] = (Time.now + 10.minutes).httpdate
        get :show, id: image.id, size: '100x100', format: :png
      end

      it "should respond with 304 not modified" do
        expect(response).to have_http_status(304)
      end
    end

    context "with an existing record" do
      before { get :show, id: image.id, size: '100x100', format: :png }

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "should set the caching headers" do
        expect(response.headers['Cache-Control']).to eq("max-age=2592000, public")
        expect(response.headers['Last-Modified']).to be_a(String)
        expect(response.headers['ETag']).to be_a(String)
      end
    end

    context "as an image format" do
      before { get :show, id: image.id, size: '100x100', format: :png }

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
      before { get :show, id: image.id, size: '100x100', format: :gif }

      it "should set the content type" do
        expect(response.content_type).to eq("image/gif")
      end

      it 'should return a GIF image' do
        expect(metadata.format).to eq('GIF')
      end
    end

    context "as JPEG format" do
      before { get :show, id: image.id, size: '100x100', format: :jpeg }

      it "should set the content type" do
        expect(response.content_type).to eq("image/jpeg")
      end

      it 'should return a JPEG image' do
        expect(metadata.format).to eq('JPEG')
      end
    end

    context "as JPG format" do
      before { get :show, id: image.id, size: '100x100', format: :jpg }

      it "should set the content type" do
        expect(response.content_type).to eq("image/jpeg")
      end

      it 'should return a JPEG image' do
        expect(metadata.format).to eq('JPEG')
      end
    end

    context "as PNG format" do
      before { get :show, id: image.id, size: '100x100', format: :png }

      it "should set the content type" do
        expect(response.content_type).to eq("image/png")
      end

      it 'should return a PNG image' do
        expect(metadata.format).to eq('PNG')
      end
    end

    context "as TIFF format" do
      before { get :show, id: image.id, size: '100x100', format: :tiff }

      it "should set the content type" do
        expect(response.content_type).to eq("image/tiff")
      end

      it 'should return a TIFF image' do
        expect(metadata.format).to eq('TIFF')
      end
    end
  end

  describe "GET uncropped" do
    context "with a nonexistant record" do
      it "should raise an error" do
        expect { get :uncropped, id: 1 }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an existing record" do
      before { get :uncropped, id: image.id, size: '100x100', format: :png }

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "should set the caching headers" do
        expect(response.headers['Cache-Control']).to eq("max-age=2592000, public")
        expect(response.headers['Last-Modified']).to be_a(String)
        expect(response.headers['ETag']).to be_a(String)
      end

      it 'should return a PNG image' do
        expect(metadata.format).to eq('PNG')
        expect(metadata.dimensions).to eq(Vector2d.new(100, 100))
      end
    end
  end

  describe "GET original" do
    context "with a nonexistant record" do
      it "should raise an error" do
        expect { get :original, id: 1 }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an existing record" do
      before { get :original, id: image.id, format: :png }

      it "should respond with success" do
        expect(response).to have_http_status(:success)
      end

      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end

      it "should set the caching headers" do
        expect(response.headers['Cache-Control']).to eq("max-age=2592000, public")
        expect(response.headers['Last-Modified']).to be_a(String)
        expect(response.headers['ETag']).to be_a(String)
      end

      it 'should return the original PNG image' do
        expect(metadata.format).to eq('PNG')
        expect(metadata.dimensions).to eq(Vector2d.new(320, 200))
      end
    end
  end
end