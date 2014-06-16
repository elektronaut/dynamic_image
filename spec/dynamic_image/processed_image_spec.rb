require 'spec_helper'

describe DynamicImage::ProcessedImage do
  def vector(x, y)
    Vector2d.new(x, y)
  end

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
    let(:size) { vector(149, 149) }
    let(:normalized) { processed.cropped_and_resized(size) }
    let(:metadata) { DynamicImage::Metadata.new(normalized) }
    subject { metadata.dimensions }
    it { is_expected.to eq(size) }
  end

  describe "#crop_geometry" do
    subject { processed.crop_geometry(crop_size) }

    context "when image isn't cropped" do
      let(:record) { Image.new(real_width: 321, real_height: 201) }

      context "cropping horizontally" do
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq("201x201+60+0") }
      end

      context "cropping vertically" do
        let(:crop_size) { vector(160, 50) }
        it { is_expected.to eq("321x100+0+50") }
      end

      context "cropping with large size" do
        let(:crop_size) { vector(600, 600) }
        it { is_expected.to eq("201x201+60+0") }
      end

      context "cropping with top left gravity" do
        let(:record) { Image.new(crop_gravity_x: 0, crop_gravity_y: 0, real_width: 320, real_height: 200) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq("200x200+0+0") }
      end

      context "cropping with bottom right gravity" do
        let(:record) { Image.new(crop_gravity_x: 320, crop_gravity_y: 200, real_width: 320, real_height: 200) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq("200x200+120+0") }
      end
    end

    context "when image is cropped" do
      let(:record) { Image.new(real_width: 521, real_height: 401, crop_width: 321, crop_height: 201, crop_start_x: 10, crop_start_y: 10) }

      context "cropping horizontally" do
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq("201x201+70+10") }
      end

      context "cropping vertically" do
        let(:crop_size) { vector(160, 50) }
        it { is_expected.to eq("321x100+10+60") }
      end

      context "cropping with top left gravity" do
        let(:record) { Image.new(crop_gravity_x: 0, crop_gravity_y: 0, real_width: 521, real_height: 401, crop_width: 320, crop_height: 200, crop_start_x: 10, crop_start_y: 10) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq("200x200+10+10") }
      end

      context "cropping with bottom right gravity" do
        let(:record) { Image.new(crop_gravity_x: 320, crop_gravity_y: 200, real_width: 521, real_height: 401, crop_width: 320, crop_height: 200, crop_start_x: 10, crop_start_y: 10) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq("200x200+130+10") }
      end
    end
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