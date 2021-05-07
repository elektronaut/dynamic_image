# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::ImageProcessor do
  def format(name)
    DynamicImage::Format.find(name)
  end

  def image_file(filename)
    File.open(
      File.expand_path("../../support/fixtures/#{filename}", __FILE__),
      "rb"
    )
  end

  let(:file) { image_file("image.png") }
  let(:processor) { described_class.new(file) }
  let(:image) { processor }
  let(:reread) { described_class.new(image.read) }

  describe "#convert" do
    let(:image) { processor.convert(format(:png)) }
    let(:metadata) { DynamicImage::Metadata.new(image.read) }

    it "converts the image" do
      expect(metadata.content_type).to eq("image/png")
    end
  end

  describe "#crop" do
    subject(:size) { reread.size }

    let(:image) { processor.crop(Vector2d(30, 20), Vector2d(50, 50)) }

    it { is_expected.to eq(Vector2d(50, 50)) }

    it "raises an error when width is out of bounds" do
      expect do
        processor.crop(Vector2d(100, 100), Vector2d(300, 50))
      end.to raise_error(DynamicImage::Errors::InvalidTransformation)
    end

    it "raises an error when height is out of bounds" do
      expect do
        processor.crop(Vector2d(100, 100), Vector2d(50, 150))
      end.to raise_error(DynamicImage::Errors::InvalidTransformation)
    end

    context "when image is animated" do
      let(:file) { image_file("animated.gif") }

      it { is_expected.to eq(Vector2d(50, 50)) }

      it "crops each frame" do
        last_frame = image.frame(2)
        expect(last_frame.image.getpoint(0, 0)).to eq([0.0, 0.0, 255.0, 255.0])
      end
    end
  end

  describe "#frame" do
    let(:file) { image_file("animated.gif") }
    let(:image) { processor.frame(2) }

    specify { expect(reread.size).to eq(Vector2d(320, 200)) }
    specify { expect(reread.frame_count).to eq(1) }

    it "extracts the correct frame" do
      expect(reread.image.getpoint(0, 0)).to eq([0.0, 0.0, 255.0, 255.0])
    end
  end

  describe "#intent" do
    subject { processor.intent }

    it { is_expected.to eq(DynamicImage::Format.find("PNG")) }
  end

  describe "#frame_count" do
    subject { image.frame_count }

    context "when image is a JPEG" do
      let(:file) { image_file("image.jpg") }

      it { is_expected.to eq(1) }
    end

    context "when image is a GIF" do
      let(:file) { image_file("image.gif") }

      it { is_expected.to eq(1) }
    end

    context "when image is an animated GIF" do
      let(:file) { image_file("animated.gif") }

      it { is_expected.to eq(3) }
    end

    context "when image is an animated WEBP" do
      let(:file) { image_file("animated.webp") }

      it { is_expected.to eq(3) }
    end
  end

  describe "#read" do
    subject(:result) { processor.read }

    it { is_expected.to be_a(String) }

    it "returns a binary string" do
      expect(result.encoding).to eq(Encoding::ASCII_8BIT)
    end
  end

  describe "#resize" do
    it "scales the image down" do
      resized = processor.resize(Vector2d(160, 100))
      expect(resized.size).to eq(Vector2d(160, 100))
    end

    it "scales the image up" do
      resized = processor.resize(Vector2d(640, 400))
      expect(resized.size).to eq(Vector2d(640, 400))
    end

    it "constrains both dimensions given a single size" do
      resized = processor.rotate(90).resize(80)
      expect(resized.size).to eq(Vector2d(50, 80))
    end

    it "does not crop the image" do
      resized = processor.resize(Vector2d(400, 400))
      expect(resized.size).to eq(Vector2d(400, 250))
    end

    context "when image is animated" do
      let(:file) { image_file("animated.gif") }
      let(:image) { processor.resize(80) }

      it "creates an animated file" do
        expect(reread.frame_count).to eq(3)
      end

      it "resizes all frames" do
        expect(reread.frame(2).size).to eq(Vector2d(80, 50))
      end
    end
  end

  describe "#rotate" do
    it "rotates the image" do
      expect(processor.rotate(90).size).to eq(Vector2d(200, 320))
    end

    it "only acceps multiples of 90 degrees" do
      expect do
        processor.rotate(45)
      end.to raise_error(DynamicImage::Errors::InvalidTransformation)
    end

    context "when image is animated" do
      let(:file) { image_file("animated.gif") }
      let(:image) { processor.rotate(90) }

      it "creates an animated file" do
        expect(reread.frame_count).to eq(3)
      end

      it "rotates all frames" do
        expect(reread.frame(2).size).to eq(Vector2d(200, 320))
      end
    end
  end

  describe "#screen_profile" do
    let(:image) { processor.screen_profile }
    let(:metadata) { DynamicImage::Metadata.new(image.read) }

    context "when image is in CMYK" do
      let(:file) { image_file("cmyk.jpg") }

      it "converts the image to RGB" do
        expect(metadata.colorspace).to eq("rgb")
      end
    end

    context "when image is in CMYK with embedded profile" do
      let(:file) { image_file("cmyk-profile.jpg") }

      it "converts the image to RGB" do
        expect(metadata.colorspace).to eq("rgb")
      end
    end

    context "when image is in grayscale" do
      let(:file) { image_file("gray.jpg") }

      it "does not convert the image to RGB" do
        expect(metadata.colorspace).to eq("gray")
      end
    end

    context "when image is in grayscale with embedded profile" do
      let(:file) { image_file("gray-profile.jpg") }

      it "converts the image to RGB" do
        expect(metadata.colorspace).to eq("gray")
      end
    end

    context "when image is in Adobe RGB" do
      let(:file) { image_file("adobe-rgb.jpg") }

      it "converts the colors" do
        expect(image.image.getpoint(0, 0)).to eq([0.0, 255.0, 1.0])
      end
    end
  end

  describe "#size" do
    subject { image.size }

    it { is_expected.to eq(Vector2d(320, 200)) }
  end

  describe "#write" do
    let(:filename) { "output.png" }

    after { File.unlink(filename) if File.exist?(filename) }

    it "writes the image to a file" do
      image.write(filename)
      reader = DynamicImage::ImageReader.new(File.open(filename, "rb"))
      expect(reader.valid_header?).to eq(true)
    end
  end
end
