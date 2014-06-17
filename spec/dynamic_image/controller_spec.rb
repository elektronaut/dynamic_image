require 'spec_helper'

describe ImagesController, type: :controller do
  storage_root = Rails.root.join('tmp', 'spec')

  let(:file) { File.open(File.expand_path("../../support/fixtures/image.png", __FILE__)) }
  let(:content_type) { "image/png" }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.create(file: uploaded_file) }

  before(:all) do
    Shrouded::Storage.layers << Shrouded::Layer.new(Fog::Storage.new({provider: 'Local', local_root: storage_root}))
  end

  after do
    FileUtils.rm_rf(storage_root) if File.exists?(storage_root)
  end

  after(:all) do
    Shrouded::Storage.layers.clear!
  end

  describe "GET show" do
    context "with a nonexistant record" do
      it "should raise an error" do
        expect { get :show, id: 1 }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an existing record" do
      before { get :show, id: image.id }
      it "should find the record" do
        expect(assigns(:record)).to eq(image)
      end
    end
  end
end