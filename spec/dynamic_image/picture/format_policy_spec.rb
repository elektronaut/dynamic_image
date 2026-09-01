# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Picture::FormatPolicy do
  subject(:policy) { described_class.new(image, requested) }

  def fixture(name, content_type)
    Rack::Test::UploadedFile.new(
      File.open(File.expand_path("../../support/fixtures/#{name}", __dir__)),
      content_type
    )
  end

  let(:image) { Image.create(file: fixture("image.png", "image/png")) }
  let(:requested) { :webp }

  describe "#source" do
    it "transcodes to the requested format, whatever the source is" do
      expect(policy.source.name).to eq("WEBP")
    end

    context "with a list" do
      let(:requested) { %i[jxl png] }

      it "negotiates" do
        expect(policy.source.name).to eq("PNG")
      end
    end

    context "with an unknown format" do
      let(:requested) { :bogus }

      it "raises" do
        expect { policy.source }
          .to raise_error(ArgumentError, /unknown format/)
      end
    end
  end

  describe "#fallback" do
    it "keeps a compatible source format" do
      expect(policy.fallback.name).to eq("PNG")
    end

    context "with a transparent image in a modern format" do
      let(:image) do
        Image.create(file: fixture("transparent.webp", "image/webp"))
      end

      it "keeps the alpha channel" do
        expect(policy.fallback.name).to eq("PNG")
      end
    end

    context "with an opaque image in a modern format" do
      let(:image) { Image.create(file: fixture("image.webp", "image/webp")) }

      it "transcodes to JPEG" do
        expect(policy.fallback.name).to eq("JPEG")
      end
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.webp", "image/webp")) }

      it "keeps the stored format rather than becoming a giant GIF" do
        expect(policy.fallback.name).to eq("WEBP")
      end
    end
  end
end
