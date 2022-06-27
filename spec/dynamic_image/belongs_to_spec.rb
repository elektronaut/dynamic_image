# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::BelongsTo do
  storage_root = Rails.root.join("tmp/spec")

  let(:file) do
    File.open(File.expand_path("../support/fixtures/image.png", __dir__))
  end
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, "image/png") }
  let(:image) { Image.create(file: uploaded_file) }

  after do
    FileUtils.rm_rf(storage_root)
  end

  describe "assignment" do
    subject { user.avatar }

    let(:user) { User.create(avatar: argument) }

    context "with nil" do
      let(:argument) { nil }

      it { is_expected.to be_nil }
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
