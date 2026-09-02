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

  describe "#inferable_formats" do
    it "includes a format with neither animation nor alpha" do
      expect(backfill.inferable_formats.map(&:name)).to include("JPEG")
    end

    it "excludes a format that holds an alpha channel" do
      expect(backfill.inferable_formats.map(&:name)).not_to include("PNG")
    end

    it "excludes a format that holds animation" do
      expect(backfill.inferable_formats.map(&:name)).not_to include("GIF")
    end
  end

  describe "#infer_from_format" do
    let(:jpeg_file) do
      File.open(File.expand_path("../support/fixtures/image.jpg", __dir__))
    end
    let(:jpeg) do
      Image.create!(file: Rack::Test::UploadedFile.new(jpeg_file, "image/jpeg"))
    end

    before { unrecorded(jpeg) }

    it "fills the frame count in" do
      backfill.infer_from_format
      expect(jpeg.reload.frame_count).to eq(1)
    end

    it "fills the alpha channel in" do
      backfill.infer_from_format
      expect(jpeg.reload.alpha).to be(false)
    end

    it "counts what it wrote" do
      expect(backfill.infer_from_format).to eq(1)
    end

    it "reads no files" do
      allow(Dis::Storage).to receive(:get)
      backfill.infer_from_format
      expect(Dis::Storage).not_to have_received(:get)
    end

    it "leaves updated_at alone" do
      expect { backfill.infer_from_format }
        .not_to(change { jpeg.reload.updated_at })
    end

    it "leaves a format it cannot settle alone" do
      unrecorded(image)
      expect { backfill.infer_from_format }
        .not_to(change { image.reload.frame_count })
    end

    it "leaves an already recorded record alone" do
      jpeg.update_columns(frame_count: 3, alpha: true)
      backfill.infer_from_format
      expect(jpeg.reload.frame_count).to eq(3)
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
