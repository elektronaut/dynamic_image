# frozen_string_literal: true

require "spec_helper"

describe DynamicImage::DigestVerifier do
  let(:secret)   { "topsecret" }
  let(:verifier) { described_class.new(secret) }
  let(:data)     { "show-123-64x64" }
  let(:digest)   { "1639a467ae544a4a9b4a5623fe56a2f93276087a" }

  describe "#generate" do
    subject { verifier.generate(data) }

    it { is_expected.to eq(digest) }
  end

  describe "#verify" do
    subject(:verification) { verifier.verify(data, digest) }

    context "with valid data" do
      it { is_expected.to be true }
    end

    context "with invalid digest" do
      let(:digest) { "1639a467ae544a4a9b4a5623fe56a2f93276087b" }

      it "raises an error" do
        expect { verification }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end

    context "with no data" do
      let(:data) { "" }

      it "raises an error" do
        expect { verification }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end

    context "with no digest" do
      let(:digest) { nil }

      it "raises an error" do
        expect { verification }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end
  end
end
