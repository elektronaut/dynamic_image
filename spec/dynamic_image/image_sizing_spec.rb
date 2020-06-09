# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::ImageSizing do
  def crop_geometry(width, height)
    sizing.crop_geometry(v(width, height))
  end

  def v(width, height)
    Vector2d.new(width, height)
  end

  let(:real_size) { v(320, 200) }
  let(:crop_gravity) { nil }
  let(:crop_size) { real_size }
  let(:crop_start) { v(0, 0) }
  let(:sizing) { described_class.new(record) }
  let(:record) do
    Image.new(real_width: real_size.x,
              real_height: real_size.y,
              crop_gravity_x: crop_gravity&.x,
              crop_gravity_y: crop_gravity&.y,
              crop_width: crop_size.x,
              crop_height: crop_size.y,
              crop_start_x: crop_start.x,
              crop_start_y: crop_start.y)
  end

  describe "#crop_geometry_string" do
    subject { sizing.crop_geometry_string(v(200, 200)) }

    it { is_expected.to eq("200x200+60+0!") }
  end

  describe "#crop_geometry (uncropped image)" do
    subject { crop_geometry(200, 200) }

    context "when image isn't cropped" do
      let(:real_size) { v(321, 201) }

      it "crops horizontally" do
        expect(crop_geometry(200, 200)).to(eq([v(201, 201), v(60, 0)]))
      end

      it "crops vertically" do
        expect(crop_geometry(160, 50)).to(eq([v(321, 100), v(0, 50)]))
      end

      it "downscales when size is large" do
        expect(crop_geometry(600, 600)).to(eq([v(201, 201), v(60, 0)]))
      end
    end

    context "when crop gravity is top left" do
      let(:crop_gravity) { v(0, 0) }

      it { is_expected.to eq([v(200, 200), v(0, 0)]) }
    end

    context "when crop gravity is bottom real_height" do
      let(:crop_gravity) { v(320, 200) }

      it { is_expected.to eq([v(200, 200), v(120, 0)]) }
    end
  end

  describe "#crop_geometry (cropped image)" do
    subject { crop_geometry(200, 200) }

    let(:real_size) { v(521, 401) }
    let(:crop_size) { v(321, 201) }
    let(:crop_start) { v(10, 10) }

    context "when cropping horizontally" do
      it { is_expected.to eq([v(201, 201), v(70, 10)]) }
    end

    context "when cropping vertically" do
      subject { crop_geometry(160, 50) }

      it { is_expected.to eq([v(321, 100), v(10, 60)]) }
    end

    context "when cropping with top left gravity" do
      let(:crop_gravity) { v(0, 0) }

      it { is_expected.to eq([v(201, 201), v(10, 10)]) }
    end

    context "when cropping with bottom right gravity" do
      let(:crop_gravity) { v(320, 200) }

      it { is_expected.to eq([v(201, 201), v(130, 10)]) }
    end

    context "with crop start = zero" do
      let(:crop_start) { v(0, 0) }

      it { is_expected.to eq([v(201, 201), v(60, 0)]) }
    end

    context "with precropping disabled" do
      let(:sizing) { described_class.new(record, uncropped: true) }

      it { is_expected.to eq([v(401, 401), v(60, 0)]) }
    end
  end

  describe "#fit" do
    subject(:fit) { sizing.fit(size, options) }

    let(:options) { {} }
    let(:size) { v(100, 100) }

    context "with string argument, both dimensions" do
      let(:size) { "100x100" }

      it { is_expected.to eq(v(100, 62.5)) }
    end

    context "with string argument, only width" do
      let(:size) { "100x" }

      it { is_expected.to eq(v(100, 62.5)) }
    end

    context "with string argument, only height" do
      let(:size) { "x100" }

      it { is_expected.to eq(v(160, 100)) }
    end

    context "when fit_size is smaller" do
      it { is_expected.to eq(v(100, 62.5)) }
    end

    context "when fit_size is larger" do
      let(:size) { v(500, 500) }

      it { is_expected.to eq(v(320, 200)) }
    end

    context "when fit_size is smaller and crop: true" do
      let(:options) { { crop: true } }

      it { is_expected.to eq(v(100, 100)) }
    end

    context "with unspecified width and crop: true" do
      it "raises an error" do
        expect { sizing.fit(v(0, 100), crop: true) }.to(
          raise_error(DynamicImage::Errors::InvalidSizeOptions)
        )
      end
    end

    context "with unspecified height and crop: true" do
      it "raises an error" do
        expect { sizing.fit(v(100, 0), crop: true) }.to(
          raise_error(DynamicImage::Errors::InvalidSizeOptions)
        )
      end
    end

    context "when fit_size is larger and crop: true" do
      let(:options) { { crop: true } }
      let(:size) { v(500, 500) }

      it { is_expected.to eq(v(200, 200)) }
    end

    context "when fit_size is smaller and upscale: true" do
      let(:options) { { upscale: true } }

      it { is_expected.to eq(v(100, 62.5)) }
    end

    context "with only width and upscale: true" do
      let(:options) { { upscale: true } }
      let(:size) { v(400, 0) }

      it { is_expected.to eq(v(400, 250)) }
    end

    context "with only height and upscale: true" do
      let(:options) { { upscale: true } }
      let(:size) { v(0, 300) }

      it { is_expected.to eq(v(480, 300)) }
    end

    context "when fit_size is larger and upscale: true" do
      let(:options) { { upscale: true } }
      let(:size) { v(500, 500) }

      it { is_expected.to eq(v(500, 312.5)) }
    end

    context "with crop: true, upscale: true" do
      let(:options) { { crop: true, upscale: true } }
      let(:size) { v(500, 520) }

      it { is_expected.to eq(v(500, 520)) }
    end

    context "with a cropped image and normal sizing" do
      let(:size) { v(1000, 1000) }
      let(:real_size) { v(520, 500) }
      let(:crop_size) { v(320, 200) }
      let(:crop_start) { v(10, 10) }

      it { is_expected.to eq(v(320, 200)) }
    end

    context "with a cropped image and uncropped sizing" do
      let(:size) { v(1000, 1000) }
      let(:real_size) { v(520, 500) }
      let(:crop_size) { v(320, 200) }
      let(:crop_start) { v(10, 10) }
      let(:sizing) { described_class.new(record, uncropped: true) }

      it { is_expected.to eq(v(520, 500)) }
    end
  end
end
