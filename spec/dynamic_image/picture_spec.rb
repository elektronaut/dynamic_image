# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Picture, type: :helper do
  subject(:picture) { described_class.new(helper, image, options) }

  def fixture(name, content_type)
    Rack::Test::UploadedFile.new(
      File.open(File.expand_path("../support/fixtures/#{name}", __dir__)),
      content_type
    )
  end

  # The controller rejects any URL whose digest doesn't match the
  # action, the record and the size, so this is what proves a generated
  # URL will actually be served.
  matcher :be_signed_for do |record|
    match do |url|
      digest, size = url.split("/")[2, 2]
      DynamicImage.digest_verifier.verify("show-#{record.id}-#{size}", digest)
    rescue DynamicImage::Errors::InvalidSignature
      false
    end
  end

  # 320x200
  let(:image) { Image.create(file: fixture("image.png", "image/png")) }
  let(:options) { { breakpoints: 100..320, step: 1.4 } }

  describe "#widths" do
    it "steps down from the image's own width" do
      expect(picture.widths).to eq([110, 160, 220, 320])
    end

    context "with a ratio" do
      let(:options) { { ratio: "16:9", breakpoints: 100..320, step: 1.4 } }

      it "steps down from the widest crop matching the ratio" do
        expect(picture.widths).to eq([110, 160, 220, 320])
      end
    end

    context "with a tall ratio" do
      let(:options) { { ratio: "9:16", breakpoints: 100..320, step: 1.4 } }

      it "is bounded by the crop, not the image" do
        expect(picture.widths).to eq([113])
      end
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.gif", "image/gif")) }

      it "steps down like any other image" do
        expect(picture.widths).to eq([110, 160, 220, 320])
      end
    end
  end

  describe "#variants" do
    it "renders each candidate at the size it advertises" do
      expect(picture.variants.pluck(:width)).to eq([110, 160, 220, 320])
    end

    it "keeps the image's aspect ratio" do
      expect(picture.variants.pluck(:height)).to eq([68, 100, 137, 200])
    end

    it "points at the negotiated format" do
      expect(picture.variants.pluck(:url)).to all(end_with(".webp"))
    end

    context "with a ratio" do
      let(:options) { { ratio: "1:1", breakpoints: 100..320, step: 1.4 } }

      it "crops to the ratio" do
        expect(picture.variants.last).to include(width: 200, height: 200)
      end
    end
  end

  describe "#srcset" do
    it "pairs each URL with the width it is actually rendered at" do
      expect(picture.srcset.split(", ").map { |c| c.split.last })
        .to eq(%w[110w 160w 220w 320w])
    end

    it "never advertises a width the URL doesn't deliver" do
      picture.srcset.split(", ").each do |candidate|
        url, descriptor = candidate.split
        expect(url).to include("/#{descriptor.chomp('w')}x")
      end
    end

    it "signs every candidate, so the controller will serve it" do
      expect(picture.variants.pluck(:url)).to all(be_signed_for(image))
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.gif", "image/gif")) }

      it "offers candidates in the stored format" do
        expect(picture.srcset.split(", ")).to all(include(".gif "))
      end
    end
  end

  describe "#sources" do
    it "offers WebP" do
      expect(picture.sources.pluck(:type)).to eq(["image/webp"])
    end

    it "carries the srcset" do
      expect(picture.sources.first[:srcset]).to eq(picture.srcset)
    end

    context "with an explicit format" do
      let(:options) { { format: :avif, breakpoints: 100..320 } }

      it "forces it" do
        expect(picture.sources.pluck(:type)).to eq(["image/avif"])
      end
    end

    context "with a list of formats" do
      let(:options) do
        { format: DynamicImage::COMPATIBLE_FORMATS, breakpoints: 100..320 }
      end

      it "negotiates, and reports what it resolved to" do
        expect(picture.type).to eq("image/png")
      end

      it "needs no source once the candidates match the fallback" do
        expect(picture.sources).to eq([])
      end
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.gif", "image/gif")) }

      it "has none, since it keeps its own format" do
        expect(picture.sources).to eq([])
      end

      it "puts the candidates on the img instead" do
        expect(picture.srcset).not_to be_nil
      end
    end
  end

  describe "the fallback" do
    it "asks for the configured width" do
      expect(picture.fallback_size)
        .to eq("#{DynamicImage.picture_fallback_width}x")
    end

    it "is scaled down to the image, without clamping of its own" do
      expect([picture.width, picture.height]).to eq([320, 200])
    end

    it "is rendered in a format everything understands" do
      expect(picture.src).to end_with(".png")
    end

    it "is signed too" do
      expect(picture.src).to be_signed_for(image)
    end

    it "is not one of the candidates" do
      expect(picture.src).not_to be_in(picture.variants.pluck(:url))
    end

    context "with a ratio" do
      let(:options) { { ratio: "16:9", fallback_width: 160 } }

      it "carries the ratio, so the layout reserves the right box" do
        expect([picture.width, picture.height]).to eq([160, 90])
      end
    end

    context "with a transparent image" do
      let(:image) do
        Image.create(file: fixture("transparent.webp", "image/webp"))
      end

      it "negotiates to PNG rather than flattening onto white" do
        expect(picture.src).to end_with(".png")
      end
    end

    context "with an animated image" do
      let(:image) { Image.create(file: fixture("animated.gif", "image/gif")) }

      it "keeps the stored format" do
        expect(picture.src).to end_with(".gif")
      end
    end

    context "with an overridden width" do
      let(:options) { { fallback_width: 100 } }

      it { expect(picture.width).to eq(100) }
    end
  end

  describe "url options" do
    let(:options) { { breakpoints: 320, routing_type: :url } }

    it "passes them to the router" do
      expect(picture.src).to start_with("http://test.host/")
    end

    it "passes them to the candidates too" do
      expect(picture.srcset).to start_with("http://test.host/")
    end
  end

  describe "#available_width" do
    it "is the image's own width" do
      expect(picture.available_width).to eq(320)
    end

    context "with a ratio taller than the image" do
      let(:options) { { ratio: "1:2" } }

      it "is the width of the largest matching crop" do
        expect(picture.available_width).to eq(100)
      end
    end
  end
end
