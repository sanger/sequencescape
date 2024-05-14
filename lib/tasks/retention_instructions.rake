# frozen_string_literal: true

# $ bundle exec rake retention_instructions:backfill

require_relative '../../app/helpers/retention_instruction_helper'

namespace :retention_instructions do

  include RetentionInstructionHelper
  desc 'Backfill retention instructions'

  task :backfill, [:batch_size] => :environment do |_, args|
    args.with_defaults(batch_size: 1000)
    batch_size = args[:batch_size].to_i

    puts "Backfilling retention instructions with batch size: #{batch_size}..."

    saved_count = 0

    ActiveRecord::Base.transaction do
      Labware.where(retention_instruction: nil).find_each(batch_size: batch_size) do |labware|
        saved_count = process_labware(labware, saved_count)
      end
    end

    puts "Backfilled retention instructions for #{saved_count} labware items."
  end

  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/MethodLength
  def process_labware(labware, saved_count)
    return saved_count unless labware.custom_metadatum_collection.present? &&
      labware.custom_metadatum_collection.metadata['retention_instruction'].present?

    labware.retention_instruction = find_retention_instruction_key_for_value(
      labware.custom_metadatum_collection.metadata['retention_instruction']
    ).to_sym

    labware.custom_metadatum_collection.custom_metadata.each do |custom_metadata_record|
      custom_metadata_record.key == 'retention_instruction' && custom_metadata_record.destroy!
    end

    labware.save! ? saved_count + 1 : saved_count
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

end