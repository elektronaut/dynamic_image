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

  subject(:processed) { described_class.new(record) }

  let(:image) { read_image("image.png") }
  let(:record) { Image.new(data: image.to_blob, filename: "test.png") }

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

    context "with invalid data" do
      let(:record) { Image.new(data: "foo") }

      it "raises an error" do
        expect { normalized }.to raise_error(DynamicImage::Errors::InvalidImage)
      end
    end

    context "when image is in CMYK" do
      let(:image) do
        super().tap { |o| o.format("JPEG") }
               .tap { |o| o.colorspace("CMYK") }
      end

      it "converts to RGB" do
        expect(metadata.colorspace).to eq("rgb")
      end
    end

    context "when image is in grayscale" do
      let(:image) do
        super().tap { |o| o.format("JPEG") }
               .tap { |o| o.colorspace("Gray") }
      end

      it "keeps the colorspace" do
        expect(metadata.colorspace).to eq("gray")
      end
    end

    context "when image is in RGB" do
      it "stays in RGB" do
        expect(metadata.colorspace).to eq("rgb")
      end
    end

    context "when image is in Adobe RGB" do
      let(:image) { read_image("adobe-rgb.jpg") }
      let(:pixels) { MiniMagick::Image.read(normalized).get_pixels }

      it "converts the colors" do
        expect(pixels[0][0]).to eq([0x00, 0xff, 0x01])
      end
    end

    context "when image is GIF" do
      let(:image) { super().tap { |o| o.format("GIF") } }

      it "returns a GIF" do
        expect(metadata.content_type).to eq("image/gif")
      end
    end

    context "when image is JPEG" do
      let(:image) { super().tap { |o| o.format("JPEG") } }

      it "returns a JPEG" do
        expect(metadata.content_type).to eq("image/jpeg")
      end
    end

    context "when image is PNG" do
      it "returns a PNG" do
        expect(metadata.content_type).to eq("image/png")
      end
    end

    context "when image is TIFF" do
      let(:image) { read_image("image.tif") }

      it "returns a TIFF" do
        expect(metadata.content_type).to eq("image/tiff")
      end
    end

    context "when image is BMP" do
      let(:image) { super().tap { |o| o.format("BMP") } }

      it "returns a BMP" do
        expect(metadata.content_type).to eq("image/bmp")
      end
    end

    context "when image is WEBP" do
      let(:image) { read_image("image.webp") }

      it "returns a WEBP" do
        expect(metadata.content_type).to eq("image/webp")
      end
    end

    context "when converting BMP to JPEG" do
      let(:image) { super().tap { |o| o.format("BMP") } }
      let(:processed) do
        described_class.new(record, format: :jpeg)
      end

      it "returns a JPEG" do
        expect(metadata.content_type).to eq("image/jpeg")
      end
    end

    context "when converting WEBP to JPEG" do
      let(:image) { read_image("image.webp") }
      let(:processed) do
        described_class.new(record, format: :jpeg)
      end

      it "returns a JPEG" do
        expect(metadata.content_type).to eq("image/jpeg")
      end
    end

    context "when converting PNG to GIF" do
      let(:processed) do
        described_class.new(record, format: :gif)
      end

      it "returns a GIF" do
        expect(metadata.content_type).to eq("image/gif")
      end
    end

    context "when converting PNG to JPEG" do
      let(:processed) do
        described_class.new(record, format: :jpeg)
      end

      it "returns a JPEG" do
        expect(metadata.content_type).to eq("image/jpeg")
      end
    end

    context "when converting JPEG to PNG" do
      let(:image) { super().tap { |o| o.format("JPEG") } }
      let(:processed) do
        described_class.new(record, format: :png)
      end

      it "returns a PNG" do
        expect(metadata.content_type).to eq("image/png")
      end
    end

    context "when converting PNG to TIFF" do
      let(:processed) do
        described_class.new(record, format: :tiff)
      end

      it "returns a TIFF" do
        expect(metadata.content_type).to eq("image/tiff")
      end
    end
  end
end
