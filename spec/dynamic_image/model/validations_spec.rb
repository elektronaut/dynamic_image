require 'spec_helper'

describe DynamicImage::Model::Validations do

  describe "content_type validation" do
    before { image.valid? }

    context "when nil" do
      let(:image) { Image.new }

      it "should validate presence" do
        expect(image.errors[:content_type]).to include("can't be blank")
      end
    end

    context "when blank" do
      let(:image) { Image.new(content_type: "") }

      it "should validate presence" do
        expect(image.errors[:content_type]).to include("can't be blank")
      end
    end

    context "not a valid type" do
      let(:image) { Image.new(content_type: "image/foo") }

      it "should validate presence" do
        expect(image.errors[:content_type]).to include("is invalid")
      end
    end

    context "when correct" do
      let(:image) { Image.new(content_type: "image/jpeg") }

      it "should validate presence" do
        expect(image.errors[:content_type].any?).to be false
      end
    end
  end
end