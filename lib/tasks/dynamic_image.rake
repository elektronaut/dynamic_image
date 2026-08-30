# frozen_string_literal: true

namespace :dynamic_image do
  desc "Fill in metadata columns for images stored before they existed"
  task backfill: :environment do
    unless ENV["MODELS"]
      puts "Usage: #{$PROGRAM_NAME} dynamic_image:backfill MODELS=Image"
      exit
    end

    ENV["MODELS"].split(",").map(&:strip).map(&:constantize).each do |model|
      backfill = DynamicImage::Backfill.new(model)
      total = backfill.pending.count
      puts "#{model.name}: #{total} #{'record'.pluralize(total)} to read"

      processed = 0
      backfill.run do
        processed += 1
        print("\r  #{processed}/#{total}") if (processed % 10).zero?
      end

      puts "\r  #{backfill.updated} updated, #{backfill.skipped} skipped"
    end
  end
end
