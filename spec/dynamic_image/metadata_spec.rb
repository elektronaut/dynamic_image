# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Metadata do
  def read_image(filename)
    MiniMagick::Image.read(
      File.open(
        File.expand_path("../../support/fixtures/#{filename}", __FILE__)
      )
    )
  end

  let(:source_image) { read_image("image.png") }

  let(:gif_image)  { source_image.tap { |o| o.format("GIF") } }
  let(:jpeg_image) { source_image.tap { |o| o.format("JPEG") } }
  let(:png_image)  { source_image.tap { |o| o.format("PNG") } }
  let(:tiff_image) { read_image("image.tif") }
  let(:bmp_image) { source_image.tap { |o| o.format("BMP") } }
  let(:webp_image) { read_image("image.webp") }

  let(:rgb_image) { source_image }
  let(:cmyk_image) { jpeg_image.tap { |o| o.colorspace("CMYK") } }
  let(:gray_image) { jpeg_image.tap { |o| o.colorspace("Gray") } }

  let(:image) { source_image }
  let(:image_data) { image.to_blob }
  let(:meta_info) { described_class.new(image_data) }

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

    context "when image is BMP" do
      let(:image) { bmp_image }

      it { is_expected.to eq("image/bmp") }
    end

    context "when image is WEBP" do
      let(:image) { webp_image }

      it { is_expected.to eq("image/webp") }
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

    context "when image is BMP" do
      let(:image) { bmp_image }

      it { is_expected.to eq("BMP") }
    end

    context "when image is WEBP" do
      let(:image) { webp_image }

      it { is_expected.to eq("WEBP") }
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
