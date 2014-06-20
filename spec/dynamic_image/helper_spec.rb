require 'spec_helper'

describe DynamicImage::Helper, type: :helper do
  storage_root = Rails.root.join('tmp', 'spec')

  def generate_digest(str)
    DynamicImage.digest_verifier.generate(str)
  end

  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.create(file: uploaded_file) }

  let(:host) { "http://test.host" }

  before(:all) do
    Shrouded::Storage.layers << Shrouded::Layer.new(Fog::Storage.new({provider: 'Local', local_root: storage_root}))
  end

  after do
    FileUtils.rm_rf(storage_root) if File.exists?(storage_root)
  end

  after(:all) do
    Shrouded::Storage.layers.clear!
  end

  describe "#dynamic_image_path" do
    subject { helper.dynamic_image_path(image, options) }
    let(:options) { { size: '100x100' } }
    let(:digest) { generate_digest("show-#{image.id}-100x62") }
    it { is_expected.to eq("/images/#{digest}/100x62/#{image.to_param}.png") }
  end

  describe "#dynamic_image_url" do
    subject { helper.dynamic_image_url(image, options) }

    context "with uncropped action" do
      subject { helper.dynamic_image_url(image, options) }
      let(:options) { { size: '100x100', action: :uncropped } }
      let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }
      it { is_expected.to eq("#{host}/images/#{digest}/100x62/#{image.to_param}/uncropped.png") }
    end

    context "with original action" do
      subject { helper.dynamic_image_url(image, options) }
      let(:options) { { action: :original } }
      let(:digest) { generate_digest("original-#{image.id}") }
      it { is_expected.to eq("#{host}/images/#{digest}/#{image.to_param}/original.png") }
    end

    context "with format" do
      let(:options) { { size: '100x100', format: :jpg } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      it { is_expected.to eq("#{host}/images/#{digest}/100x62/#{image.to_param}.jpg") }
    end

    context "without crop and upscale" do
      context "with both dimensions" do
        let(:options) { { size: '100x100' } }
        let(:digest) { generate_digest("show-#{image.id}-100x62") }
        it { is_expected.to eq("#{host}/images/#{digest}/100x62/#{image.to_param}.png") }
      end

      context "with only width" do
        let(:options) { { size: '100x' } }
        let(:digest) { generate_digest("show-#{image.id}-100x62") }
        it { is_expected.to eq("#{host}/images/#{digest}/100x62/#{image.to_param}.png") }
      end

      context "with only height" do
        let(:options) { { size: 'x100' } }
        let(:digest) { generate_digest("show-#{image.id}-160x100") }
        it { is_expected.to eq("#{host}/images/#{digest}/160x100/#{image.to_param}.png") }
      end

      context "with size larger than image" do
        let(:options) { { size: '500x500' } }
        let(:digest) { generate_digest("show-#{image.id}-320x200") }
        it { is_expected.to eq("#{host}/images/#{digest}/320x200/#{image.to_param}.png") }
      end
    end

    context "with crop" do
      context "and both dimensions" do
        let(:options) { { size: '100x100', crop: true } }
        let(:digest) { generate_digest("show-#{image.id}-100x100") }
        it { is_expected.to eq("#{host}/images/#{digest}/100x100/#{image.to_param}.png") }
      end

      context "with only width" do
        let(:options) { { size: '100x', crop: true } }
        it "should raise an error" do
          expect { subject }.to raise_error(DynamicImage::Errors::InvalidSizeOptions)
        end
      end

      context "with only height" do
        let(:options) { { size: 'x100', crop: true } }
        it "should raise an error" do
          expect { subject }.to raise_error(DynamicImage::Errors::InvalidSizeOptions)
        end
      end

      context "and size larger than image" do
        let(:options) { { size: '500x500', crop: true } }
        let(:digest) { generate_digest("show-#{image.id}-200x200") }
        it { is_expected.to eq("#{host}/images/#{digest}/200x200/#{image.to_param}.png") }
      end
    end

    context "with upscale" do
      context "with both dimensions" do
        let(:options) { { size: '100x100', upscale: true } }
        let(:digest) { generate_digest("show-#{image.id}-100x62") }
        it { is_expected.to eq("#{host}/images/#{digest}/100x62/#{image.to_param}.png") }
      end

      context "with only width" do
        let(:options) { { size: '400x', upscale: true } }
        let(:digest) { generate_digest("show-#{image.id}-400x250") }
        it { is_expected.to eq("#{host}/images/#{digest}/400x250/#{image.to_param}.png") }
      end

      context "with only height" do
        let(:options) { { size: 'x300', upscale: true } }
        let(:digest) { generate_digest("show-#{image.id}-480x300") }
        it { is_expected.to eq("#{host}/images/#{digest}/480x300/#{image.to_param}.png") }
      end

      context "with size larger than image" do
        let(:options) { { size: '500x500', upscale: true } }
        let(:digest) { generate_digest("show-#{image.id}-500x312") }
        it { is_expected.to eq("#{host}/images/#{digest}/500x312/#{image.to_param}.png") }
      end
    end

    context "with upscale and crop" do
      let(:options) { { size: '500x500', upscale: true, crop: true } }
      let(:digest) { generate_digest("show-#{image.id}-500x500") }
      it { is_expected.to eq("#{host}/images/#{digest}/500x500/#{image.to_param}.png") }
    end
  end
end