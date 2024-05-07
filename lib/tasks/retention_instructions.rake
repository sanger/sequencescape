# frozen_string_literal: true

# $ bundle exec rake retention_instructions:backfill

require_relative '../../app/helpers/retention_instruction_helper'

namespace :retention_instructions do

  include RetentionInstructionHelper
  desc 'Backfill retention instructions'

  task backfill: :environment do
    puts 'Backfilling retention instructions...'

    ActiveRecord::Base.transaction do
      Labware.where(retention_instruction: nil).find_in_batches(batch_size: 1000) do |labware_group|
        labware_group.each do |labware|
          next unless labware.custom_metadatum_collection.present? &&
            labware.custom_metadatum_collection.metadata['retention_instruction'].present?
          labware.retention_instruction = find_retention_instruction_key_for_value(
            labware.custom_metadatum_collection.metadata['retention_instruction']
          )
          labware.custom_metadatum_collection.metadata.delete('retention_instruction')
          labware.custom_metadatum_collection.save!
          labware.save!
        end
      end
    end
  end

end