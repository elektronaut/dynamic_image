# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::ProcessedImage do
  let(:file_path) { "../../support/fixtures/image.png" }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:source_image) { MiniMagick::Image.read(file.read) }

  let(:gif_image)  { source_image.tap { |o| o.format("GIF") } }
  let(:jpeg_image) { source_image.tap { |o| o.format("JPEG") } }
  let(:png_image)  { source_image.tap { |o| o.format("PNG") } }
  let(:tiff_image) { source_image.tap { |o| o.format("TIFF") } }
  let(:bmp_image) { source_image.tap { |o| o.format("BMP") } }

  let(:rgb_image)  { source_image }
  let(:cmyk_image) { jpeg_image.tap { |o| o.colorspace("CMYK") } }
  let(:gray_image) { jpeg_image.tap { |o| o.colorspace("Gray") } }

  let(:image) { source_image }

  let(:record) { Image.new(data: image.to_blob, filename: "test.png") }
  let(:processed) { DynamicImage::ProcessedImage.new(record) }

  describe "#content_type" do
    let(:record) { Image.new }
    subject { processed.content_type }

    context "when format is GIF" do
      let(:processed) do
        DynamicImage::ProcessedImage.new(record, format: :gif)
      end
      it { is_expected.to eq("image/gif") }
    end

    context "when format is JPEG" do
      let(:processed) do
        DynamicImage::ProcessedImage.new(record, format: :jpg)
      end
      it { is_expected.to eq("image/jpeg") }
    end

    context "when format is PNG" do
      let(:processed) do
        DynamicImage::ProcessedImage.new(record, format: :png)
      end
      it { is_expected.to eq("image/png") }
    end

    context "when format is TIFF" do
      let(:processed) do
        DynamicImage::ProcessedImage.new(record, format: :tiff)
      end
      it { is_expected.to eq("image/tiff") }
    end

    context "when format is BMP" do
      let(:processed) do
        DynamicImage::ProcessedImage.new(record, format: :bmp)
      end
      it { is_expected.to eq("image/bmp") }
    end
  end

  describe "#cropped_and_resized" do
    let(:size) { Vector2d.new(149, 149) }
    let(:normalized) { processed.cropped_and_resized(size) }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }
    subject(:dimensions) { metadata.dimensions }

    context "when image is saved" do
      let(:record) { Image.create(data: image.to_blob, filename: "test.png") }

      it { is_expected.to eq(size) }

      it "creates a variant" do
        expect { normalized }.to change { DynamicImage::Variant.count }.by(1)
      end
    end

    context "when image isn't saved" do
      it { is_expected.to eq(size) }

      it "doesn't create a variant" do
        expect { normalized }.to change { DynamicImage::Variant.count }.by(0)
      end
    end
  end

  describe "#normalized" do
    let(:normalized) { processed.normalized }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }

    context "with invalid data" do
      let(:record) { Image.new(data: "foo") }
      it "should raise an error" do
        expect { normalized }.to raise_error(DynamicImage::Errors::InvalidImage)
      end
    end

    describe "colorspace conversion" do
      subject { metadata.colorspace }

      context "when image is in CMYK" do
        let(:image) { cmyk_image }
        it { is_expected.to eq("rgb") }
      end

      context "when image is in grayscale" do
        let(:image) { gray_image }
        it { is_expected.to eq("gray") }
      end

      context "when image is in RGB" do
        let(:image) { rgb_image }
        it { is_expected.to eq("rgb") }
      end
    end

    describe "format conversion" do
      subject { metadata.content_type }

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

      context "converting BMP to JPEG" do
        let(:processed) do
          DynamicImage::ProcessedImage.new(record, format: :bmp)
        end
        it { is_expected.to eq("image/bmp") }
      end

      context "converting PNG to GIF" do
        let(:processed) do
          DynamicImage::ProcessedImage.new(record, format: :gif)
        end
        it { is_expected.to eq("image/gif") }
      end

      context "converting PNG to JPEG" do
        let(:processed) do
          DynamicImage::ProcessedImage.new(record, format: :jpeg)
        end
        it { is_expected.to eq("image/jpeg") }
      end

      context "converting JPEG to PNG" do
        let(:image) { jpeg_image }
        let(:processed) do
          DynamicImage::ProcessedImage.new(record, format: :png)
        end
        it { is_expected.to eq("image/png") }
      end

      context "converting PNG to TIFF" do
        let(:processed) do
          DynamicImage::ProcessedImage.new(record, format: :tiff)
        end
        it { is_expected.to eq("image/tiff") }
      end
    end
  end
end
