# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Format do
  def find_format(name)
    described_class.find(name)
  end

  let(:format) { find_format("JPEG") }

  describe ".content_type" do
    subject { described_class.content_type("image/pjpeg") }

    it { is_expected.to eq(format) }
  end

  describe ".content_types" do
    subject { described_class.content_types }

    it { is_expected.to include("image/pjpeg") }
  end

  describe ".sniff" do
    subject { described_class.sniff(bytes) }

    context "when byte sequence has a valid header" do
      let(:bytes) { "\x4d\x4d\x00\x2a\x01\x02\x03\x04" }

      it { is_expected.to eq(find_format("TIFF")) }
    end

    context "when byte sequence is invalid" do
      let(:bytes) { "invalid" }

      it { is_expected.to be_nil }
    end

    context "when byte sequence is a non-WEBP RIFF container (e.g. WAV)" do
      let(:bytes) { "RIFF\x24\x00\x00\x00WAVEfmt ".b }

      it { is_expected.to be_nil }
    end

    context "when byte sequence is a valid WEBP header" do
      let(:bytes) { "RIFF\x24\x00\x00\x00WEBPVP8 ".b }

      it { is_expected.to eq(find_format("WEBP")) }
    end

    context "when byte sequence is RIFF but truncated below 12 bytes" do
      let(:bytes) { "RIFF\x24\x00\x00".b }

      it { is_expected.to be_nil }
    end
  end

  describe ".iso_brands" do
    subject { described_class.iso_brands(bytes) }

    context "when the header is an ftyp box" do
      let(:bytes) { "\x00\x00\x00\x1cftypavif\x00\x00\x00\x00mif1avifmiaf".b }

      it { is_expected.to eq(%w[avif mif1 avif miaf]) }
    end

    context "when the box ends before the compatible brands" do
      let(:bytes) { "\x00\x00\x00\x10ftypavif\x00\x00\x00\x00mif1avifmiaf".b }

      it { is_expected.to eq(%w[avif]) }
    end

    context "when the box claims to be longer than the header read" do
      let(:bytes) { "\x00\x00\xff\xffftypavif\x00\x00\x00\x00mif1".b }

      it { is_expected.to eq(%w[avif mif1]) }
    end

    context "when the header isn't an ftyp box" do
      let(:bytes) { "\x89PNG\r\n\x1a\n\x00\x00\x00\x0d".b }

      it { is_expected.to eq([]) }
    end

    context "when the header is truncated below 12 bytes" do
      let(:bytes) { "\x00\x00\x00\x1cftyp".b }

      it { is_expected.to eq([]) }
    end
  end

  describe "#matches?" do
    subject { described_class.new("TEST", offset: 4, magic_bytes: %w[ftyp]) }

    context "when the magic bytes sit at the offset" do
      it { is_expected.to be_matches("\x00\x00\x00\x1cftypavif".b) }
    end

    context "when the magic bytes sit elsewhere" do
      it { is_expected.not_to be_matches("ftyp\x00\x00\x00\x1cavif".b) }
    end

    context "when the header is shorter than the offset" do
      it { is_expected.not_to be_matches("\x00\x00".b) }
    end
  end

  describe "#content_type" do
    subject { format.content_type }

    it { is_expected.to eq("image/jpeg") }
  end

  describe "#extension" do
    subject { format.extension }

    it { is_expected.to eq(".jpg") }
  end

  describe "#alpha?" do
    context "when the format carries an alpha channel" do
      subject { find_format("PNG").alpha? }

      it { is_expected.to be(true) }
    end

    context "when the format carries no alpha channel" do
      subject { format.alpha? }

      it { is_expected.to be(false) }
    end
  end
end
