# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Helper::Formats, type: :helper do
  subject(:url) { helper.dynamic_image_url(image, size: "100x100") }

  let(:image) do
    Image.create(
      file: Rack::Test::UploadedFile.new(
        File.open(
          File.expand_path("../../support/fixtures/image.webp", __dir__)
        ),
        "image/webp"
      ),
      filename: "my-uploaded-file.webp"
    )
  end

  it { is_expected.to end_with(".webp") }

  it "renders a mailer view in a format the mailer accepts" do
    expect(ImageMailer.image(image).body.to_s).to include(".jpeg")
  end

  it "keeps a format the mailer can't render out of a mailer view" do
    expect(ImageMailer.image(image).body.to_s).not_to include(".webp")
  end

  context "when the uploaded format isn't accepted" do
    before do
      allow(DynamicImage).to receive(:default_formats)
        .and_return(%i[jpeg png gif])
    end

    it { is_expected.to end_with(".jpeg") }
  end
end
