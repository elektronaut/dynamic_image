require "spec_helper"

describe DynamicImage::Model do
  let(:file_path) { "../../support/fixtures/image.png" }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.new }

  describe ".cmyk?" do
    subject { image.cmyk? }

    context "when colorspace is CMYK" do
      let(:image) { Image.new(colorspace: "cmyk") }
      it { is_expected.to be true }
    end

    context "when colorspace isn't CMYK" do
      let(:image) { Image.new(colorspace: "rgb") }
      it { is_expected.to be false }
    end
  end

  describe ".gray?" do
    subject { image.gray? }

    context "when colorspace is grayscale" do
      let(:image) { Image.new(colorspace: "gray") }
      it { is_expected.to be true }
    end

    context "when colorspace isn't grayscale" do
      let(:image) { Image.new(colorspace: "rgb") }
      it { is_expected.to be false }
    end
  end

  describe ".rgb?" do
    subject { image.rgb? }

    context "when colorspace is rgb" do
      let(:image) { Image.new(colorspace: "rgb") }
      it { is_expected.to be true }
    end

    context "when colorspace isn't rgb" do
      let(:image) { Image.new(colorspace: "cmyk") }
      it { is_expected.to be false }
    end
  end

  describe ".to_param" do
    let(:timestamp) { DateTime.new(2014, 6, 18, 12, 0).utc }
    subject { image.to_param }
    let(:image) { Image.new(updated_at: timestamp) }
    it { is_expected.to eq("#{image.id}-20140618120000000000") }
  end

  describe ".web_safe_content_type" do
    subject { image.safe_content_type }

    context "when image is GIF" do
      let(:image) { Image.new(content_type: "image/gif") }
      it { is_expected.to eq("image/gif") }
    end

    context "when image is JPEG" do
      let(:image) { Image.new(content_type: "image/jpeg") }
      it { is_expected.to eq("image/jpeg") }
    end

    context "when image is PNG" do
      let(:image) { Image.new(content_type: "image/png") }
      it { is_expected.to eq("image/png") }
    end

    context "when image is TIFF" do
      let(:image) { Image.new(content_type: "image/tiff") }
      it { is_expected.to eq("image/jpeg") }
    end
  end

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
