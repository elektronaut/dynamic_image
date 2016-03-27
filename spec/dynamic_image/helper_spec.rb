require 'spec_helper'

describe DynamicImage::Helper, type: :helper do
  def generate_digest(str)
    DynamicImage.digest_verifier.generate(str)
  end

  let(:file_path) { '../../support/fixtures/image.png' }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { 'image/png' }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) do
    Image.create(file: uploaded_file, filename: 'my-uploaded-file.png')
  end

  let(:host) { 'http://test.host' }

  describe '#dynamic_image_path' do
    subject { helper.dynamic_image_path(image, options) }
    let(:options) { { size: '100x100' } }
    let(:digest) { generate_digest("show-#{image.id}-100x62") }
    it { is_expected.to eq("/images/#{digest}/100x62/#{image.to_param}.png") }
  end

  describe '#dynamic_image_tag' do
    subject { helper.dynamic_image_tag(image, options) }

    context 'with size' do
      let(:options) { { size: '100x100' } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:path) { "/images/#{digest}/100x62/#{image.to_param}.png" }
      it do
        is_expected.to eq(
          "<img alt=\"My uploaded file\" src=\"#{path}\" width=\"100\" " \
            'height="62" />'
        )
      end
    end

    context 'with HTML options' do
      let(:options) { { size: '100x100', alt: 'Foobar', class: 'foo' } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:path) { "/images/#{digest}/100x62/#{image.to_param}.png" }
      it do
        is_expected.to eq(
          "<img alt=\"Foobar\" class=\"foo\" src=\"#{path}\" width=\"100\" " \
            'height="62" />'
        )
      end
    end

    context 'with url options' do
      let(:options) { { size: '100x100', routing_type: :url } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:path) { "/images/#{digest}/100x62/#{image.to_param}.png" }
      it do
        is_expected.to eq(
          "<img alt=\"My uploaded file\" src=\"#{host}#{path}\" " \
            'width="100" height="62" />'
        )
      end
    end
  end

  describe '#dynamic_image_url' do
    subject { helper.dynamic_image_url(image, options) }

    context 'with format' do
      let(:options) { { size: '100x100', format: :jpg } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      it do
        is_expected.to eq(
          "#{host}/images/#{digest}/100x62/#{image.to_param}.jpg"
        )
      end
    end

    context 'with size' do
      let(:options) { { size: '100x100' } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      it do
        is_expected.to eq(
          "#{host}/images/#{digest}/100x62/#{image.to_param}.png"
        )
      end
    end

    context 'without size' do
      let(:options) { {} }
      let(:digest) { generate_digest("show-#{image.id}-320x200") }
      it do
        is_expected.to eq(
          "#{host}/images/#{digest}/320x200/#{image.to_param}.png"
        )
      end
    end

    context 'with crop' do
      let(:options) { { size: '500x500', crop: true } }
      let(:digest) { generate_digest("show-#{image.id}-200x200") }
      it do
        is_expected.to eq(
          "#{host}/images/#{digest}/200x200/#{image.to_param}.png"
        )
      end
    end

    context 'with upscale' do
      let(:options) { { size: '500x500', upscale: true } }
      let(:digest) { generate_digest("show-#{image.id}-500x312") }
      it do
        is_expected.to eq(
          "#{host}/images/#{digest}/500x312/#{image.to_param}.png"
        )
      end
    end
  end

  describe '#original_dynamic_image_path' do
    let(:options) { {} }
    let(:digest) { generate_digest("original-#{image.id}-320x200") }
    subject { helper.original_dynamic_image_path(image, options) }
    it do
      is_expected.to eq(
        "/images/#{digest}/320x200/#{image.to_param}/original.png"
      )
    end
  end

  describe '#original_dynamic_image_url' do
    let(:options) { {} }
    let(:digest) { generate_digest("original-#{image.id}-320x200") }
    subject { helper.original_dynamic_image_url(image, options) }
    it do
      is_expected.to eq(
        "#{host}/images/#{digest}/320x200/#{image.to_param}/original.png"
      )
    end
  end

  describe '#uncropped_dynamic_image_path' do
    let(:options) { { size: '100x100' } }
    let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }
    subject { helper.uncropped_dynamic_image_path(image, options) }
    it do
      is_expected.to eq(
        "/images/#{digest}/100x62/#{image.to_param}/uncropped.png"
      )
    end
  end

  describe '#uncropped_dynamic_image_tag' do
    subject { helper.uncropped_dynamic_image_tag(image, options) }
    let(:options) { { size: '100x100' } }
    let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }
    let(:path) { "/images/#{digest}/100x62/#{image.to_param}/uncropped.png" }
    it do
      is_expected.to eq(
        "<img alt=\"My uploaded file\" src=\"#{path}\" width=\"100\" " \
          'height="62" />'
      )
    end
  end

  describe '#uncropped_dynamic_image_url' do
    let(:options) { { size: '100x100' } }
    let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }
    subject { helper.uncropped_dynamic_image_url(image, options) }
    it do
      is_expected.to eq(
        "#{host}/images/#{digest}/100x62/#{image.to_param}/uncropped.png"
      )
    end
  end
end
