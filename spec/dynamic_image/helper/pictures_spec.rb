# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Helper::Pictures, type: :helper do
  def fixture(name, content_type)
    Rack::Test::UploadedFile.new(
      File.open(File.expand_path("../../support/fixtures/#{name}", __dir__)),
      content_type
    )
  end

  # 320x200
  let(:image) { Image.create(file: fixture("image.png", "image/png")) }

  describe "#dynamic_picture" do
    subject(:picture) { helper.dynamic_picture(image, ratio: "16:9") }

    it { is_expected.to be_a(DynamicImage::Picture) }

    it "passes the options on" do
      expect(picture.ratio).to be_within(0.001).of(1.7778)
    end

    it "keeps HTML attributes away from the router" do
      expect(helper.dynamic_picture(image, alt: "Kitten", class: "photo").src)
        .not_to include("alt")
    end
  end

  describe "#dynamic_picture_tag" do
    subject(:markup) { helper.dynamic_picture_tag(image, options) }

    let(:options) { { breakpoints: 100..320 } }

    it "wraps a source and an image" do
      expect(markup).to match(%r{\A<picture><source .+><img .+ /></picture>\z})
    end

    it "offers WebP" do
      expect(markup).to include('type="image/webp"')
    end

    it "falls back to a format everything understands" do
      expect(markup).to match(/<img src="[^"]+\.png"/)
    end

    it "defaults sizes to the full viewport" do
      expect(markup).to include('sizes="100vw"')
    end

    it "takes a sizes attribute" do
      expect(helper.dynamic_picture_tag(image, sizes: "50vw"))
        .to include('sizes="50vw"')
    end

    it "gives the image its dimensions, so the layout can reserve space" do
      expect(markup).to include('width="320" height="200"')
    end

    it "passes HTML attributes to the image" do
      expect(helper.dynamic_picture_tag(image, alt: "A kitten"))
        .to include('<img alt="A kitten"')
    end

    it "puts nothing but the source and the image inside the wrapper" do
      expect(markup.scan("<img").length).to eq(1)
    end

    context "with a ratio" do
      let(:options) { { ratio: "16:9", fallback_width: 160 } }

      it "crops the fallback to it" do
        expect(markup).to include('width="160" height="90"')
      end

      it "crops the candidates to it" do
        expect(markup).to match(%r{srcset="[^"]*/320x180/})
      end
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.gif", "image/gif")) }
      let(:options) { {} }

      it "needs no picture element, having nothing to negotiate" do
        expect(markup).to start_with("<img ")
      end

      it "keeps the stored format" do
        expect(markup).to match(/src="[^"]+\.gif"/)
      end

      it "carries the candidates on the img itself" do
        expect(markup).to match(/<img srcset="[^"]+\.gif 320w" sizes="100vw"/)
      end
    end
  end

  describe "#dynamic_picture_source_tag" do
    subject(:markup) { helper.dynamic_picture_source_tag(image, options) }

    let(:options) { { ratio: "21:9", media: "(min-width: 1000px)" } }

    it "renders a source" do
      expect(markup).to start_with("<source ")
    end

    it "carries the media query" do
      expect(markup).to include('media="(min-width: 1000px)"')
    end

    it "defaults to WebP" do
      expect(markup).to include('type="image/webp"')
    end

    context "with a list of formats" do
      let(:options) do
        { ratio: "21:9", format: DynamicImage::COMPATIBLE_FORMATS }
      end

      it "advertises the format it resolved to, not the one asked for" do
        expect(markup).to include('type="image/png"')
      end

      it "renders the candidates in that format" do
        expect(markup).to match(/srcset="[^"]+\.png /)
      end
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.gif", "image/gif")) }
      let(:options) { { media: "(min-width: 600px)" } }

      it "still composes, in the stored format" do
        expect(markup).to include('type="image/gif"')
      end
    end
  end

  describe "composing a picture by hand" do
    subject(:markup) do
      helper.tag.picture do
        helper.safe_join(
          [helper.dynamic_picture_source_tag(
            image, ratio: "21:9", media: "(min-width: 600px)"
          ),
           helper.dynamic_picture_source_tag(image, ratio: "1:1"),
           helper.dynamic_image_tag(image, size: "320x320", crop: true)]
        )
      end
    end

    it "renders both sources and the image" do
      expect([markup.scan("<source").length, markup.scan("<img").length])
        .to eq([2, 1])
    end

    it "keeps the media scoped source ahead of the unconditional one" do
      expect(markup.index("min-width")).to be < markup.index("<source", 20)
    end
  end
end
