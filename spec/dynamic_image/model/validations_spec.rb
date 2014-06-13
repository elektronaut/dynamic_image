require 'spec_helper'

describe DynamicImage::Model::Validations do

  let(:image) { Image.new }

  def errors_on(attribute, value)
    image.send("#{attribute}=", value)
    image.valid?
    image.errors[attribute]
  end

  shared_examples "a required attribute" do |attribute|
    it "should not accept nil" do
      expect(errors_on(attribute, nil)).to include("can't be blank")
    end

    it "should not accept an empty string" do
      expect(errors_on(attribute, "")).to include("can't be blank")
    end
  end

  shared_examples "a size validation" do |attribute|
    it_should_behave_like "a required attribute", attribute

    it "should not accept a malformed string" do
      expect(errors_on(attribute, "100x")).to include("is invalid")
      expect(errors_on(attribute, "x100")).to include("is invalid")
      expect(errors_on(attribute, "100.0x100.0")).to include("is invalid")
    end

    it "should accept a vector string" do
      expect(errors_on(attribute, "100x100").any?).to be false
    end
  end

  describe "data validation" do
    it_should_behave_like "a required attribute", :data
  end

  describe "content_type validation" do
    it_should_behave_like "a required attribute", :content_type

    it "should not accept an invalid content type" do
      expect(errors_on(:content_type, "image/foo")).to include("is invalid")
    end

    it "should accept a valid content type" do
      expect(errors_on(:content_type, "image/jpeg").any?).to be false
    end
  end

  describe "content_length validation" do
    it_should_behave_like "a required attribute", :content_length

    it "should be more than 0" do
      expect(errors_on(:content_length, 0)).to include("must be greater than 0")
    end

    it "should accept a number" do
      expect(errors_on(:content_length, 2048).any?).to be false
    end
  end

  describe "filename validation" do
    it_should_behave_like "a required attribute", :filename

    it "should not accept too long names" do
      expect(errors_on(:filename, ("a" * 252) + ".jpg")).to include("is too long (maximum is 255 characters)")
    end
  end

  describe "crop_size validation" do
    it_should_behave_like "a size validation", :crop_size
  end

  describe "crop_start validation" do
    it_should_behave_like "a size validation", :crop_start
  end

  describe "real_size validation" do
    it_should_behave_like "a size validation", :real_size
  end
end