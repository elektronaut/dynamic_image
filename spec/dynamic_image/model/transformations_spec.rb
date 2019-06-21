# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Model::Transformations do
  let(:file_path) { "../../../support/fixtures/image.png" }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) do
    Image.new(file: uploaded_file,
              crop_width: 40,
              crop_height: 30,
              crop_start_x: 20,
              crop_start_y: 10,
              crop_gravity_x: 50,
              crop_gravity_y: 60)
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
  end

  describe "#rotate" do
    subject(:rotated) do
      image.rotate(degrees)
    end

    let(:degrees) { 90 }
    let(:real_size) { rotated.real_size }
    let(:crop_size) { rotated.crop_size }
    let(:crop_start) { rotated.crop_start }
    let(:crop_gravity) { rotated.crop_gravity }

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
        expect(real_size).to eq(Vector2d.new(200, 320))
      end

      it "adjusts the crop size" do
        expect(crop_size).to eq(Vector2d.new(30, 40))
      end

      it "adjusts the crop start" do
        expect(crop_start).to eq(Vector2d.new(160, 20))
      end

      it "adjusts the crop gravity" do
        expect(crop_gravity).to eq(Vector2d.new(140, 50))
      end
    end

    context "with a 180 degree rotation" do
      let(:degrees) { 180 }

      it "keeps the image size" do
        expect(real_size).to eq(Vector2d.new(320, 200))
      end

      it "keeps the crop size" do
        expect(crop_size).to eq(Vector2d.new(40, 30))
      end

      it "adjusts the crop start" do
        expect(crop_start).to eq(Vector2d.new(260, 160))
      end

      it "adjusts the crop gravity" do
        expect(crop_gravity).to eq(Vector2d.new(270, 140))
      end
    end

    context "with a -90 degree rotation" do
      let(:degrees) { -90 }

      it "rotates the image" do
        expect(real_size).to eq(Vector2d.new(200, 320))
      end

      it "adjusts the crop size" do
        expect(crop_size).to eq(Vector2d.new(30, 40))
      end

      it "adjusts the crop start" do
        expect(crop_start).to eq(Vector2d.new(10, 260))
      end

      it "adjusts the crop gravity" do
        expect(crop_gravity).to eq(Vector2d.new(60, 270))
      end
    end
  end
end
