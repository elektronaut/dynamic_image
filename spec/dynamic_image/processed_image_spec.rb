# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::ProcessedImage do
  def read_image(filename)
    File.open(
      File.expand_path("../../support/fixtures/#{filename}", __FILE__),
      "rb"
    )
  end

  subject(:processed) { described_class.new(record) }

  let(:image) { read_image("image.png") }
  let(:record) { Image.new(data: image.read, filename: "test.png") }

  describe "#cropped_and_resized" do
    subject(:dimensions) { metadata.dimensions }

    let(:size) { Vector2d.new(149, 149) }
    let(:normalized) { processed.cropped_and_resized(size) }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }

    context "when image is saved" do
      let(:record) { Image.create(data: image.read, filename: "test.png") }

      it { is_expected.to eq(size) }

      it "creates a variant" do
        expect { normalized }.to change(DynamicImage::Variant, :count).by(1)
      end
    end

    context "when image isn't saved" do
      it { is_expected.to eq(size) }

      it "doesn't create a variant" do
        expect { normalized }.not_to change(DynamicImage::Variant, :count)
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
  end
end
