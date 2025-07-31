# frozen_string_literal: true

# $ bundle exec rake "retention_instructions:backfill[batch_size, limit]"
require_relative '../../app/helpers/retention_instruction_helper'

namespace :retention_instructions do
  include RetentionInstructionHelper

  desc 'Backfill retention instructions'

  task :backfill, %i[batch_size limit] => :environment do |_, args|
    args.with_defaults(batch_size: 1000, limit: nil)
    batch_size = args[:batch_size].to_i
    limit = args[:limit]&.to_i

    puts "Backfilling retention instructions with batch size: #{batch_size}..."

    ActiveRecord::Base.transaction do
      saved_count = 0
      labwares =
        Labware.joins(custom_metadatum_collection: :custom_metadata).where(
          retention_instruction: nil,
          custom_metadata: {
            key: 'retention_instruction'
          }
        )
      labwares = labwares.limit(limit) unless limit.nil?
      labwares.find_each(batch_size:) do |labware|
        puts "Processing labware #{labware.id}: #{labware.name}..."
        saved_count = process_labware(labware, saved_count)
      end
      puts "Backfilled retention instructions for #{saved_count} labware items."
    end
  end

  # rubocop:todo Metrics/MethodLength
  def process_labware(labware, saved_count)
    retention_instruction =
      find_retention_instruction_key_for_value(labware.custom_metadatum_collection.metadata['retention_instruction'])

    # Had to add this because there are some labwares with retention instructions like 'not provided'!
    return saved_count if retention_instruction.nil?

    labware.retention_instruction = retention_instruction.to_sym

    begin
      labware.custom_metadatum_collection.custom_metadata.where(key: 'retention_instruction').find_each(&:destroy!)
      # increment saved_count if save is successful
      labware.save!
      saved_count += 1
    rescue ActiveRecord::ActiveRecordError, StandardError => e
      puts "Error processing labware #{labware.id}: #{e.message}"
      raise e
    end
    saved_count
  end
  # rubocop:enable Metrics/MethodLength
end
