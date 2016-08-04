require "spec_helper"

describe DynamicImage::Model::Dimensions do
  let(:image) { Image.new }

  describe "#crop_gravity" do
    subject { image.crop_gravity }

    context "with no dimensions" do
      it { is_expected.to be nil }
    end

    context "when only real_size is set" do
      let(:image) { Image.new(real_width: 321, real_height: 201) }
      it { is_expected.to eq(Vector2d.new(160, 100)) }
    end

    context "when image is cropped" do
      let(:image) do
        Image.new(
          real_width: 320,
          real_height: 200,
          crop_width: 12,
          crop_height: 11,
          crop_start_x: 12,
          crop_start_y: 11
        )
      end
      it { is_expected.to eq(Vector2d.new(18, 16)) }
    end

    context "when gravity is set" do
      let(:image) do
        Image.new(
          crop_gravity_x: 200,
          crop_gravity_y: 100,
          real_width: 320,
          real_height: 200
        )
      end
      it { is_expected.to eq(Vector2d.new(200, 100)) }
    end
  end

  describe "#crop_gravity?" do
    subject { image.crop_gravity? }
    context "with no dimensions" do
      it { is_expected.to be false }
    end

    context "with one dimensions" do
      let(:image) { Image.new(crop_gravity_x: 320) }
      it { is_expected.to be false }
    end

    context "with both dimensions" do
      let(:image) { Image.new(crop_gravity_x: 320, crop_gravity_y: 200) }
      it { is_expected.to be true }
    end

    context "when gravity is zero" do
      let(:image) { Image.new(crop_gravity_x: 0, crop_gravity_y: 0) }
      it { is_expected.to be true }
    end
  end

  describe "#crop_size" do
    subject { image.crop_size }

    context "with no dimensions" do
      it { is_expected.to be nil }
    end

    context "with dimensions" do
      let(:image) { Image.new(crop_width: 320, crop_height: 200) }
      it { is_expected.to eq(Vector2d.new(320, 200)) }
    end
  end

  describe "#crop_size?" do
    subject { image.crop_size? }
    context "with no dimensions" do
      it { is_expected.to be false }
    end

    context "with one dimensions" do
      let(:image) { Image.new(crop_width: 320) }
      it { is_expected.to be false }
    end

    context "with both dimensions" do
      let(:image) { Image.new(crop_width: 320, crop_height: 200) }
      it { is_expected.to be true }
    end
  end

  describe "#crop_start" do
    subject { image.crop_start }

    context "with no dimensions" do
      it { is_expected.to eq(Vector2d.new(0, 0)) }
    end

    context "with dimensions" do
      let(:image) { Image.new(crop_start_x: 320, crop_start_y: 200) }
      it { is_expected.to eq(Vector2d.new(320, 200)) }
    end
  end

  describe "#crop_start?" do
    subject { image.crop_start? }
    context "with no dimensions" do
      it { is_expected.to be false }
    end

    context "with one dimensions" do
      let(:image) { Image.new(crop_start_x: 320) }
      it { is_expected.to be false }
    end

    context "with both dimensions" do
      let(:image) { Image.new(crop_start_x: 320, crop_start_y: 200) }
      it { is_expected.to be true }
    end
  end

  describe "#cropped?" do
    subject { image.cropped? }

    context "with no dimensions" do
      it { is_expected.to be false }
    end

    context "when only crop_size is set" do
      let(:image) { Image.new(crop_width: 320, crop_height: 200) }
      it { is_expected.to be false }
    end

    context "when only real_size is set" do
      let(:image) { Image.new(real_width: 320, real_height: 200) }
      it { is_expected.to be false }
    end

    context "crop_size and real_size is set" do
      let(:image) do
        Image.new(
          crop_width: 200,
          crop_height: 100,
          real_width: 320,
          real_height: 200
        )
      end
      it { is_expected.to be true }
    end

    context "crop_size and real_size are the same" do
      let(:image) do
        Image.new(
          crop_width: 320,
          crop_height: 200,
          real_width: 320,
          real_height: 200
        )
      end
      it { is_expected.to be false }
    end
  end

  describe "#real_size" do
    subject { image.real_size }

    context "with no dimensions" do
      it { is_expected.to be nil }
    end

    context "with dimensions" do
      let(:image) { Image.new(real_width: 320, real_height: 200) }
      it { is_expected.to eq(Vector2d.new(320, 200)) }
    end
  end

  describe "#real_size?" do
    subject { image.real_size? }
    context "with no dimensions" do
      it { is_expected.to be false }
    end

    context "with one dimensions" do
      let(:image) { Image.new(real_width: 320) }
      it { is_expected.to be false }
    end

    context "with both dimensions" do
      let(:image) { Image.new(real_width: 320, real_height: 200) }
      it { is_expected.to be true }
    end
  end

  describe "#size" do
    subject { image.size }

    context "with no dimensions" do
      it { is_expected.to be nil }
    end

    context "when not cropped" do
      let(:image) { Image.new(real_width: 320, real_height: 200) }
      it { is_expected.to eq(Vector2d.new(320, 200)) }
    end

    context "when cropped" do
      let(:image) do
        Image.new(
          real_width: 320,
          real_height: 200,
          crop_width: 100,
          crop_height: 80
        )
      end
      it { is_expected.to eq(Vector2d.new(100, 80)) }
    end
  end

  describe "#size?" do
    subject { image.size? }

    context "with no dimensions" do
      it { is_expected.to be false }
    end

    context "with size" do
      let(:image) { Image.new(real_width: 320, real_height: 200) }
      it { is_expected.to be true }
    end
  end
end
