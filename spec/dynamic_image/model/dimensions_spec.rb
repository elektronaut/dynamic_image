require 'spec_helper'

describe DynamicImage::Model::Dimensions do
  let(:image) { Image.new }

  describe "#cropped?" do
    subject { image.cropped? }
    it { is_expected.to be false }

    context "when only real_size has been set" do
      let(:image) { Image.new(real_size: '320x200') }
      it { is_expected.to be false }
    end

    context "when crop_size equals real_size" do
      let(:image) { Image.new(real_size: '320x200', crop_size: '320x200') }
      it { is_expected.to be false }
    end

    context "when crop_size is different from real_size" do
      let(:image) { Image.new(real_size: '320x200', crop_size: '200x100') }
      it { is_expected.to be true }
    end
  end

  describe "#size" do
    subject { image.size }
    it { is_expected.to be nil }

    context "when only real_size has been set" do
      let(:image) { Image.new(real_size: '320x200') }
      it { is_expected.to eq('320x200') }
    end

    context "when only crop_size has been set" do
      let(:image) { Image.new(crop_size: '320x200') }
      it { is_expected.to eq('320x200') }
    end

    context "when image has been cropped" do
      let(:image) { Image.new(real_size: '320x200', crop_size: '200x100') }
      it { is_expected.to eq('200x100') }
    end
  end

  describe "#width" do
    subject { image.width }
    it { is_expected.to be nil }

    context "when only real_size has been set" do
      let(:image) { Image.new(real_size: '320x200') }
      it { is_expected.to eq(320) }
    end

    context "when only crop_size has been set" do
      let(:image) { Image.new(crop_size: '320x200') }
      it { is_expected.to eq(320) }
    end

    context "when image has been cropped" do
      let(:image) { Image.new(real_size: '320x200', crop_size: '200x100') }
      it { is_expected.to eq(200) }
    end
  end

  describe "#height" do
    subject { image.height }
    it { is_expected.to be nil }

    context "when only real_size has been set" do
      let(:image) { Image.new(real_size: '320x200') }
      it { is_expected.to eq(200) }
    end

    context "when only crop_size has been set" do
      let(:image) { Image.new(crop_size: '320x200') }
      it { is_expected.to eq(200) }
    end

    context "when image has been cropped" do
      let(:image) { Image.new(real_size: '320x200', crop_size: '200x100') }
      it { is_expected.to eq(100) }
    end
  end
end