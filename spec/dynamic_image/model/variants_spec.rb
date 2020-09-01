# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Model::Variants do
  let(:source_image) do
    MiniMagick::Image.read(
      File.open(
        File.expand_path("../../support/fixtures/image.png", __dir__)
      ).read
    )
  end

  let(:jpeg_image) { source_image.tap { |o| o.format("JPEG") } }
  let(:png_image)  { source_image.tap { |o| o.format("PNG") } }

  let(:image) do
    Image.create(data: png_image.to_blob,
                 filename: "test.png")
  end

  let(:processed) { DynamicImage::ProcessedImage.new(image) }

  describe ".clear_variants" do
    before { processed.cropped_and_resized(Vector2d.new(149, 149)) }

    it "clears variants when the data changes" do
      expect { image.update(data: jpeg_image.to_blob) }.to(
        change { image.variants.count }.by(-1)
      )
    end

    it "doesn't clear variants when the data remains the same" do
      expect { image.update(crop_width: 100) }.to(
        change { image.variants.count }.by(0)
      )
    end
  end
end
