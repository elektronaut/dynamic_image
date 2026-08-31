# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Backfill
  #
  # Fills in the metadata columns for records stored before those
  # columns existed. Values are read back from the stored file, which is
  # the only place they can come from.
  #
  # Records are written with +update_columns+, so no callbacks run and
  # +updated_at+ is left alone. {DynamicImage::Model#to_param}
  # fingerprints on +updated_at+, so touching it would invalidate every
  # image URL and every cached variant.
  #
  #   DynamicImage::Backfill.new(Image).run
  #
  # @see DynamicImage::Schema
  class Backfill
    # The columns this fills in.
    COLUMNS = %i[frame_count alpha].freeze

    # @return [Class] the model being backfilled
    attr_reader :model

    # @return [Integer] records written
    attr_reader :updated

    # @return [Integer] records left alone, unreadable or missing
    attr_reader :skipped

    # @param model [Class] a model including {DynamicImage::Model}
    def initialize(model)
      @model = model
      @updated = 0
      @skipped = 0
    end

    # The records with a column still unset.
    #
    # @return [ActiveRecord::Relation] the pending records
    def pending
      COLUMNS.map { |column| model.where(column => nil) }.reduce(:or)
    end

    # Reads metadata for every pending record and fills the columns in.
    #
    # @yieldparam record [DynamicImage::Model] each record, after it has
    #   been processed
    # @return [self]
    # @raise [ArgumentError] if the table doesn't have the columns yet
    def run
      ensure_columns
      pending.find_each do |record|
        process(record)
        yield(record) if block_given?
      end
      self
    end

    private

    def ensure_columns
      missing = COLUMNS.reject { |c| model.column_names.include?(c.to_s) }
      return if missing.empty?

      raise ArgumentError,
            "#{model.table_name} has no #{missing.join(', ')} column. " \
            "Run bin/rails generate dynamic_image:upgrade #{model.name}"
    end

    def process(record)
      record.with_data_file { |path| apply(record, path) }
    rescue Dis::Errors::NotFoundError
      @skipped += 1
    end

    # Metadata reads lazily, so the values have to be resolved before
    # the file goes out of scope. Written with update_columns so that
    # no callbacks run.
    def apply(record, path)
      metadata = DynamicImage::Metadata.new(path)
      return @skipped += 1 unless metadata.valid?

      record.update_columns(frame_count: metadata.frame_count,
                            alpha: metadata.alpha?)
      @updated += 1
    end
  end
end
