# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Backfill
  #
  # Fills in the metadata columns for records stored before those columns existed. The values are read back from
  # the stored file, except where the format guarantees them.
  #
  # Records are written with +update_columns+, so no callbacks run and +updated_at+ is left alone.
  # {DynamicImage::Model#to_param} fingerprints on +updated_at+, and touching it would invalidate every image URL
  # and every cached variant.
  #
  #   DynamicImage::Backfill.new(Image).run
  #
  # @see DynamicImage::Schema
  class Backfill
    # The columns this fills in.
    COLUMNS = %i[frame_count alpha].freeze

    # @return [Integer] records written
    attr_reader :updated

    # @return [Integer] records left alone, unreadable or missing
    attr_reader :skipped

    # @return [Integer] records filled in from the format, without a read
    attr_reader :inferred

    # @param model [Class] a model including {DynamicImage::Model}
    # @param concurrency [Integer] how many files to read at a time. Reads are network bound; the metadata itself
    #   comes off the header. Set to 1 to read serially.
    def initialize(model, concurrency: 4)
      @model = model
      @updated = 0
      @skipped = 0
      @inferred = 0
      @concurrency = [concurrency.to_i, 1].max
    end

    # The records with a column still unset.
    #
    # @return [ActiveRecord::Relation] the pending records
    def pending
      COLUMNS.map { |column| model.where(column => nil) }.reduce(:or)
    end

    # Fills in what the format settles, then reads the rest.
    #
    # @yieldparam record [DynamicImage::Model] each record, after it has been read
    # @return [self]
    # @raise [ArgumentError] if the table doesn't have the columns yet
    def run
      ensure_columns
      infer_from_format
      pending.find_in_batches(batch_size: concurrency) do |batch|
        read(batch).each do |record, values|
          write(record, values)
          yield(record) if block_given?
        end
      end
      self
    end

    private

    attr_reader :model, :concurrency

    # The formats whose values follow from the format itself. A format that holds neither animation nor an alpha
    # channel has one frame and no transparency, whatever the file contains.
    def inferable_formats
      DynamicImage::Format.formats.reject { |f| f.animated? || f.alpha? }
    end

    # Written with update_all, so no files are read, no callbacks run and updated_at is left alone.
    def infer_from_format
      inferable_formats.each do |format|
        @inferred += pending.where(content_type: format.content_types)
                            .update_all(frame_count: 1, alpha: false)
      end
      @inferred
    end

    def ensure_columns
      missing = COLUMNS.reject { |c| model.column_names.include?(c.to_s) }
      return if missing.empty?

      raise ArgumentError,
            "#{model.table_name} has no #{missing.join(', ')} column. " \
            "Run bin/rails generate dynamic_image:upgrade #{model.name}"
    end

    # Reads run in threads and touch no database connection. The writes happen on the calling thread, so the
    # counters stay consistent.
    def read(records)
      return records.map { |record| [record, values_for(record)] } if concurrency == 1

      records.map { |record| Thread.new { [record, values_for(record)] } }
             .map(&:value)
    end

    # Metadata reads lazily, so the values have to be resolved before the file goes out of scope.
    def values_for(record)
      record.with_data_file do |path|
        metadata = DynamicImage::Metadata.new(path)
        [metadata.frame_count, metadata.alpha?] if metadata.valid?
      end
    rescue Dis::Errors::NotFoundError
      nil
    end

    # Written with update_columns so that no callbacks run.
    def write(record, values)
      return @skipped += 1 if values.nil?

      record.update_columns(frame_count: values.first, alpha: values.last)
      @updated += 1
    end
  end
end
