# frozen_string_literal: true

# $ bundle exec rake retention_instructions:backfill

require_relative '../../app/helpers/retention_instruction_helper'

namespace :retention_instructions do

  include RetentionInstructionHelper
  desc 'Backfill retention instructions'

  task backfill: :environment do
    puts 'Backfilling retention instructions...'

    ActiveRecord::Base.transaction do
      Labware.where(retention_instruction: nil).find_each do |labware|
        next unless labware.custom_metadatum_collection.present? &&
          labware.custom_metadatum_collection.metadata['retention_instruction'].present?
        labware.retention_instruction = find_retention_instruction_key_for_value(
          labware.custom_metadatum_collection.metadata['retention_instruction']
        )
        labware.custom_metadatum_collection.custom_metadata.each do |custom_metadata_record|
          custom_metadata_record.key == 'retention_instruction' && custom_metadata_record.destroy!
        end
        labware.save!
      end
    end
  end

end