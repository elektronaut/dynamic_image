# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Schema do
  describe "::ATTRIBUTES" do
    subject(:attributes) { described_class::ATTRIBUTES }

    it { is_expected.to be_frozen }

    it "marks the metadata columns as non-null" do
      expect(attributes[:colorspace]).to eq(type: :string, null: false)
    end

    it "marks the crop columns as nullable" do
      expect(attributes[:crop_width]).to eq(type: :integer, null: true)
    end

    it "describes every column with a type and a nullability" do
      expect(attributes.values)
        .to all(match(type: Symbol, null: be(true).or(be(false))))
    end
  end

  describe "::INDEXES" do
    subject(:indexes) { described_class::INDEXES }

    it { is_expected.to be_frozen }

    it "indexes content_hash without requiring it to be unique" do
      expect(indexes).to include(columns: %i[content_hash], unique: false)
    end
  end

  describe ".generator_arguments" do
    subject(:arguments) { described_class.generator_arguments }

    it { is_expected.to include("content_hash:string") }
    it { is_expected.to include("real_width:integer") }

    it "covers every expected attribute" do
      expect(arguments.length).to eq(described_class::ATTRIBUTES.length)
    end
  end
end
