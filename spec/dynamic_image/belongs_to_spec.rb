require 'spec_helper'

describe DynamicImage::BelongsTo do
  storage_root = Rails.root.join('tmp', 'spec')

  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }
  let(:image) { Image.create(file: uploaded_file) }

  after do
    FileUtils.rm_rf(storage_root) if File.exists?(storage_root)
  end

  describe "assignment" do
    let(:user) { User.create(avatar: argument) }
    subject { user.avatar }

    context "with nil" do
      let(:argument) { nil }
      it { is_expected.to be nil }
    end

    context "with an existing image" do
      let(:argument) { image }
      it { is_expected.to be_valid }
      it { is_expected.to eq(image) }
    end

    context "with an uploaded file" do
      let(:argument) { uploaded_file }
      it { is_expected.to be_valid }
      it { is_expected.to be_a(DynamicImage::Model) }
    end
  end
end