# frozen_string_literal: true

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates transfer templates if they are not present
  class TransferTemplateLoader < ApplicationRecordLoader
    config_folder 'transfer_templates'

    def create_or_update!(name, options)
      # We do not use the following because it creates a new record only.
      # TransferTemplate.create_with(options).find_or_create_by!(name: name)

      # We use the following because it creates a new record or updates existing.
      transfer_template = TransferTemplate.find_or_initialize_by(name:)
      transfer_template.update!(options) # assign_attributes and save!
    end
  end
end
