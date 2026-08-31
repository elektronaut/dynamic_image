# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::Backfill do
  subject(:backfill) { described_class.new(Image) }

  let(:file) do
    File.open(File.expand_path("../support/fixtures/image.png", __dir__))
  end
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, "image/png") }
  let(:image) { Image.create!(file: uploaded_file) }

  def unrecorded(record)
    record.update_columns(frame_count: nil, alpha: nil)
    record.reload
  end

  describe "#pending" do
    it "finds records with a column unset" do
      unrecorded(image)
      expect(backfill.pending).to include(image)
    end

    it "leaves recorded records alone" do
      image
      expect(backfill.pending).not_to include(image)
    end
  end

  describe "#run" do
    before { unrecorded(image) }

    it "records the frame count" do
      backfill.run
      expect(image.reload.frame_count).to eq(1)
    end

    it "records the alpha channel" do
      backfill.run
      expect(image.reload.alpha).to be(false)
    end

    it "counts what it wrote" do
      expect(backfill.run.updated).to eq(1)
    end

    it "leaves updated_at alone" do
      expect { backfill.run }.not_to(change { image.reload.updated_at })
    end

    it "yields each record" do
      expect { |b| backfill.run(&b) }.to yield_with_args(image)
    end

    context "when the stored file is gone" do
      before { Dis::Storage.delete(Image.dis_type, image.content_hash) }

      it "skips the record" do
        expect(backfill.run.skipped).to eq(1)
      end

      it "leaves the columns unset" do
        backfill.run
        expect(image.reload.frame_count).to be_nil
      end
    end

    context "when the table has no such columns" do
      subject(:backfill) { described_class.new(LegacyImage) }

      it "says which generator to run" do
        expect { backfill.run }
          .to raise_error(ArgumentError, /dynamic_image:upgrade LegacyImage/)
      end
    end
  end
end
