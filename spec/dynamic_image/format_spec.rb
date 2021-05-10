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

      it { is_expected.to eq(nil) }
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
end
