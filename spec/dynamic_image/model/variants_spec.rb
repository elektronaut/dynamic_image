# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Model::Variants do
  def read_image(filename)
    File.open(
      File.expand_path("../../../support/fixtures/#{filename}", __FILE__),
      "rb"
    )
  end

  let(:source_image) { read_image("image.png") }
  let(:jpeg_image) { read_image("image.jpg") }

  let(:image) do
    Image.create(data: source_image.read,
                 filename: "test.png")
  end

  let(:processed) { DynamicImage::ProcessedImage.new(image) }

  describe ".clear_variants" do
    before { processed.cropped_and_resized(Vector2d.new(149, 149)) }

    it "clears variants when the data changes" do
      expect { image.update(data: jpeg_image.read) }.to(
        change { image.variants.count }.by(-1)
      )
    end

    it "doesn't clear variants when the data remains the same" do
      expect { image.update(crop_width: 100) }.not_to(
        change { image.variants.count }
      )
    end
  end
end
