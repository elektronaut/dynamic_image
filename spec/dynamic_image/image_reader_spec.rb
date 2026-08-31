# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::ImageReader do
  let(:fixture_path) do
    File.expand_path("../support/fixtures/image.png", __dir__)
  end

  describe "with an ISO base media or JPEG XL file" do
    subject(:reader) { described_class.new(Pathname(path)) }

    let(:path) do
      File.expand_path("../support/fixtures/image.#{extension}", __dir__)
    end

    context "with a HEIC" do
      let(:extension) { "heic" }

      it { expect(reader.format.name).to eq("HEIC") }
      it { expect(reader.read.width).to eq(320) }
    end

    context "with an AVIF" do
      let(:extension) { "avif" }

      it { expect(reader.format.name).to eq("AVIF") }
      it { expect(reader.read.width).to eq(320) }
    end

    context "with a JPEG XL" do
      let(:extension) { "jxl" }

      it { expect(reader.format.name).to eq("JXL") }
      it { expect(reader.read.width).to eq(320) }
    end
  end

  describe "with a Pathname" do
    subject(:reader) { described_class.new(Pathname(fixture_path)) }

    describe "#format" do
      it "detects the format" do
        expect(reader.format.name).to eq("PNG")
      end
    end

    describe "#valid_header?" do
      it "returns true" do
        expect(reader.valid_header?).to be(true)
      end
    end

    describe "#read" do
      it "returns a Vips::Image" do
        expect(reader.read).to be_a(Vips::Image)
      end

      it "has the correct width" do
        expect(reader.read.get("width")).to eq(320)
      end

      it "has the correct height" do
        expect(reader.read.get("height")).to eq(200)
      end
    end
  end
end
