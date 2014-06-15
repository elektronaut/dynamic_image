require 'spec_helper'

describe DynamicImage::Model do
  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.new }

  describe "metadata parsing" do
    before { image.valid? }
    let(:image) { Image.new(file: uploaded_file) }

    it "should set the color space" do
      expect(image.colorspace).to eq("rgb")
    end

    it "should set the size" do
      expect(image.real_size).to eq(Vector2d.new(320, 200))
    end

    context "when the upload has incorrect content type" do
      let(:content_type) { "image/jpeg" }

      it "should set the content type based on image data" do
        expect(image.content_type).to eq("image/png")
      end
    end
  end
end