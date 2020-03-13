# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::ProcessedImage do
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

  let(:rgb_image)  { source_image }
  let(:cmyk_image) { jpeg_image.tap { |o| o.colorspace("CMYK") } }
  let(:gray_image) { jpeg_image.tap { |o| o.colorspace("Gray") } }

  let(:image) { source_image }

  let(:record) { Image.new(data: image.to_blob, filename: "test.png") }
  let(:processed) { described_class.new(record) }

  describe "#content_type" do
    subject { processed.content_type }

    let(:record) { Image.new }

    context "when format is GIF" do
      let(:processed) do
        described_class.new(record, format: :gif)
      end

      it { is_expected.to eq("image/gif") }
    end

    context "when format is JPEG" do
      let(:processed) do
        described_class.new(record, format: :jpg)
      end

      it { is_expected.to eq("image/jpeg") }
    end

    context "when format is PNG" do
      let(:processed) do
        described_class.new(record, format: :png)
      end

      it { is_expected.to eq("image/png") }
    end

    context "when format is TIFF" do
      let(:processed) do
        described_class.new(record, format: :tiff)
      end

      it { is_expected.to eq("image/tiff") }
    end

    context "when format is BMP" do
      let(:processed) do
        described_class.new(record, format: :bmp)
      end

      it { is_expected.to eq("image/bmp") }
    end

    context "when format is WEBP" do
      let(:processed) do
        described_class.new(record, format: :webp)
      end

      it { is_expected.to eq("image/webp") }
    end
  end

  describe "#cropped_and_resized" do
    subject(:dimensions) { metadata.dimensions }

    let(:size) { Vector2d.new(149, 149) }
    let(:normalized) { processed.cropped_and_resized(size) }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }

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
    let(:colorspace) { metadata.colorspace }
    let(:content_type) { metadata.content_type }

    context "with invalid data" do
      let(:record) { Image.new(data: "foo") }

      it "raises an error" do
        expect { normalized }.to raise_error(DynamicImage::Errors::InvalidImage)
      end
    end

    context "when image is in CMYK" do
      let(:image) { cmyk_image }

      it "converts to RGB" do
        expect(colorspace).to eq("rgb")
      end
    end

    context "when image is in grayscale" do
      let(:image) { gray_image }

      it "keeps the colorspace" do
        expect(colorspace).to eq("gray")
      end
    end

    context "when image is in RGB" do
      let(:image) { rgb_image }

      it "stays in RGB" do
        expect(colorspace).to eq("rgb")
      end
    end

    context "when image is GIF" do
      let(:image) { gif_image }

      it "returns a GIF" do
        expect(content_type).to eq("image/gif")
      end
    end

    context "when image is JPEG" do
      let(:image) { jpeg_image }

      it "returns a JPEG" do
        expect(content_type).to eq("image/jpeg")
      end
    end

    context "when image is PNG" do
      let(:image) { png_image }

      it "returns a PNG" do
        expect(content_type).to eq("image/png")
      end
    end

    context "when image is TIFF" do
      let(:image) { tiff_image }

      it "returns a TIFF" do
        expect(content_type).to eq("image/tiff")
      end
    end

    context "when image is BMP" do
      let(:image) { bmp_image }

      it "returns a BMP" do
        expect(content_type).to eq("image/bmp")
      end
    end

    context "when image is WEBP" do
      let(:image) { webp_image }

      it "returns a WEBP" do
        expect(content_type).to eq("image/webp")
      end
    end

    context "when converting BMP to JPEG" do
      let(:image) { bmp_image }
      let(:processed) do
        described_class.new(record, format: :jpeg)
      end

      it "returns a JPEG" do
        expect(content_type).to eq("image/jpeg")
      end
    end

    context "when converting WEBP to JPEG" do
      let(:image) { webp_image }
      let(:processed) do
        described_class.new(record, format: :jpeg)
      end

      it "returns a JPEG" do
        expect(content_type).to eq("image/jpeg")
      end
    end

    context "when converting PNG to GIF" do
      let(:processed) do
        described_class.new(record, format: :gif)
      end

      it "returns a GIF" do
        expect(content_type).to eq("image/gif")
      end
    end

    context "when converting PNG to JPEG" do
      let(:processed) do
        described_class.new(record, format: :jpeg)
      end

      it "returns a JPEG" do
        expect(content_type).to eq("image/jpeg")
      end
    end

    context "when converting JPEG to PNG" do
      let(:image) { jpeg_image }
      let(:processed) do
        described_class.new(record, format: :png)
      end

      it "returns a PNG" do
        expect(content_type).to eq("image/png")
      end
    end

    context "when converting PNG to TIFF" do
      let(:processed) do
        described_class.new(record, format: :tiff)
      end

      it "returns a TIFF" do
        expect(content_type).to eq("image/tiff")
      end
    end
  end
end
