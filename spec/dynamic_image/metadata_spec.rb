require 'spec_helper'

describe DynamicImage::Metadata do
  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:source_image) { MiniMagick::Image.read(file.read) }

  let(:gif_image)  { source_image.format("GIF"); source_image }
  let(:jpeg_image) { source_image.format("JPEG"); source_image }
  let(:png_image)  { source_image.format("PNG"); source_image }
  let(:tiff_image) { source_image.format("TIFF"); source_image }

  let(:rgb_image) { source_image }
  let(:cmyk_image) { jpeg_image.colorspace("CMYK"); jpeg_image }
  let(:gray_image) { jpeg_image.colorspace("Gray"); jpeg_image }

  let(:image) { source_image }
  let(:image_data) { image.to_blob }
  let(:meta_info) { DynamicImage::Metadata.new(image_data) }

  describe "#colorspace" do
    subject { meta_info.colorspace }

    context "when image is sRGB" do
      let(:image) { rgb_image }
      it { is_expected.to eq("rgb") }
    end

    context "when image is grayscale" do
      let(:image) { gray_image }
      it { is_expected.to eq("gray") }
    end

    context "when image is CMYK" do
      let(:image) { cmyk_image }
      it { is_expected.to eq("cmyk") }
    end

    context "with invalid data" do
      let(:image_data) { "invalid" }
      it { is_expected.to be nil }
    end
  end

  describe "#format" do
    subject { meta_info.content_type }

    context "when image is GIF" do
      let(:image) { gif_image }
      it { is_expected.to eq("image/gif") }
    end

    context "when image is JPEG" do
      let(:image) { jpeg_image }
      it { is_expected.to eq("image/jpeg") }
    end

    context "when image is PNG" do
      let(:image) { png_image }
      it { is_expected.to eq("image/png") }
    end

    context "when image is TIFF" do
      let(:image) { tiff_image }
      it { is_expected.to eq("image/tiff") }
    end

    context "with invalid data" do
      let(:image_data) { "invalid" }
      it { is_expected.to be nil }
    end
  end

  describe "#dimensions" do
    subject { meta_info.dimensions }
    it { is_expected.to eq(Vector2d.new(320, 200)) }

    context "with invalid data" do
      let(:image_data) { "invalid" }
      it { is_expected.to be nil }
    end
  end

  describe "#width" do
    subject { meta_info.width }
    it { is_expected.to eq(320) }

    context "with invalid data" do
      let(:image_data) { "invalid" }
      it { is_expected.to be nil }
    end
  end

  describe "#height" do
    subject { meta_info.height }
    it { is_expected.to eq(200) }

    context "with invalid data" do
      let(:image_data) { "invalid" }
      it { is_expected.to be nil }
    end
  end

  describe "#format" do
    subject { meta_info.format }

    context "when image is GIF" do
      let(:image) { gif_image }
      it { is_expected.to eq("GIF") }
    end

    context "when image is JPEG" do
      let(:image) { jpeg_image }
      it { is_expected.to eq("JPEG") }
    end

    context "when image is PNG" do
      let(:image) { png_image }
      it { is_expected.to eq("PNG") }
    end

    context "when image is TIFF" do
      let(:image) { tiff_image }
      it { is_expected.to eq("TIFF") }
    end

    context "with invalid data" do
      let(:image_data) { "invalid" }
      it { is_expected.to be nil }
    end
  end

  describe "#valid?" do
    subject { meta_info.valid? }

    context "when valid" do
      it { is_expected.to be true }
    end

    context "when invalid" do
      let(:image_data) { "invalid" }
      it { is_expected.to be false }
    end
  end
end