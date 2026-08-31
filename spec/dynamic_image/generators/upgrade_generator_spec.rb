# frozen_string_literal: true

require "spec_helper"
require "rails/generators"

# Generator defaults are baked into class options when the generator
# class is defined. Rails does this while booting the generate command;
# here it has to happen before the require.
Rails::Generators.configure!(Rails.application.config.generators)

require "rails/generators/dynamic_image/upgrade/upgrade_generator"

describe DynamicImage::Generators::UpgradeGenerator do
  let(:destination) { Rails.root.join("tmp/upgrade") }
  let(:connection) { ActiveRecord::Base.connection }
  let(:table) { :upgradable_images }
  let(:migrations) { Dir[destination.join("db/migrate/*.rb")] }
  let(:migration) { File.read(migrations.first) }

  def build_table(without: [], nullable: [], indexes: [])
    connection.create_table(table, force: true) do |t|
      DynamicImage::Schema::ATTRIBUTES.each do |name, column|
        next if without.include?(name)

        t.send(column[:type], name,
               null: nullable.include?(name) || column[:null])
      end
    end
    indexes.each { |columns| connection.add_index(table, columns) }
  end

  def run_generator
    FileUtils.rm_rf(destination)
    FileUtils.mkdir_p(destination.join("db/migrate"))
    original = $stdout
    $stdout = StringIO.new
    Rails::Generators.invoke("dynamic_image:upgrade", ["UpgradableImage"],
                             destination_root: destination,
                             behavior: :invoke)
    $stdout.string
  ensure
    $stdout = original
  end

  before do
    stub_const("UpgradableImage", Class.new(ApplicationRecord) do
      def self.name = "UpgradableImage"
    end)
    UpgradableImage.table_name = "upgradable_images"
  end

  after do
    connection.drop_table(table, if_exists: true)
    FileUtils.rm_rf(destination)
  end

  context "when the table is missing columns and the index" do
    before do
      build_table(without: %i[frame_count alpha])
      run_generator
    end

    it "writes one migration" do
      expect(migrations.length).to eq(1)
    end

    it "names it for what it adds" do
      expect(migrations.first)
        .to include("add_frame_count_and_alpha_to_upgradable_images")
    end

    it "adds the missing columns", :aggregate_failures do
      expect(migration)
        .to include("add_column :upgradable_images, :frame_count, :integer")
      expect(migration)
        .to include("add_column :upgradable_images, :alpha, :boolean")
    end

    it "adds the missing index" do
      expect(migration)
        .to include("add_index :upgradable_images, :content_hash")
    end

    it "adds columns nullable, even where the schema wants NOT NULL" do
      expect(migration).not_to include("null: false")
    end
  end

  context "when only the index is missing" do
    before do
      build_table
      run_generator
    end

    it "names the migration for the index" do
      expect(migrations.first)
        .to include("add_dynamic_image_indexes_to_upgradable_images")
    end

    it "adds no columns" do
      expect(migration).not_to include("add_column")
    end
  end

  context "when the table is already up to date" do
    before { build_table(indexes: [:content_hash]) }

    it "writes no migration" do
      run_generator
      expect(migrations).to be_empty
    end

    it "says so" do
      expect(run_generator).to include("is up to date")
    end
  end

  context "when an existing index already leads with content_hash" do
    before { build_table(indexes: [%i[content_hash content_type]]) }

    it "writes no migration" do
      run_generator
      expect(migrations).to be_empty
    end
  end

  context "when a column that should be NOT NULL is nullable" do
    before { build_table(nullable: %i[colorspace], indexes: [:content_hash]) }

    it "reports it" do
      expect(run_generator)
        .to include("upgradable_images.colorspace should be NOT NULL")
    end
  end
end
