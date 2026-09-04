# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Breakpoints do
  subject(:breakpoints) { described_class.new(spec, **options) }

  let(:spec) { nil }
  let(:options) { {} }

  describe "defaults" do
    it "reads the breakpoints from the configuration" do
      expect(breakpoints.spec).to eq(DynamicImage.default_breakpoints)
    end

    it "reads the step from the configuration" do
      expect(breakpoints.step).to eq(DynamicImage.breakpoint_step)
    end

    it "treats an explicit nil as absent" do
      expect(described_class.new(nil, step: nil).step)
        .to eq(DynamicImage.breakpoint_step)
    end
  end

  describe "#widths with a range" do
    let(:spec) { 320..3200 }
    let(:options) { { step: 1.4 } }

    it "steps down from the available width" do
      expect(breakpoints.widths(3200))
        .to eq([420, 590, 830, 1160, 1630, 2280, 3200])
    end

    it "always offers the full width, even outside the range" do
      expect(breakpoints.widths(1100)).to eq([400, 560, 780, 1100])
    end

    it "stops stepping below the beginning of the range" do
      expect(breakpoints.widths(3200).first).to be >= 320
    end

    it "caps at the end of the range" do
      expect(breakpoints.widths(6000).last).to eq(3200)
    end

    it "returns a single candidate for an image below the range" do
      expect(breakpoints.widths(200)).to eq([200])
    end

    it "never snaps the single candidate below the range" do
      expect(breakpoints.widths(199)).to eq([199])
    end

    it "serves the image at its own width, not snapped down" do
      expect(breakpoints.widths(16)).to eq([16])
    end

    it "snaps the interpolated steps down to a multiple of ten" do
      expect(breakpoints.widths(1103)).to eq([400, 560, 780, 1103])
    end

    it "never snaps the available width itself" do
      expect(breakpoints.widths(1103).last).to eq(1103)
    end

    it "never advertises more than the image has" do
      expect(breakpoints.widths(1103).last).to be <= 1103
    end

    it "returns nothing when there is no image to speak of" do
      expect(breakpoints.widths(0)).to eq([])
    end

    it "generates fewer candidates as the step grows" do
      expect(described_class.new(320..3200, step: 2).widths(3200))
        .to eq([400, 800, 1600, 3200])
    end

    it "generates more candidates as the step shrinks" do
      expect(described_class.new(320..3200, step: 1.25)
                            .widths(3200).length).to eq(11)
    end

    it "handles a range without an end" do
      expect(described_class.new(320.., step: 2).widths(1000))
        .to eq([500, 1000])
    end

    it "never repeats a width" do
      widths = described_class.new(10..100, step: 1.01).widths(100)
      expect(widths).to eq(widths.uniq)
    end
  end

  describe "#widths with an array" do
    let(:spec) { [1200, 400, 800] }

    it "sorts the widths" do
      expect(breakpoints.widths(2000)).to eq([400, 800, 1200])
    end

    it "drops widths the image can't fill" do
      expect(breakpoints.widths(1000)).to eq([400, 800])
    end

    it "falls back to the available width when none fit" do
      expect(breakpoints.widths(300)).to eq([300])
    end

    it "ignores the step" do
      expect(described_class.new([400, 800], step: 3).widths(2000))
        .to eq([400, 800])
    end
  end

  describe "#widths with an integer" do
    let(:spec) { 800 }

    it "offers the one width" do
      expect(breakpoints.widths(2000)).to eq([800])
    end

    it "offers it even when the image is smaller, since fitting " \
       "clamps it and one candidate can't collide" do
      expect(breakpoints.widths(400)).to eq([800])
    end
  end

  describe "validation" do
    it "rejects a step of one, which would never terminate" do
      expect { described_class.new(step: 1) }
        .to raise_error(ArgumentError, /step must be greater than 1/)
    end

    it "rejects a step below one, which would grow without bound" do
      expect { described_class.new(step: 0.5) }
        .to raise_error(ArgumentError, /step must be greater than 1/)
    end

    it "rejects a beginless range, which would step down forever" do
      expect { described_class.new(..3200) }
        .to raise_error(ArgumentError, /must have a beginning/)
    end

    it "rejects a spec it doesn't understand" do
      expect { described_class.new("400w, 800w").widths(1000) }
        .to raise_error(ArgumentError, /must be a Range, Array or Integer/)
    end
  end
end
