# frozen_string_literal: true

require "spec_helper"

describe ImagesController, type: :routing do
  let(:image) do
    Image.create(
      file: Rack::Test::UploadedFile.new(
        File.open(File.expand_path("../support/fixtures/image.png", __dir__)),
        "image/png"
      )
    )
  end

  describe "show" do
    let(:route) do
      { controller: "images",
        action: "show",
        id: "1-20140606",
        digest: "123456",
        size: "100x100",
        format: "png" }
    end

    it "routes the URL" do
      expect(get("/images/123456/100x100/1-20140606.png")).to(
        route_to(route)
      )
    end

    it "routes the named route" do
      expect(
        get: image_path("123456", "100x100", id: "1-20140606", format: "png")
      ).to(
        route_to(route)
      )
    end

    it "does not route URLs with an invalid size" do
      expect(get("/images/123456/100x/1-20140606.png")).not_to be_routable
    end
  end

  describe "uncropped" do
    let(:route) do
      { controller: "images",
        action: "uncropped",
        id: "1-20140606",
        digest: "123456",
        size: "100x100",
        format: "png" }
    end

    let(:helper_path) do
      uncropped_image_path("123456", "100x100", id: "1-20140606", format: "png")
    end

    it "routes the URL" do
      expect(get("/images/123456/100x100/1-20140606/uncropped.png")).to(
        route_to(route)
      )
    end

    it "routes the named route" do
      expect(get: helper_path).to(route_to(route))
    end
  end

  describe "original" do
    let(:route) do
      { controller: "images",
        action: "original",
        id: "1-20140606",
        digest: "123456",
        format: "png" }
    end

    it "routes the URL" do
      expect(get("/images/123456/1-20140606/original.png")).to(
        route_to(route)
      )
    end

    it "routes the named route" do
      expect(
        get: original_image_path("123456", id: "1-20140606", format: "png")
      ).to(
        route_to(route)
      )
    end
  end

  describe "download" do
    let(:route) do
      { controller: "images",
        action: "download",
        id: "1-20140606",
        digest: "123456",
        format: "png" }
    end

    it "routes the URL" do
      expect(get("/images/123456/1-20140606/download.png")).to(
        route_to(route)
      )
    end

    it "routes the named route" do
      expect(
        get: download_image_path("123456", id: "1-20140606", format: "png")
      ).to(
        route_to(route)
      )
    end
  end
end
