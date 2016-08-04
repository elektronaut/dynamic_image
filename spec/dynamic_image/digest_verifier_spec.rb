require "spec_helper"

describe DynamicImage::DigestVerifier do
  let(:secret)   { "topsecret" }
  let(:verifier) { DynamicImage::DigestVerifier.new(secret) }
  let(:data)     { "show-123-64x64" }
  let(:digest)   { "1639a467ae544a4a9b4a5623fe56a2f93276087a" }

  describe "#generate" do
    subject { verifier.generate(data) }
    it { is_expected.to eq(digest) }
  end

  describe "#verify" do
    subject { verifier.verify(data, digest) }
    context "with valid data" do
      it { is_expected.to be true }
    end

    context "with invalid digest" do
      let(:digest) { "1639a467ae544a4a9b4a5623fe56a2f93276087b" }
      it "should raise an error" do
        expect { subject }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end

    context "with no data" do
      let(:data) { "" }
      it "should raise an error" do
        expect { subject }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end

    context "with no digest" do
      let(:digest) { nil }
      it "should raise an error" do
        expect { subject }.to(
          raise_error(DynamicImage::Errors::InvalidSignature)
        )
      end
    end
  end
end
