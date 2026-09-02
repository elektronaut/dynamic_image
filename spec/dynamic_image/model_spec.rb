# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Model do
  let(:file_path) { "../../support/fixtures/image.png" }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.new }

  describe ".animated?" do
    subject { image.animated? }

    context "when the image has several frames" do
      let(:image) { Image.new(frame_count: 12, content_type: "image/gif") }

      it { is_expected.to be true }
    end

    context "when the image has several frames in a still format" do
      let(:image) { Image.new(frame_count: 2, content_type: "image/tiff") }

      it { is_expected.to be false }
    end

    context "when the image has several frames in an unknown format" do
      let(:image) { Image.new(frame_count: 2, content_type: "image/jp2") }

      it { is_expected.to be false }
    end

    context "when the image has one frame" do
      let(:image) { Image.new(frame_count: 1, content_type: "image/gif") }

      it { is_expected.to be false }
    end

    context "when the image predates the frame count" do
      let(:image) { LegacyImage.new }

      it { is_expected.to be false }
    end
  end

  describe ".alt_text" do
    subject { image.alt_text }

    context "when the image has alt text" do
      let(:image) { Image.new(alt_text: "A kitten") }

      it { is_expected.to eq("A kitten") }
    end

    context "when the image is marked as decorative" do
      let(:image) { Image.new(alt_text: "") }

      it { is_expected.to eq("") }
    end

    context "when the image has no alt text" do
      it { is_expected.to be_nil }
    end

    context "when the table has no alt_text column" do
      let(:image) { LegacyImage.new }

      it { is_expected.to be_nil }
    end
  end

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
    subject { image.to_param }

    let(:image) { Image.new(updated_at: DateTime.new(2014, 6, 18, 12, 0).utc) }

    it { is_expected.to eq("#{image.id}-20140618120000000000") }
  end

  describe ".safe_content_type" do
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

    context "when image is WEBP" do
      let(:image) { Image.new(content_type: "image/webp") }

      it { is_expected.to eq("image/webp") }
    end

    context "when image is an opaque HEIC" do
      let(:image) do
        Image.new(content_type: "image/heic", frame_count: 1, alpha: false)
      end

      it { is_expected.to eq("image/jpeg") }
    end

    context "when image is a transparent AVIF" do
      let(:image) do
        Image.new(content_type: "image/avif", frame_count: 1, alpha: true)
      end

      it { is_expected.to eq("image/png") }
    end

    context "when image is an animated AVIF" do
      let(:image) do
        Image.new(content_type: "image/avif", frame_count: 3, alpha: true)
      end

      it { is_expected.to eq("image/gif") }
    end
  end

  describe "metadata parsing" do
    before { image.valid? }

    let(:image) { Image.new(file: uploaded_file) }

    it "sets the color space" do
      expect(image.colorspace).to eq("rgb")
    end

    it "sets the size" do
      expect(image.real_size).to eq(Vector2d.new(320, 200))
    end

    it "sets the frame count" do
      expect(image.frame_count).to eq(1)
    end

    it "sets the alpha channel flag" do
      expect(image.alpha).to be(false)
    end

    context "when the upload has incorrect content type" do
      let(:content_type) { "image/jpeg" }

      it "sets the content type based on image data" do
        expect(image.content_type).to eq("image/png")
      end
    end

    context "when the image is animated" do
      let(:file_path) { "../../support/fixtures/animated.webp" }
      let(:content_type) { "image/webp" }

      it "counts the frames" do
        expect(image.frame_count).to eq(3)
      end

      it "records the alpha channel" do
        expect(image.alpha).to be(true)
      end
    end

    context "when the image is a still with transparency" do
      let(:file_path) { "../../support/fixtures/transparent.webp" }
      let(:content_type) { "image/webp" }

      it "counts a single frame" do
        expect(image.frame_count).to eq(1)
      end

      it "records the alpha channel" do
        expect(image.alpha).to be(true)
      end
    end

    context "when the table predates the columns" do
      let(:image) { LegacyImage.new(file: uploaded_file) }

      it "reads the rest of the metadata" do
        expect(image.colorspace).to eq("rgb")
      end

      it "accepts the image" do
        expect(image).to be_valid
      end
    end
  end
end
