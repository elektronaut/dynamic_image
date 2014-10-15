require 'spec_helper'

describe DynamicImage::ImageSizing do
  def vector(x, y)
    Vector2d.new(x, y)
  end

  let(:record) { Image.new }
  let(:sizing) { DynamicImage::ImageSizing.new(record) }

  describe "#crop_geometry_string" do
    let(:record) { Image.new(real_width: 320, real_height: 200) }
    let(:crop_size) { vector(200, 200) }
    subject { sizing.crop_geometry_string(crop_size) }
    it { is_expected.to eq("200x200+60+0!") }
  end

  describe "#crop_geometry" do
    subject { sizing.crop_geometry(crop_size) }

    context "when image isn't cropped" do
      let(:record) { Image.new(real_width: 321, real_height: 201) }

      context "cropping horizontally" do
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(201, 201), vector(60, 0)]) }
      end

      context "cropping vertically" do
        let(:crop_size) { vector(160, 50) }
        it { is_expected.to eq([vector(321, 100), vector(0, 50)]) }
      end

      context "cropping with large size" do
        let(:crop_size) { vector(600, 600) }
        it { is_expected.to eq([vector(201, 201), vector(60, 0)]) }
      end

      context "cropping with top left gravity" do
        let(:record) { Image.new(crop_gravity_x: 0, crop_gravity_y: 0, real_width: 320, real_height: 200) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(200, 200), vector(0, 0)]) }
      end

      context "cropping with bottom right gravity" do
        let(:record) { Image.new(crop_gravity_x: 320, crop_gravity_y: 200, real_width: 320, real_height: 200) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(200, 200), vector(120, 0)]) }
      end
    end

    context "when image is cropped" do
      let(:record) { Image.new(real_width: 521, real_height: 401, crop_width: 321, crop_height: 201, crop_start_x: 10, crop_start_y: 10) }

      context "cropping horizontally" do
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(201, 201), vector(70, 10)]) }
      end

      context "cropping vertically" do
        let(:crop_size) { vector(160, 50) }
        it { is_expected.to eq([vector(321, 100), vector(10, 60)]) }
      end

      context "cropping with top left gravity" do
        let(:record) { Image.new(crop_gravity_x: 0, crop_gravity_y: 0, real_width: 521, real_height: 401, crop_width: 320, crop_height: 200, crop_start_x: 10, crop_start_y: 10) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(200, 200), vector(10, 10)]) }
      end

      context "cropping with bottom right gravity" do
        let(:record) { Image.new(crop_gravity_x: 320, crop_gravity_y: 200, real_width: 521, real_height: 401, crop_width: 320, crop_height: 200, crop_start_x: 10, crop_start_y: 10) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(200, 200), vector(130, 10)]) }
      end

      context "and crop start is zero" do
        let(:record) { Image.new(real_width: 520, real_height: 400, crop_width: 320, crop_height: 200, crop_start_x: 0, crop_start_y: 0) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(200, 200), vector(60, 0)]) }
      end

      context "with precropping disabled" do
        let(:sizing) { DynamicImage::ImageSizing.new(record, uncropped: true) }
        let(:crop_size) { vector(200, 200) }
        it { is_expected.to eq([vector(401, 401), vector(60, 0)]) }
      end
    end
  end

  describe "#fit" do
    let(:record) { Image.new(real_width: 320, real_height: 200) }
    let(:options) { {} }
    let(:size) { vector(100, 100) }
    subject { sizing.fit(size, options) }

    context "with string argument" do
      context "with both dimensions" do
        let(:size) { "100x100" }
        it { is_expected.to eq(vector(100, 62.5)) }
      end

      context "with only width" do
        let(:size) { "100x" }
        it { is_expected.to eq(vector(100, 62.5)) }
      end

      context "with only height" do
        let(:size) { "x100" }
        it { is_expected.to eq(vector(160, 100)) }
      end
    end

    context "with no options" do
      context "when fit_size is smaller" do
        it { is_expected.to eq(vector(100, 62.5)) }
      end

      context "when fit_size is larger" do
        let(:size) { vector(500, 500) }
        it { is_expected.to eq(vector(320, 200)) }
      end
    end

    context "with crop: true" do
      let(:options) { { crop: true } }

      context "when fit_size is smaller" do
        it { is_expected.to eq(vector(100, 100)) }
      end

      context "with unspecified width" do
        let(:size) { vector(0, 100) }
        it "should raise an error" do
          expect { subject }.to raise_error(DynamicImage::Errors::InvalidSizeOptions)
        end
      end

      context "with unspecified height" do
        let(:size) { vector(100, 0) }
        it "should raise an error" do
          expect { subject }.to raise_error(DynamicImage::Errors::InvalidSizeOptions)
        end
      end

      context "when fit_size is larger" do
        let(:size) { vector(500, 500) }
        it { is_expected.to eq(vector(200, 200)) }
      end
    end

    context "with upscale: true" do
      let(:options) { { upscale: true } }

      context "when fit_size is smaller" do
        it { is_expected.to eq(vector(100, 62.5)) }
      end

      context "with only width" do
        let(:size) { vector(400, 0) }
        it { is_expected.to eq(vector(400, 250)) }
      end

      context "with only height" do
        let(:size) { vector(0, 300) }
        it { is_expected.to eq(vector(480, 300)) }
      end

      context "when fit_size is larger" do
        let(:size) { vector(500, 500) }
        it { is_expected.to eq(vector(500, 312.5)) }
      end
    end

    context "with crop: true, upscale: true" do
      let(:options) { { crop: true, upscale: true } }
      let(:size) { vector(500, 520) }
      it { is_expected.to eq(vector(500, 520)) }
    end

    context "with a cropped image" do
      let(:record) { Image.new(real_width: 520, real_height: 500, crop_width: 320, crop_height: 200, crop_start_x: 10, crop_start_y: 10) }
      let(:size) { vector(1000, 1000) }

      context "and normal sizing" do
        it { is_expected.to eq(vector(320, 200)) }
      end

      context "and uncropped sizing" do
        let(:sizing) { DynamicImage::ImageSizing.new(record, uncropped: true) }
        it { is_expected.to eq(vector(520, 500)) }
      end
    end
  end
end