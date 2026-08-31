# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Helper, type: :helper do
  def generate_digest(str)
    DynamicImage.digest_verifier.generate(str)
  end

  let(:image) do
    Image.create(
      file: Rack::Test::UploadedFile.new(
        File.open(File.expand_path("../support/fixtures/image.png", __dir__)),
        "image/png"
      ),
      filename: "my-uploaded-file.png"
    )
  end

  let(:host) { "http://test.host" }

  describe "#dynamic_image_path" do
    subject { helper.dynamic_image_path(image, options) }

    let(:options) { { size: "100x100" } }
    let(:digest) { generate_digest("show-#{image.id}-100x62") }

    it { is_expected.to eq("/images/#{digest}/100x62/#{image.to_param}.png") }
  end

  describe "#dynamic_image_tag" do
    subject(:tag) { helper.dynamic_image_tag(image, options) }

    context "with size" do
      let(:options) { { size: "100x100" } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:path) { "/images/#{digest}/100x62/#{image.to_param}.png" }

      it do
        expect(tag).to eq(
          "<img src=\"#{path}\" width=\"100\" height=\"62\" />"
        )
      end
    end

    context "with HTML options" do
      let(:options) { { size: "100x100", alt: "Foobar", class: "foo" } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:path) { "/images/#{digest}/100x62/#{image.to_param}.png" }

      it do
        expect(tag).to eq(
          "<img alt=\"Foobar\" class=\"foo\" src=\"#{path}\" width=\"100\" " \
          'height="62" />'
        )
      end
    end

    context "with url options" do
      let(:options) { { size: "100x100", routing_type: :url } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:path) { "/images/#{digest}/100x62/#{image.to_param}.png" }

      it do
        expect(tag).to eq(
          "<img src=\"#{host}#{path}\" width=\"100\" height=\"62\" />"
        )
      end
    end
  end

  describe "rendering in a mailer" do
    subject(:body) { ImageMailer.image(image).body.to_s }

    it "builds an absolute URL, since mailer views have no path helpers" do
      expect(body).to include(%(src="#{host}/images/))
    end
  end

  describe "#dynamic_image_url" do
    subject(:url) { helper.dynamic_image_url(image, options) }

    context "with format" do
      let(:options) { { size: "100x100", format: :jpg } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/100x62/#{image.to_param}.jpg"
        )
      end
    end

    context "with an array of formats the source is in" do
      let(:options) { { size: "100x100", format: %i[jpeg png gif] } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/100x62/#{image.to_param}.png"
        )
      end
    end

    context "with an array of formats the source isn't in" do
      let(:options) { { size: "100x100", format: %i[jpeg png gif] } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }
      let(:image) do
        Image.create(
          file: Rack::Test::UploadedFile.new(
            File.open(
              File.expand_path("../support/fixtures/transparent.webp", __dir__)
            ),
            "image/webp"
          ),
          filename: "my-uploaded-file.webp"
        )
      end

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/100x62/#{image.to_param}.png"
        )
      end
    end

    context "with size" do
      let(:options) { { size: "100x100" } }
      let(:digest) { generate_digest("show-#{image.id}-100x62") }

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/100x62/#{image.to_param}.png"
        )
      end
    end

    context "without size" do
      let(:options) { {} }
      let(:digest) { generate_digest("show-#{image.id}-320x200") }

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/320x200/#{image.to_param}.png"
        )
      end
    end

    context "with crop" do
      let(:options) { { size: "500x500", crop: true } }
      let(:digest) { generate_digest("show-#{image.id}-200x200") }

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/200x200/#{image.to_param}.png"
        )
      end
    end

    context "with upscale" do
      let(:options) { { size: "500x500", upscale: true } }
      let(:digest) { generate_digest("show-#{image.id}-500x312") }

      it do
        expect(url).to eq(
          "#{host}/images/#{digest}/500x312/#{image.to_param}.png"
        )
      end
    end
  end

  describe "#original_dynamic_image_path" do
    subject(:path) { helper.original_dynamic_image_path(image, options) }

    let(:options) { {} }
    let(:digest) { generate_digest("original-#{image.id}-320x200") }

    it do
      expect(path).to eq(
        "/images/#{digest}/320x200/#{image.to_param}/original.png"
      )
    end
  end

  describe "#original_dynamic_image_url" do
    subject(:url) { helper.original_dynamic_image_url(image, options) }

    let(:options) { {} }
    let(:digest) { generate_digest("original-#{image.id}-320x200") }

    it do
      expect(url).to eq(
        "#{host}/images/#{digest}/320x200/#{image.to_param}/original.png"
      )
    end
  end

  describe "#download_dynamic_image_path" do
    subject(:path) { helper.download_dynamic_image_path(image, options) }

    let(:options) { {} }
    let(:digest) { generate_digest("download-#{image.id}-320x200") }

    it do
      expect(path).to eq(
        "/images/#{digest}/320x200/#{image.to_param}/download.png"
      )
    end
  end

  describe "#download_dynamic_image_url" do
    subject(:url) { helper.download_dynamic_image_url(image, options) }

    let(:options) { {} }
    let(:digest) { generate_digest("download-#{image.id}-320x200") }

    it do
      expect(url).to eq(
        "#{host}/images/#{digest}/320x200/#{image.to_param}/download.png"
      )
    end
  end

  describe "#uncropped_dynamic_image_path" do
    subject(:path) { helper.uncropped_dynamic_image_path(image, options) }

    let(:options) { { size: "100x100" } }
    let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }

    it do
      expect(path).to eq(
        "/images/#{digest}/100x62/#{image.to_param}/uncropped.png"
      )
    end
  end

  describe "#uncropped_dynamic_image_tag" do
    subject(:tag) { helper.uncropped_dynamic_image_tag(image, options) }

    let(:options) { { size: "100x100" } }
    let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }
    let(:path) { "/images/#{digest}/100x62/#{image.to_param}/uncropped.png" }

    it do
      expect(tag).to eq(
        "<img src=\"#{path}\" width=\"100\" height=\"62\" />"
      )
    end
  end

  describe "#uncropped_dynamic_image_url" do
    subject(:url) { helper.uncropped_dynamic_image_url(image, options) }

    let(:options) { { size: "100x100" } }
    let(:digest) { generate_digest("uncropped-#{image.id}-100x62") }

    it do
      expect(url).to eq(
        "#{host}/images/#{digest}/100x62/#{image.to_param}/uncropped.png"
      )
    end
  end
end
