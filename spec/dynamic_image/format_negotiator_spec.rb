# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::FormatNegotiator do
  subject(:negotiated) { described_class.new(image).negotiate(accepted) }

  let(:image) do
    Image.new(content_type: "image/webp", frame_count: 1, alpha: false)
  end

  let(:accepted) { %i[jpeg png gif] }

  def find_format(name)
    DynamicImage::Format.find(name)
  end

  context "when the source format is accepted" do
    let(:image) { Image.new(content_type: "image/png", alpha: true) }

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when the source format is accepted and listed last" do
    let(:accepted) { %i[gif png jpeg] }
    let(:image) { Image.new(content_type: "image/jpeg", frame_count: 1) }

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when the source is a still, opaque WebP" do
    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when the source is a still, transparent WebP" do
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 1, alpha: true)
    end

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when the source is an animated WebP" do
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 3, alpha: true)
    end

    it { is_expected.to eq(find_format("GIF")) }
  end

  context "when animation can't be kept" do
    let(:accepted) { %i[jpeg png] }
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 3, alpha: true)
    end

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when neither animation nor alpha can be kept" do
    let(:accepted) { %i[jpeg] }
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 3, alpha: true)
    end

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when the preferred format already fits" do
    let(:accepted) { %i[png jpeg gif] }
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 1, alpha: true)
    end

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when a still, opaque image is listed after a capable format" do
    let(:accepted) { %i[png jpeg] }

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when the metadata hasn't been backfilled" do
    let(:image) { Image.new(content_type: "image/webp") }

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when only the frame count is known" do
    let(:image) { Image.new(content_type: "image/webp", frame_count: 3) }

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when the table predates the metadata columns" do
    let(:image) { LegacyImage.new(content_type: "image/webp") }

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when the accepted list is empty" do
    let(:accepted) { [] }

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when JPEG XL is accepted for a transparent image" do
    let(:accepted) { %i[jpeg jxl] }
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 1, alpha: true)
    end

    it { is_expected.to eq(find_format("JXL")) }
  end

  context "when JPEG XL is accepted for an animated image" do
    let(:accepted) { %i[jxl gif] }
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 3, alpha: false)
    end

    it { is_expected.to eq(find_format("GIF")) }
  end

  context "when the source is an opaque AVIF" do
    let(:image) do
      Image.new(content_type: "image/avif", frame_count: 1, alpha: false)
    end

    it { is_expected.to eq(find_format("JPEG")) }
  end

  context "when the source is a transparent AVIF" do
    let(:image) do
      Image.new(content_type: "image/avif", frame_count: 1, alpha: true)
    end

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when the accepted list holds unknown names" do
    let(:accepted) { %i[svg png] }
    let(:image) do
      Image.new(content_type: "image/webp", frame_count: 1, alpha: true)
    end

    it { is_expected.to eq(find_format("PNG")) }
  end

  context "when the accepted list is a single symbol" do
    let(:accepted) { :png }

    it { is_expected.to eq(find_format("PNG")) }
  end
end
