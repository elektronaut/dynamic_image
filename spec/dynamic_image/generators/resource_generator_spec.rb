# frozen_string_literal: true

require "spec_helper"
require "rails/generators"

# Generator defaults, the ORM among them, are baked into class options
# when the generator class is defined. Rails does this while booting the
# generate command; here it has to happen before the require.
Rails::Generators.configure!(Rails.application.config.generators)

require "rails/generators/dynamic_image/resource/resource_generator"

describe DynamicImage::Generators::ResourceGenerator do
  let(:destination) { Rails.root.join("tmp/generator") }
  let(:migrations) { Dir[destination.join("db/migrate/*_create_pictures.rb")] }
  let(:migration) { File.read(migrations.first) }

  def prepare_destination
    FileUtils.rm_rf(destination)
    %w[app/models app/controllers config db/migrate].each do |dir|
      FileUtils.mkdir_p(destination.join(dir))
    end
    destination.join("config/routes.rb")
               .write("Rails.application.routes.draw do\nend\n")
    destination.join("app/controllers/application_controller.rb")
               .write("class ApplicationController < ActionController::Base\n" \
                      "end\n")
  end

  def run_generator(args)
    prepare_destination
    original = $stdout
    $stdout = StringIO.new
    Rails::Generators.invoke("dynamic_image:resource", args,
                             destination_root: destination,
                             behavior: :invoke)
  ensure
    $stdout = original
  end

  after { FileUtils.rm_rf(destination) }

  context "when generating a resource" do
    before { run_generator(%w[picture]) }

    it "creates exactly one migration" do
      expect(migrations.length).to eq(1)
    end

    it "requires the columns metadata is read into", :aggregate_failures do
      expect(migration).to include("t.string :content_hash, null: false")
      expect(migration).to include("t.string :colorspace, null: false")
      expect(migration).to include("t.integer :real_width, null: false")
    end

    it "leaves the crop columns nullable" do
      expect(migration).to include("t.integer :crop_width\n")
    end

    it "indexes content_hash" do
      expect(migration).to include("add_index :pictures, :content_hash\n")
    end

    it "includes the model extension" do
      expect(destination.join("app/models/picture.rb").read)
        .to include("include DynamicImage::Model")
    end

    it "includes the controller extension" do
      expect(destination.join("app/controllers/pictures_controller.rb").read)
        .to include("include DynamicImage::Controller")
    end

    it "points the controller at the model" do
      expect(destination.join("app/controllers/pictures_controller.rb").read)
        .to include("def model\n    Picture\n  end")
    end

    it "routes with image_resources" do
      expect(destination.join("config/routes.rb").read)
        .to include("image_resources :pictures")
    end
  end

  context "when given additional attributes" do
    before { run_generator(%w[picture caption:string]) }

    it "passes them through to the migration" do
      expect(migration).to include("t.string :caption")
    end

    it "still carries the DynamicImage columns" do
      expect(migration).to include("t.string :content_hash, null: false")
    end
  end
end
