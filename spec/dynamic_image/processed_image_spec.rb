require 'spec_helper'

describe DynamicImage::ProcessedImage do
  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:source_image) { MiniMagick::Image.read(file.read) }

  let(:gif_image)  { source_image.format("GIF"); source_image }
  let(:jpeg_image) { source_image.format("JPEG"); source_image }
  let(:png_image)  { source_image.format("PNG"); source_image }
  let(:tiff_image) { source_image.format("TIFF"); source_image }

  let(:rgb_image)  { source_image }
  let(:cmyk_image) { jpeg_image.colorspace("CMYK"); jpeg_image }
  let(:gray_image) { jpeg_image.colorspace("Gray"); jpeg_image }

  let(:image) { source_image }

  let(:record) { Image.new(data: image.to_blob, filename: 'test.png') }
  let(:processed) { DynamicImage::ProcessedImage.new(record) }

  describe "#cropped_and_resized" do
    let(:size) { Vector2d.new(149, 149) }
    let(:normalized) { processed.cropped_and_resized(size) }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }
    subject { metadata.dimensions }
    it { is_expected.to eq(size) }
  end

  describe "#normalized" do
    let(:normalized) { processed.normalized }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }

    context "with invalid data" do
      let(:record) { Image.new(data: "foo") }
      it "should raise an error" do
        expect { normalized }.to raise_error(DynamicImage::Errors::InvalidImageError)
      end
    end

    describe "colorspace conversion" do
      subject { metadata.colorspace }

      context "when image is in CMYK" do
        let(:image) { cmyk_image }
        it { is_expected.to eq('rgb') }
      end

      context "when image is in grayscale" do
        let(:image) { gray_image }
        it { is_expected.to eq('gray') }
      end

      context "when image is in RGB" do
        let(:image) { rgb_image }
        it { is_expected.to eq('rgb') }
      end
    end

    describe "format conversion" do
      subject { metadata.content_type }

      context "with no arguments" do
        it { is_expected.to eq('image/png') }
      end

      context "converting to GIF" do
        let(:processed) { DynamicImage::ProcessedImage.new(record, :gif) }
        it { is_expected.to eq('image/gif') }
      end

      context "converting to JPEG" do
        let(:processed) { DynamicImage::ProcessedImage.new(record, :jpeg) }
        it { is_expected.to eq('image/jpeg') }
      end

      context "converting to PNG" do
        let(:processed) { DynamicImage::ProcessedImage.new(record, :png) }
        it { is_expected.to eq('image/png') }
      end

      context "converting to TIFF" do
        let(:processed) { DynamicImage::ProcessedImage.new(record, :tiff) }
        it { is_expected.to eq('image/tiff') }
      end
    end
  end
end