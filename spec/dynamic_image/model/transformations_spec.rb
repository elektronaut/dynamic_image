# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Model::Transformations do
  let(:image) { Image.new(file:, **crop) }

  let(:file) do
    Rack::Test::UploadedFile.new(
      File.open(File.expand_path("../../support/fixtures/image.png", __dir__)),
      "image/png"
    )
  end

  let(:crop) do
    { crop_width: 40, crop_height: 30,
      crop_start_x: 20, crop_start_y: 10,
      crop_gravity_x: 50, crop_gravity_y: 60 }
  end

  describe "#resize" do
    subject(:resized) { image.resize("160x160") }

    it "resizes the image" do
      expect(resized.real_size).to eq(Vector2d(160, 100))
    end

    it "adjusts the crop size" do
      expect(resized.crop_size).to eq(Vector2d(20, 15))
    end

    it "adjusts the crop start" do
      expect(resized.crop_start).to eq(Vector2d(10, 5))
    end

    it "adjusts the crop gravity" do
      expect(resized.crop_gravity).to eq(Vector2d(25, 30))
    end

    it { is_expected.to be_valid }

    it "stores the crop as integers" do
      expect(
        crop.keys.map { |attr| resized.send(:"#{attr}_before_type_cast") }
      ).to all(be_an(Integer))
    end

    context "when the crop is against the edge" do
      let(:crop) do
        { crop_width: 320, crop_height: 5,
          crop_start_x: 0, crop_start_y: 195 }
      end

      it { is_expected.to be_valid }

      it "keeps the crop within the image" do
        expect(resized.crop_start + resized.crop_size).to eq(Vector2d(160, 100))
      end
    end

    context "when the crop rounds down to nothing" do
      subject(:resized) { image.resize("16x16") }

      let(:crop) do
        { crop_width: 2, crop_height: 2,
          crop_start_x: 0, crop_start_y: 0,
          crop_gravity_x: 1, crop_gravity_y: 1 }
      end

      it { is_expected.to be_valid }

      it "keeps a one pixel crop" do
        expect(resized.crop_size).to eq(Vector2d(1, 1))
      end

      it "keeps the crop gravity within the image" do
        expect(resized.crop_gravity).to eq(Vector2d(1, 1))
      end
    end
  end

  describe "#rotate" do
    subject(:rotated) do
      image.rotate(degrees)
    end

    let(:degrees) { 90 }

    it { is_expected.to eq(image) }

    context "with an invalid angle" do
      it "raises an error" do
        expect { image.rotate(45) }.to(
          raise_error(DynamicImage::Errors::InvalidTransformation)
        )
      end
    end

    context "with a 90 degree rotation" do
      it "rotates the image" do
        expect(rotated.real_size).to eq(Vector2d.new(200, 320))
      end

      it "adjusts the crop size" do
        expect(rotated.crop_size).to eq(Vector2d.new(30, 40))
      end

      it "adjusts the crop start" do
        expect(rotated.crop_start).to eq(Vector2d.new(160, 20))
      end

      it "adjusts the crop gravity" do
        expect(rotated.crop_gravity).to eq(Vector2d.new(140, 50))
      end
    end

    context "with a 180 degree rotation" do
      let(:degrees) { 180 }

      it "keeps the image size" do
        expect(rotated.real_size).to eq(Vector2d.new(320, 200))
      end

      it "keeps the crop size" do
        expect(rotated.crop_size).to eq(Vector2d.new(40, 30))
      end

      it "adjusts the crop start" do
        expect(rotated.crop_start).to eq(Vector2d.new(260, 160))
      end

      it "adjusts the crop gravity" do
        expect(rotated.crop_gravity).to eq(Vector2d.new(270, 140))
      end
    end

    context "with a -90 degree rotation" do
      let(:degrees) { -90 }

      it "rotates the image" do
        expect(rotated.real_size).to eq(Vector2d.new(200, 320))
      end

      it "adjusts the crop size" do
        expect(rotated.crop_size).to eq(Vector2d.new(30, 40))
      end

      it "adjusts the crop start" do
        expect(rotated.crop_start).to eq(Vector2d.new(10, 260))
      end

      it "adjusts the crop gravity" do
        expect(rotated.crop_gravity).to eq(Vector2d.new(60, 270))
      end
    end
  end
end
