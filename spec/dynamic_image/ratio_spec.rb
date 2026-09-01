# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Ratio do
  describe ".parse" do
    it "passes floats through" do
      expect(described_class.parse(1.5)).to eq(1.5)
    end

    it "converts integers" do
      expect(described_class.parse(2)).to eq(2.0)
    end

    it "converts rationals" do
      expect(described_class.parse(Rational(16, 9)))
        .to be_within(0.001).of(1.7778)
    end

    it "converts vectors" do
      expect(described_class.parse(Vector2d.new(16, 9)))
        .to be_within(0.001).of(1.7778)
    end

    it "parses colon separated strings" do
      expect(described_class.parse("16:9")).to be_within(0.001).of(1.7778)
    end

    it "parses x separated strings" do
      expect(described_class.parse("16x9")).to be_within(0.001).of(1.7778)
    end

    it "parses slash separated strings" do
      expect(described_class.parse("16/9")).to be_within(0.001).of(1.7778)
    end

    it "parses a bare decimal string" do
      expect(described_class.parse("1.5")).to eq(1.5)
    end

    it "returns nil for nil" do
      expect(described_class.parse(nil)).to be_nil
    end

    it "rejects zero, which has no usable inverse" do
      expect { described_class.parse(0) }
        .to raise_error(ArgumentError, /invalid ratio/)
    end

    it "rejects a zero height" do
      expect { described_class.parse("16:0") }
        .to raise_error(ArgumentError, /invalid ratio/)
    end

    it "rejects a negative ratio" do
      expect { described_class.parse(-1.5) }
        .to raise_error(ArgumentError, /invalid ratio/)
    end

    it "rejects nonsense" do
      expect { described_class.parse(:wide) }
        .to raise_error(ArgumentError, /invalid ratio/)
    end
  end
end
