require "spec_helper"

describe DynamicImage::Model::Validations do
  let(:file_path) { "../../../support/fixtures/image.png" }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.new }

  before { image.valid? }

  describe "colorspace" do
    subject { image.errors[:colorspace] }

    context "when not present" do
      it { is_expected.to include("can't be blank") }
    end

    context "when invalid" do
      let(:image) { Image.new(colorspace: "yuv") }
      it { is_expected.to include("is not included in the list") }
    end

    context "when valid" do
      let(:image) { Image.new(colorspace: "rgb") }
      it { is_expected.to eq([]) }
    end
  end

  describe "content_type" do
    subject { image.errors[:content_type] }

    context "when not present" do
      it { is_expected.to include("can't be blank") }
    end

    context "when invalid" do
      let(:image) { Image.new(content_type: "image/foo") }
      it { is_expected.to include("is not included in the list") }
    end

    context "when valid" do
      let(:image) { Image.new(content_type: "image/jpeg") }
      it { is_expected.to eq([]) }
    end
  end

  describe "content_length" do
    subject { image.errors[:content_length] }

    context "when not present" do
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(content_length: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(content_length: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "data" do
    subject { image.errors[:data] }

    context "when not present" do
      it { is_expected.to include("can't be blank") }
    end

    context "when not an image" do
      let(:image) { Image.new(data: "foo") }
      it { is_expected.to include("is invalid") }
    end

    context "when a valid image" do
      let(:image) { Image.new(data: uploaded_file) }
      it { is_expected.to eq([]) }
    end

    context "when a valid image has been saved previously" do
      let(:existing_image) { Image.create(file: uploaded_file) }
      let(:image) { Image.find(existing_image.id) }
      it { is_expected.to eq([]) }
    end
  end

  describe "real_width" do
    subject { image.errors[:real_width] }

    context "when not present" do
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(real_width: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(real_width: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "real_height" do
    subject { image.errors[:real_height] }

    context "when not present" do
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(real_height: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(real_height: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop_width" do
    subject { image.errors[:crop_width] }

    context "when not present" do
      it { is_expected.to eq([]) }
    end

    context "when crop_height is set" do
      let(:image) { Image.new(crop_height: 100) }
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(crop_width: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(crop_width: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop_height" do
    subject { image.errors[:crop_height] }

    context "when not present" do
      it { is_expected.to eq([]) }
    end

    context "when crop_width is set" do
      let(:image) { Image.new(crop_width: 100) }
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(crop_height: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(crop_height: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop_start_x" do
    subject { image.errors[:crop_start_x] }

    context "when not present" do
      it { is_expected.to eq([]) }
    end

    context "when crop_start_y is set" do
      let(:image) { Image.new(crop_start_y: 100) }
      it { is_expected.to include("can't be blank") }
    end

    context "when non-zero" do
      let(:image) { Image.new(crop_start_x: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop_start_y" do
    subject { image.errors[:crop_start_y] }

    context "when not present" do
      it { is_expected.to eq([]) }
    end

    context "when crop_start_x is set" do
      let(:image) { Image.new(crop_start_x: 100) }
      it { is_expected.to include("can't be blank") }
    end

    context "when non-zero" do
      let(:image) { Image.new(crop_start_y: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop_gravity_x" do
    subject { image.errors[:crop_gravity_x] }

    context "when not present" do
      it { is_expected.to eq([]) }
    end

    context "when crop_gravity_y is set" do
      let(:image) { Image.new(crop_gravity_y: 100) }
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(crop_gravity_x: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(crop_gravity_x: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop_gravity_y" do
    subject { image.errors[:crop_gravity_y] }

    context "when not present" do
      it { is_expected.to eq([]) }
    end

    context "when crop_gravity_x is set" do
      let(:image) { Image.new(crop_gravity_x: 100) }
      it { is_expected.to include("can't be blank") }
    end

    context "when zero" do
      let(:image) { Image.new(crop_gravity_y: 0) }
      it { is_expected.to include("must be greater than 0") }
    end

    context "when non-zero" do
      let(:image) { Image.new(crop_gravity_y: 2048) }
      it { is_expected.to eq([]) }
    end
  end

  describe "crop bounds" do
    subject { image.errors[:crop_size] }

    context "with no dimensions" do
      it { is_expected.to eq([]) }
    end

    context "when crop is not out of bounds" do
      let(:image) do
        Image.new(
          real_width: 10, real_height: 10,
          crop_width: 5, crop_height: 5,
          crop_start_x: 5, crop_start_y: 5
        )
      end
      it { is_expected.to eq([]) }
    end

    context "when crop is out of bounds" do
      let(:image) do
        Image.new(
          real_width: 10, real_height: 10,
          crop_width: 6, crop_height: 5,
          crop_start_x: 5, crop_start_y: 5
        )
      end
      it { is_expected.to include("is out of bounds") }
    end
  end
end
