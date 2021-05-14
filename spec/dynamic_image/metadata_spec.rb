# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Metadata do
  def read_image(filename)
    File.open(
      File.expand_path("../../support/fixtures/#{filename}", __FILE__)
    )
  end

  subject(:meta_info) { described_class.new(image_data) }

  let(:source_image) { read_image("image.png") }
  let(:tiff_image) { read_image("image.tif") }
  let(:webp_image) { read_image("image.webp") }

  let(:image) { source_image }
  let(:image_data) { image }

  describe "#colorspace" do
    subject { meta_info.colorspace }

    context "when image is sRGB" do
      let(:image) { source_image }

      it { is_expected.to eq("rgb") }
    end

    context "when image is grayscale" do
      let(:image) { read_image("gray.jpg") }

      it { is_expected.to eq("gray") }
    end

    context "when image is CMYK" do
      let(:image) { read_image("cmyk.jpg") }

      it { is_expected.to eq("cmyk") }
    end

    context "with invalid data" do
      let(:image_data) { "invalid" }

      it { is_expected.to be nil }
    end
  end

  describe "#content_type" do
    subject { meta_info.content_type }

    context "when image is GIF" do
      let(:image) { read_image("image.gif") }

      it { is_expected.to eq("image/gif") }
    end

    context "when image is JPEG" do
      let(:image) { read_image("image.jpg") }

      it { is_expected.to eq("image/jpeg") }
    end

    context "when image is PNG" do
      let(:image) { source_image }

      it { is_expected.to eq("image/png") }
    end

    context "when image is TIFF" do
      let(:image) { tiff_image }

      it { is_expected.to eq("image/tiff") }
    end

    context "when image is BMP" do
      let(:image) { read_image("image.bmp") }

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

    context "when image is rotated" do
      let(:image) { read_image("rotated.jpg") }

      it { is_expected.to eq(Vector2d.new(200, 320)) }
    end
  end

  describe "#width" do
    subject { meta_info.width }

    it { is_expected.to eq(320) }

    context "with invalid data" do
      let(:image_data) { "invalid" }

      it { is_expected.to be nil }
    end

    context "when image is rotated" do
      let(:image) { read_image("rotated.jpg") }

      it { is_expected.to eq(200) }
    end
  end

  describe "#height" do
    subject { meta_info.height }

    it { is_expected.to eq(200) }

    context "with invalid data" do
      let(:image_data) { "invalid" }

      it { is_expected.to be nil }
    end

    context "when image is an animated gif" do
      let(:image) { read_image("animated.gif") }

      it { is_expected.to eq(200) }
    end

    context "when image is rotated" do
      let(:image) { read_image("rotated.jpg") }

      it { is_expected.to eq(320) }
    end
  end

  describe "#format" do
    subject { meta_info.format }

    context "when image is GIF" do
      let(:image) { read_image("image.gif") }

      it { is_expected.to eq("GIF") }
    end

    context "when image is JPEG" do
      let(:image) { read_image("image.jpg") }

      it { is_expected.to eq("JPEG") }
    end

    context "when image is PNG" do
      let(:image) { source_image }

      it { is_expected.to eq("PNG") }
    end

    context "when image is TIFF" do
      let(:image) { tiff_image }

      it { is_expected.to eq("TIFF") }
    end

    context "when image is BMP" do
      let(:image) { read_image("image.bmp") }

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
